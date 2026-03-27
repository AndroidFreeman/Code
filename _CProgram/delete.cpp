/*
 * @Date: 2026-03-26 19:38:10
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-27 15:45:31
 * @FilePath: /Code/_CProgram/delete.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main(int argc, char* argv[])
{
         if (argc < 3) {
        // 如果参 数不够，打印一个错误的 JSON 告诉前端
        printf(
            "{\"status\":\"error\", \"message\":\"参数不足！需要：姓名 "
            "\"}\n");
        return 1;  // 返回 1 表示出错了
        }

            char*deletename = argv[1];  // 比如 "张三"
            char* deleteID = argv[2];   

    //重写文件去掉对应行            
    FILE *oldFile=fopen("database.csv", "r");

    FILE*newFile=fopen("temp.csv", "w");
     if(oldFile==NULL)
     {
        printf("{\"status\":\"error\", \"message\":\"无法打开数据库文件\"}\n");
        return 1;
     }

     if(newFile==NULL)
     {
        printf("{\"status\":\"error\", \"message\":\"无法创建临时文件\"}\n");
        return 1;
     }
    
    char line[1024];
    int found=0;
    char currentName[100],currentID[100],currentschool[100];
    char sex[100],currentpassword[100];
        while(fgets(line,sizeof(line),oldFile)!=NULL)
        {
            //去掉\n避免影响字符串比较
            line[strcspn(line, "\n")]=0;
            //注意在拆分时要考虑insert里的存入顺序
        sscanf(line," %[^,],%[^,],%[^,],%[^,],%[^,]",currentName,sex,currentID,currentschool,currentpassword);
         if(strcmp(currentID,deleteID )==0&&strcmp(currentName,deletename )==0)
         {
            found=1;
         }else{
            fprintf(newFile,"%s\n",line);
         }
        }

        fclose(oldFile);
        fclose(newFile);
        remove("database.csv");
        rename("temp.csv","database.csv");
        

        if(found)
        {
            printf(
        "{\"status\":\"success\", \"message\":\"删除成功\", "
        " \"deletename\":\"%s\", \"deleteID\":\"%s\"}\n",
       deletename,deleteID );
        }else{
             printf(
        "{\"status\":\"success\", \"message\":\"未找到该学生\", "
        " \"deletename\":\"%s\", \"deleteID\":\"%s\"}\n",
       deletename,deleteID );
        }
        
    return 0;  // 返回 0 表示完美执行

}