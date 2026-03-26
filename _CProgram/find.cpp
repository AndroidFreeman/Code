/*
 * @Date: 2026-03-26 22:31:20
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 22:44:57
 * @FilePath: /Code/_CProgram/find.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    // ---- 第一步：检查参数够不够 ----
    // argv[0] 是程序名自己，argv[1] 是第一个参数，以此类推
    if (argc < 3) {
        // 如果参数不够，打印一个错误的 JSON 告诉前端
        printf(
            "{\"status\":\"error\", \"message\":\"参数不足！需要：姓名 "
            "年龄\"}\n");
        return 1;  // 返回 1 表示出错了
    }

    // ---- 第二步：接收前端传来的数据 ----
    char* name = argv[1];  // 比如 "张三"
    char* age = argv[2];   // 比如 "20"

    // ---- 第三步：执行你的逻辑（比如写文件、计算等） ----
    // 这里是你的核心代码，比如把数据存进 CSV 文件
    FILE* file = fopen("database.csv", "a");  // 以“追加”模式打开文件
    if (file == NULL) {
        printf("{\"status\":\"error\", \"message\":\"无法打开数据库文件\"}\n");
        return 1;
    }

    // 写入一行：姓名,年龄
    fprintf(file, "%s,%s\n", name, age);
    fclose(file);  // 记得关文件

    // ---- 第四步：大功告成，反馈给前端 ----
    // 💡 注意：JSON 里的双引号在 C 语言里要写成 \"
    // 这一行打印出来，Flutter 就能抓到并显示在 UI 上
    printf(
        "{\"status\":\"success\", \"message\":\"保存成功\", "
        "\"saved_name\":\"%s\"}\n",
        name);

    return 0;  
}