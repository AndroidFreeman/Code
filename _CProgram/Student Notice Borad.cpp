/*
 * @Date: 2026-03-30 14:56:37
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-30 15:07:19
 * @FilePath: /Code/_CProgram/Student Notice Borad.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main(int argc,char*argv[])
{
    if(argc<4)
    {
        printf(
            "{\"status\":\"error\", \"message\":\"参数不足!需要:教师ID "
            "学号  姓名  公告内容\"}\n");
        return 1;
    }
    char *id=argv[1];
    char*name=argv[2];
    char*content=argv[3];
     FILE*file=fopen("note_board.csv","a");
     if(file==NULL)
     {
        printf("{\"status\":\"error\",\"message\":\"无法打开公告文件\"}\n");
     
         return 1;
     } 

     fprintf(file,"%s,%s,%s\n",id,name,content);

    fclose(file);
    printf("{\"status\":\"success\",\"message\":\"公告发布成功\","
        "\"student_id\":\"%s\",\"student_name\":\"%s\"}\n",id,name);
     return 0;
}

