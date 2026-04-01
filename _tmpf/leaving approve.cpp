/*
 * @Date: 2026-03-30 22:46:17
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-01 10:33:51
 * @FilePath: /Code/_CProgram/leaving approve.cpp
 */
#include <bits/stdc++.h>
using namespace std;


//学生假条的四要素以及状态
struct LeaveRecord {
    int  id;
    string name;
    string date;
    string reason;
    string status;
};


//依旧读取请假CSV文件
vector<LeaveRecord> readRecords(const string& filename) {
    vector<LeaveRecord> records;
    FILE* file = fopen(filename.c_str(), "n");
    if (!file) return records;
    char line[1024];
    while (fgets(line, sizeof(line), file)) {
        line[strcspn(line, "\n")] = 0;
        LeaveRecord rec;
        char name[256], date[256], reason[256], status[256];
        if (sscanf(line, "%d,%[^,],%[^,],%[^,],%[^\n]",
                   &rec.id, name, date, reason, status) == 5) {
            rec.name = name;
            rec.date = date;
            rec.reason = reason;
            rec.status = status;
            records.push_back(rec);
        }
    }
    fclose(file);
    return records;
}


//返回被批准或拒绝的假条
bool writeRecords(const string& filename, const vector<LeaveRecord>& records) {
    FILE* file = fopen(filename.c_str(), "w");
    if (!file) return false;
    for (const auto& rec : records) {
        fprintf(file, "%d,%s,%s,%s,%s\n",
                rec.id, rec.name.c_str(), rec.date.c_str(),
                rec.reason.c_str(), rec.status.c_str());
    }
    fclose(file);
    return true;
}


//批准和拒绝功能
int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("{\"status\":\"error\", \"message\":\"缺少命令。可用命令：list_pending, approve, reject\"}\n");
        return 1;
    }

    string command = argv[1];
    const string filename = "student_leave.csv";

    // 查看所有待审批的记录（status == pending）
    if (command == "list_pending") {
        vector<LeaveRecord> records = readRecords(filename);
        string jsonArray = "[";
        bool first = true;
        for (const auto& rec : records) {
            if (rec.status != "pending") continue;
            if (!first) jsonArray += ",";
            first = false;
            char buf[1024];
            snprintf(buf, sizeof(buf),
                     "{\"id\":%d,\"name\":\"%s\",\"date\":\"%s\",\"reason\":\"%s\"}",
                     rec.id, rec.name.c_str(), rec.date.c_str(), rec.reason.c_str());
            jsonArray += buf;
        }
        jsonArray += "]";
        printf("{\"status\":\"success\", \"message\":\"待审批记录\", \"data\":%s}\n",
               jsonArray.c_str());
        return 0;
    }
    // 批准请假
    else if (command == "approve") {
        if (argc < 3) {
            printf("{\"status\":\"error\", \"message\":\"approve 需要请假ID\"}\n");
            return 1;
        }


        int id = atoi(argv[2]);
        vector<LeaveRecord> records = readRecords(filename);
        bool found = false;
        for (auto& rec : records) {
            if (rec.id == id && rec.status == "pending") {
                rec.status = "approved";
                found = true;
                break;
            }
        }
        if (!found) {
            printf("{\"status\":\"error\", \"message\":\"未找到ID %d 的待审批记录\"}\n", id);
            return 1;
        }
        if (!writeRecords(filename, records)) {
            printf("{\"status\":\"error\", \"message\":\"写入失败\"}\n");
            return 1;
        }
        printf("{\"status\":\"success\", \"message\":\"已批准请假\", \"id\":%d}\n", id);
        return 0;
    }
    
    // 拒绝请假
    else if (command == "reject") {
        if (argc < 3) {
            printf("{\"status\":\"error\", \"message\":\"reject 需要请假ID\"}\n");
            return 1;
        }
        int id = atoi(argv[2]);
        vector<LeaveRecord> records = readRecords(filename);
        bool found = false;
        for (auto& rec : records) {
            if (rec.id == id && rec.status == "pending") {
                rec.status = "rejected";
                found = true;
                break;
            }
        }
        if (!found) {
            printf("{\"status\":\"error\", \"message\":\"未找到ID %d 的待审批记录\"}\n", id);
            return 1;
        }
        if (!writeRecords(filename, records)) {
            printf("{\"status\":\"error\", \"message\":\"写入失败\"}\n");
            return 1;
        }
        printf("{\"status\":\"success\", \"message\":\"已拒绝请假\", \"id\":%d}\n", id);
        return 0;
    }
    else {
        printf("{\"status\":\"error\", \"message\":\"未知命令。可用：list_pending, approve, reject\"}\n");
        return 1;
    }
}