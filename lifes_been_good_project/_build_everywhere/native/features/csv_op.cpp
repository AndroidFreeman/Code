#include "common.hpp"
#include "json.hpp"
#include <fstream>
#include <sstream>
#include <algorithm>

using json = nlohmann::json;

int main(int argc, char **argv)
{
    init_console_utf8();
    auto args = get_args_utf8(argc, argv);
    if (args.size() < 3) {
        json_err("bad_request", "Usage: csv_op <data_dir> <json_payload>");
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
            std::fputs("{\"items\":[]}", stdout);
            json_ok_end();
            return 0;
        }
        json_print_csv_items(path);
        return 0;
    }
    else if (action == "write") {
        if (!payload.contains("headers") || !payload.contains("rows")) {
            json_err("bad_request", "Missing headers or rows");
            return 1;
        }
        std::ofstream out(path, std::ios::binary);
        if (!out.is_open()) {
            json_err("io_error", "Cannot open file for writing");
            return 1;
        }
        
        auto headers = payload["headers"];
        bool first = true;
        for (auto& h : headers) {
            if (!first) out << ",";
            out << h.get<std::string>();
            first = false;
        }
        out << "\n";
        
        auto rows = payload["rows"];
        for (auto& r : rows) {
            first = true;
            for (auto& h : headers) {
                if (!first) out << ",";
                std::string key = h.get<std::string>();
                std::string val;
                if (r.contains(key)) {
                    if (r[key].is_string()) {
                        val = r[key].get<std::string>();
                    } else if (r[key].is_number_integer()) {
                        val = std::to_string(r[key].get<long long>());
                    } else if (r[key].is_number_float()) {
                        val = std::to_string(r[key].get<double>());
                    } else if (r[key].is_boolean()) {
                        val = r[key].get<bool>() ? "true" : "false";
                    }
                }
                val.erase(std::remove(val.begin(), val.end(), ','), val.end());
                val.erase(std::remove(val.begin(), val.end(), '\r'), val.end());
                val.erase(std::remove(val.begin(), val.end(), '\n'), val.end());
                out << val;
                first = false;
            }
            out << "\n";
        }
        out.close();
        
        json_ok_start();
        std::fputs("{\"success\":true}", stdout);
        json_ok_end();
        return 0;
    }
    
    json_err("bad_action", "Unknown action");
    return 1;
}
