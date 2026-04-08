#include "common.hpp"
#include "json.hpp"
#include <fstream>
#include <sstream>

using json = nlohmann::json;

int main(int argc, char **argv)
{
    init_console_utf8();
    auto args = get_args_utf8(argc, argv);
    if (args.size() < 3) {
        json_err("bad_request", "Usage: json_op <data_dir> <json_payload>");
        return 2;
    }
    std::string data_dir = args[1];
    std::string payload_str = args[2];
    
    json payload;
    try {
        payload = json::parse(payload_str);
    } catch (...) {
        json_err("bad_json", "Invalid JSON payload");
        return 1;
    }
    
    std::string action = payload.value("action", "");
    std::string filename = payload.value("file", "");
    if (action.empty() || filename.empty()) {
        json_err("bad_request", "Missing action or file");
        return 1;
    }
    
    char path[1024];
    path_join(path, sizeof(path), data_dir.c_str(), filename.c_str());
    
    if (action == "read") {
        if (!file_exists(path)) {
            json_ok_start();
            std::fputs("null", stdout);
            json_ok_end();
            return 0;
        }
        std::ifstream in(path);
        if (!in.is_open()) {
            json_err("io_error", "Cannot read file");
            return 1;
        }
        std::stringstream buffer;
        buffer << in.rdbuf();
        
        json_ok_start();
        std::string content = buffer.str();
        if (content.empty()) content = "null";
        std::fputs(content.c_str(), stdout);
        json_ok_end();
        return 0;
    }
    else if (action == "write") {
        if (!payload.contains("data")) {
            json_err("bad_request", "Missing data");
            return 1;
        }
        std::ofstream out(path, std::ios::binary);
        if (!out.is_open()) {
            json_err("io_error", "Cannot write file");
            return 1;
        }
        out << payload["data"].dump();
        out.close();
        
        json_ok_start();
        std::fputs("{\"success\":true}", stdout);
        json_ok_end();
        return 0;
    }
    else if (action == "delete") {
        if (file_exists(path)) {
            std::remove(path);
        }
        json_ok_start();
        std::fputs("{\"success\":true}", stdout);
        json_ok_end();
        return 0;
    }
    
    json_err("bad_action", "Unknown action");
    return 1;
}
