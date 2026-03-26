/*
 * @Date: 2026-03-26 19:38:10
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 20:20:13
 * @FilePath: /Code/_CProgram/delete.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main(int argc, char* argv[]){
        if (argc < 3) {
        // 如果参数不够，打印一个错误的 JSON 告诉前端
        printf(
            "{\"status\":\"error\", \"message\":\"参数不足！需要：姓名 "
            "\"}\n");
        return 1;  // 返回 1 表示出错了

            char*deletename = argv[1];  // 比如 "张三"
            char* id = argv[2];   

    //重写文件去掉对应行            
    FILE *oldFile=fopen("database.csv", "r");

    FILE*newFile=fopen("database.csv", "w");
     if(oldFile==NULL||newFile==NULL)
     {
        printf("{\"status\":\"error\", \"message\":\"无法打开数据库文件\"}\n");
        return 1;
     }
    
    char line[1024];
    int Found=0;
        while(fgets(line,sizeof(line),oldFile)!=NULL)
        {
            //去掉\n避免影响字符串比较
            line[strcspn(line, "\n"]=0;
        }

        char currentName[100];
        sscanf(line,"%[^,],currentName");



    fclose(oldFile);
    fclose(newFile);
        printf(
        "{\"status\":\"success\", \"message\":\"保存成功\", "
        "\"saved_name\":\"%s\"}\n",
        name);

    return 0;  // 返回 0 表示完美执行

}