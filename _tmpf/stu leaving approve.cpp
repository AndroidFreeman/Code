/*
 * @Date: 2026-03-30 23:32:01
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-01 10:22:35
 * @FilePath: /Code/_CProgram/stu leaving approve.cpp
 */
#include <bits/stdc++.h>
using namespace std;

//请假四要素，加一个状态（待处理  批准或是拒绝）
struct LeaveRecord {
    int  id;
    string name;
    string date;
    string reason;
    string status; // pending, approved, rejected
};

//读取CSV文件里的请假记录
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


//把批准或拒绝的假条 返回录入到CSV文件中
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


//提交新的请假记录
int getNextId(const vector<LeaveRecord>& records) {
    int maxId = 0;
    for (const auto& rec : records) if (rec.id > maxId) maxId = rec.id;
    return maxId + 1;
}



//主功能 申请请假submit 和 查看请假状态表list
int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("{\"status\":\"error\", \"message\":\"缺少命令。可用命令：submit, list\"}\n");
        return 1;
    }

    string command = argv[1];
    const string filename = "student_leave.csv";

    if (command == "submit") {
        if (argc < 5) {
            printf("{\"status\":\"error\", \"message\":\"submit 需要：姓名 日期 事由\"}\n");
            return 1;
        }
        string name = argv[2], date = argv[3], reason = argv[4];
        vector<LeaveRecord> records = readRecords(filename);
        int newId = getNextId(records);
        LeaveRecord newRec = {newId, name, date, reason, "pending"};
        records.push_back(newRec);
        if (!writeRecords(filename, records)) {
            printf("{\"status\":\"error\", \"message\":\"写入失败\"}\n");
            return 1;
        }
        printf("{\"status\":\"success\", \"message\":\"请假申请已提交\", \"id\":%d, \"name\":\"%s\"}\n",
               newId, name.c_str());
        return 0;
    }
    else if (command == "list") {
        vector<LeaveRecord> records = readRecords(filename);
        if (argc < 3) {
            printf("{\"status\":\"error\", \"message\":\"list 需要提供学生姓名\"}\n");
            return 1;
        }
        string studentName = argv[2];
        string jsonArray = "[";
        bool first = true;
        for (const auto& rec : records) {
            if (rec.name != studentName) continue;
            if (!first) jsonArray += ",";
            first = false;
            char buf[1024];
            snprintf(buf, sizeof(buf),
                     "{\"id\":%d,\"date\":\"%s\",\"reason\":\"%s\",\"status\":\"%s\"}",
                     rec.id, rec.date.c_str(), rec.reason.c_str(), rec.status.c_str());
            jsonArray += buf;
        }
        jsonArray += "]";
        printf("{\"status\":\"success\", \"message\":\"%s 的请假记录\", \"data\":%s}\n",
               studentName.c_str(), jsonArray.c_str());
        return 0;
    }
    else {
        printf("{\"status\":\"error\", \"message\":\"未知命令。可用：submit, list\"}\n");
        return 1;
    }
}





























