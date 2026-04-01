/*
 * @Date: 2026-03-27 12:40:23
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-27 15:24:50
 * @FilePath: /Code/_CProgram/student class schedule.cpp
 */

#include <bits/stdc++.h>
using namespace std;
int main(int argc,char*argv[])
{
    if(argc<4)
    {
        printf("{\"status\":\"error \",\"message\":\"参数不足！格式:操作[add/query]"
            " 学号 姓名\"}\n");
             return 1;
    }
    char*op=argv[1];//操作类型 add/query
    char*IDnum=argv[2];//学号
    char*name=argv[3];//姓名

    //开始添加课表
    if(strcmp(op,"add")==0)
    {
        if(argc<8)
        {
            printf("{\"status\":\"error\",\"message\":\"参数不足！需要："
                "学号 姓名 星期 节次 课程\"}\n");
                return 1;
        }
        char *week=argv[4];
        char*timeSlot=argv[5];
        char*course=argv[6];
        char*classplace=argv[7];
        FILE*file=fopen("schedule.csv","a");
        if(file==NULL)
        {
            printf("{\"status\":\"error\", \"message\":\"无法打开课表文件\"}\n");
        return 1;
        }

        //存入部分
        fprintf(file,"%s,%s,%s,%s,%s,%s",
       IDnum,name,week,timeSlot,course ,classplace);

       fclose(file);
       printf(
        "{\"status\":\"success\", \"message\":\"添加课表成功\", "
        "\"IDnum\":\"%s\", \"name\":\"%s\"}\n",
        IDnum, name);

    }
    
    //查询课表（学号加姓名）
    else if(strcmp(op,"query")==0)  {
        //只读打开文件“r”
        FILE*file=fopen("student schedule.csv","r");
        if(file==NULL)
        {
            printf("{\"status\":\"error\", \"message\":\"无法打开课表文件\"}\n");
           return 1;
        } 

        printf(
        "{\"status\":\"success\", \"message\":\"课表打开成功\", "
        "\"IDnum\":\"%s\", \"name\":\"%s\",\"schedule\":[",
        IDnum, name);

       char line[256];
       int first=1;
       while(fgets(line,sizeof(line),file)!=NULL)
       {
        line[strcspn(line,"\n")]=0;
        char IDnum[100],name[100],week[100],timeSlot[100],course[100],classplace[100];
        sscanf(line,"%[^,],%[^,],%[^,],%[^,],%[^,],%[^,]",IDnum,name,week,timeSlot,course,classplace);
       
        if(strcmp(IDnum,name )==0)
       {
          if(!first) printf(",");
        
          printf("{\"week\":\"%s\",\"timeSlot\":\"%s\",\"course\":\"%s\",\"classplace\":\"%s\"}",week,timeSlot,course,classplace);
           first=0;   
        }
    }
    printf("]}\n");
    fclose(file);
      }else{
         printf("{\"status\":\"error\",\"message\":\"仅支持add/query\"}\n");
         return 1;
        }
       

    return 0;
}