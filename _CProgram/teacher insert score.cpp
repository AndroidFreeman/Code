/*
 * @Date: 2026-03-30 15:10:56
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-30 15:27:19
 * @FilePath: /Code/_CProgram/teacher insert score.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main(int argc,char*argv[])
{
    if(argc<5)
    {
        printf("{\"status\":\"error\",\"message\":\"参数不足！需要：学号 姓名"
            "课程 成绩\"}\n");
            return 1;
    }
    char *id=argv[1];
     char*name=argv[2];
     char*course=argv[3];
     char*score=argv[4];
     
   //开始写入成绩
    FILE*file=fopen("score.csv","a");
    if(file==NULL)
    {
        printf("{\"status\":\"error\",\"message\":\"无法打开成绩文件\"}\n");
        return 1;
    }
    fprintf(file,"%s,%s,%s,%s\n",id,name,course,score);
    fclose(file);
    printf("{\"status\":\"success\",\"message\":\"成绩录入成功\",\"student_id:"
        "\"%s\",\"course\":\"%s\"}\n",id,course);
    return 0;
}