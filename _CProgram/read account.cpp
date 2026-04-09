/*
 * @Date: 2026-04-01 11:02:40
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-01 11:24:17
 * @FilePath: /Code/_CProgram/read account
 */
#include <bits/stdc++.h>
using namespace std;
int main(int argc, char* argv[]) 
{
    FILE*file= fopen("accounts.csv","a");
     if(file==NULL)
     {
        printf("{\"status\":\"erorr\",\"message\":\"无法打开记账文本}\n");
        return 1;
     }


    //JOSN数组开始
    printf("[");
    char line[1024];
    int first=1;//控制逗号分隔
     while(fgets(line,sizeof(line),file))
     {
        //除去换行符
        line[strcspn(line,"\n")]='\0';
        //开始逗号分隔
        char*time=strtok(line,",");//line表示从开头位置切割
        char*type=strtok(NULL,",");//NULL是从上次位置继续切割
        char*amount=strtok(NULL,",");
        char*note=strtok(NULL,",");
        if(!time||!type||!amount||!note)
        {
            continue;
        }
        if(!first)
        {
            printf(",");
        }
        first=0;
       //输出一条JOSN对象
        printf("{\"time\":\"%s\",\"type\":\"%s\",\"amount\":\"%s\","
            "\"note\":\"%s\"}\n",time,type,amount,note);
     }
     fclose(file);
     printf("]");

    return 0;
}