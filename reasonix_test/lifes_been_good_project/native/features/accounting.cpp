/*
 * @Date: 2026-04-15 11:48:13
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-15 11:48:16
 * @FilePath: /Code/lifes_been_good_project/native/features/accounting.cpp
 */
#include <algorithm>
#include <fstream>
#include <mutex>
#include <sstream>

#include "common.hpp"
#include "json.hpp"

using json = nlohmann::json;

#if defined(_WIN32)
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

// 参考其他 native 文件（如 students_list.cpp），使用 CSV 进行存储
static std::string process_accounting(const std::string& data_dir,
                                      const std::string& action,
                                      const std::string& payload_json) {
    char path[1024];
    path_join(path, sizeof(path), data_dir.c_str(), "accounting.csv");

    // 确保 CSV 文件存在并带有表头
    ensure_csv_with_header(
        path, "id,student_id,amount,type,category,description,timestamp");

    json res;
    try {
        if (action == "list") {
            FILE* f = fopen(path, "rb");
            if (!f) {
                res["ok"] = false;
                res["error"] = {{"code", "io_error"},
                                {"message", "Cannot open accounting.csv"}};
            } else {
                char line[4096];
                // 读取并跳过表头
                if (!fgets(line, sizeof(line), f)) {
                    res["ok"] = true;
                    res["data"] = {{"items", json::array()}};
                } else {
                    auto headers = csv_split(line);
                    json items = json::array();
                    while (fgets(line, sizeof(line), f)) {
                        auto fields = csv_split(line);
                        if (fields.size() < 2) continue;
                        json item;
                        for (size_t i = 0;
                             i < headers.size() && i < fields.size(); i++) {
                            std::string val = fields[i];
                            trim_ascii(val);
                            item[headers[i]] = val;
                        }
                        items.push_back(item);
                    }
                    res["ok"] = true;
                    res["data"] = {{"items", items}};
                }
                fclose(f);
            }
        } else if (action == "add") {
            json p = json::parse(payload_json);
            std::string student_id = p.value("student_id", "");
            std::string amount = p.value("amount", "0");
            std::string type = p.value("type", "0");  // 0=income, 1=expense
            std::string category = p.value("category", "");
            std::string description = p.value("description", "");

            char ts_buf[64];
            now_iso(ts_buf);
            std::string id = gen_id("acc");

            // 清洗数据，防止 CSV 注入（移除逗号和换行）
            auto sanitize = [](std::string s) {
                s.erase(std::remove(s.begin(), s.end(), ','), s.end());
                s.erase(std::remove(s.begin(), s.end(), '\n'), s.end());
                s.erase(std::remove(s.begin(), s.end(), '\r'), s.end());
                return s;
            };

            std::stringstream ss;
            ss << id << "," << sanitize(student_id) << "," << sanitize(amount)
               << "," << sanitize(type) << "," << sanitize(category) << ","
               << sanitize(description) << "," << ts_buf;

            // 使用 common.hpp 中的 append_line
            if (append_line(path, ss.str().c_str())) {
                res["ok"] = true;
                res["data"] = {{"id", id}};
            } else {
                res["ok"] = false;
                res["error"] = {{"code", "io_error"},
                                {"message", "Failed to append to file"}};
            }
        } else if (action == "delete") {
            json p = json::parse(payload_json);
            std::string target_id = p.value("id", "");

            FILE* f = fopen(path, "rb");
            if (!f) {
                res["ok"] = false;
                res["error"] = {{"code", "io_error"},
                                {"message", "Cannot open file"}};
            } else {
                std::vector<std::string> lines;
                char line[4096];
                bool found = false;
                if (fgets(line, sizeof(line), f)) {
                    lines.push_back(line);  // 保留表头
                    while (fgets(line, sizeof(line), f)) {
                        auto fields = csv_split(line);
                        if (!fields.empty() && fields[0] == target_id) {
                            found = true;
                            continue;
                        }
                        lines.push_back(line);
                    }
                }
                fclose(f);

                if (found) {
                    FILE* fw = fopen(path, "wb");
                    for (const auto& l : lines) {
                        fputs(l.c_str(), fw);
                    }
                    fclose(fw);
                    res["ok"] = true;
                } else {
                    res["ok"] = false;
                    res["error"] = {{"code", "not_found"},
                                    {"message", "Record not found"}};
                }
            }
        } else {
            res["ok"] = false;
            res["error"] = {{"code", "bad_action"},
                            {"message", "Unknown action"}};
        }
    } catch (const std::exception& e) {
        res["ok"] = false;
        res["error"] = {{"code", "exception"}, {"message", e.what()}};
    } catch (...) {
        res["ok"] = false;
        res["error"] = {{"code", "unknown_exception"},
                        {"message", "An unknown error occurred"}};
    }

    return res.dump();
}

extern "C" {

EXPORT void accounting_free_string(char* s) {
    if (s) free(s);
}

static char* string_to_heap(const std::string& s) {
    char* res = (char*)malloc(s.size() + 1);
    if (res) {
        memcpy(res, s.c_str(), s.size() + 1);
    }
    return res;
}

EXPORT char* accounting_call(const char* data_dir, const char* action,
                             const char* payload_json) {
    std::string res =
        process_accounting(data_dir ? data_dir : "", action ? action : "",
                           payload_json ? payload_json : "{}");
    return string_to_heap(res);
}

}  // extern "C"
