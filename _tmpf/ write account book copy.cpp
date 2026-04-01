/*
 * @Date: 2026-04-01 21:21:14
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-01 21:21:23
 * @FilePath: /Code/_tmpf/ write account book copy.cpp
 */
/*
 * @Date: 2026-04-01 10:21:28
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-01 10:55:40
 * @FilePath: /Code/_CProgram/accout book.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main(int argc, char* argv[]) {
    // 检查参数
    if (argc < 4) {
        printf(
            "{\"status\":\"error\",\"message\":\"参数不足！ 需要："
            "类型（收入/支出）金额 备注 \"}\n");
        return 1;
    }
    printf("{\"status\":\"error\",\"message\":\"打开记账文件成功 \"}\n");
    // 接收前端传来的数据
    char* type = argv[1];  // income  或者  expense
    char* amount = argv[2];
    char* note = argv[3];
    FILE* file = fopen("accounts.csv", "a");
    if (file == NULL) {
        printf("{\"status\":\"erorr\",\"message\":\"无法打开记账文本}\n");
        return 1;
    }
    // 获取当前时间系统，作为记录时间戳
    time_t now = time(NULL);
    char* time_str = ctime(&now);
    // ctime自带换行符，去掉它
    time_str[strcspn(time_str, "\n")] = '\0';
    // strcspn(time_str,"\n")返回的是数值相当于数组下标

    // 写入格式：时间 类型 金额 备注内容
    fprintf(file, "%s,%s,%s,%s\n", time_str, type, amount, note);
    fclose(file);
    printf(
        "{\"status\":\"success\",\"message\":\"记账成功\","
        "\type\":\"%s\",\"amount\":\"%s\"}\n",
        type, amount);
    return 0;
}