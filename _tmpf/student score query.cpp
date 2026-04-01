/*
 * @Date: 2026-03-30 15:29:45
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-30 23:00:45
 * @FilePath: /Code/_CProgram/student score query.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main(int argc,char*argv[])
{
    if(argc<3)
    {
        printf("{\"status\":\"error\",\"message\":\"参数不足！需要：姓名 学号\"}\n");
        return 1;
    }
    char*name=argv[1];
    char*ID=argv[2];
    FILE*file=fopen("score.csv","r");
    if(file==NULL)
    {
      printf("{\"status\":\"error\", \"message\":\"无法查询成绩文件\"}\n");
      return 1;
    }
    //查询并输出
    printf("{\"status\":\"success\",\"message\":\"成绩查询成功\","
    "\"name\":\"%s\",\"ID\":\"%s\"}\n",name,ID);
      char id[50],Name[50],course[50],score[10];
      int first=1;
      while(fscanf(file,"%49[^,],%49[^,],%49[^,],%9[^\n]\n",id,Name,course,score)==4)
      {
       if(strcmp(id,ID)==0)
       {
        if(!first)printf(",\n");
        printf("{\"course\":\"%s\",\"score\":\"%s\"}",course,score);
        first=0;
       }
       printf("\n]}\n");
      }
      fclose(file);
    
        return 0;
}