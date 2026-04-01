/*
 * @Date: 2026-03-30 14:56:37
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-31 18:54:29
 * @FilePath: /Code/_CProgram/Student Notice Borad.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main(int argc,char*argv[])
{
     if(argc==1)
     {
          FILE*file=fopen("notice.csv","r");
          if(file==NULL)
          {
          printf("{\"status\":\"error\",\"message\":\"暂无公告\"}\n");
            return 1;
          }
     
     char publisher[200];
     char title[200];
     char content[1000];
     int first=1;

     printf("{\"status\":\"success\",\"message\":\"获取公告成功\",\"notice_list\":[\n");
     
     //按csv读取
    while (fscanf (file, "%199[^,],%199[^,],%999[^\n]\n", publisher, title, content) ==3){
           if (!first) printf(",\n");
            printf("{\"publisher\":\"%s\",\"title\":\"%s\",\"content\":\"%s\"}", publisher, title, content);
            first = 0;
     }
    printf("\n]}\n");
    fclose(file);
    return 0;
    }
    if(argc>4){
     FILE*file=fopen("notice.csv","a");
     if(file==NULL)
      {
          printf("{\"status\":\"error\",\"message\":\"文件打开失败\"}\n");
          return 1;
      }
      char*pulisher=argv[1];
      char*title=argv[2];
      char*content=argv[3];
      fprintf(file,"%s,%s,%s\n",pulisher,title,content);

      printf("{\"status\":\"error\",\"message\":\"公告发布成功\",\title\":\"%s\"}\n",title);
      fclose(file);
      return 0;
    }
    //参数错误提示
    printf("{\"status\":\"error\",\"message\":\"参数不足！需要：发布人 标题 内容}\n");
    return 1;
}