/*
 * @Date: 2026-03-26 22:47:43
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 23:41:44
 * @FilePath: /Code_Sync/_CProgram/teacherID.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    if (argc < 6) {
        printf(
            "{\"status\":\"error\", \"message\":\"参数不足!需要:教师ID "
            "姓名 性别 所属学院  登录密码\"}\n");
        return 1;
    }

    // ---- 第二步：接收前端传来的数据 ----
    char* name = argv[1];
    char* sex = argv[2];
    char* IDnum = argv[3];
    char* school = argv[4];
    char* password = argv[5];

    // ---- 第三步：执行你的逻辑（比如写文件、计算等） ----
    // 这里是你的核心代码，比如把数据存进 CSV 文件
    FILE* file = fopen("database.csv", "a");  // 以“追加”模式打开文件
    if (file == NULL) {
        printf("{\"status\":\"error\", \"message\":\"无法打开数据库文件\"}\n");
        return 1;
    }

    fprintf(file, "%s,%s,%s,%s,%s\n", name, sex, IDnum, school, password);
    fclose(file);  // 记得关文件

    printf(
        "{\"status\":\"success\", \"message\":\"教师注册成功\", "
        "\"IDnum\":\"%s\", \"name\":\"%s\", \"school\":\"%s\"}\n",
        IDnum, name, school);

    return 0;
}