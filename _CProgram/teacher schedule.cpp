/*
 * @Date: 2026-03-27 15:13:25
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-27 17:43:26
 * @FilePath: /Code/_CProgram/teacher schedule.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    if (argc < 6) {
        // 如果参数不够，打印一个错误的 JSON 告诉前端
        printf(
            "{\"status\":\"error\", \"message\":\"参数不足！需要：姓名 "
            "课程 时间(输入第几节课 第一节课 输入 1) 地点 周几(例 :  周一 则输入 1 )\"}\n");
        return 1;  // 返回 1 表示出错了
    }

  
    char* name = argv[1];  
    char* course = argv[2];  
    char* time=argv[3];
    char* place =argv[4];
    char*weekday=argv[5];
    
    int weekday_num=atoi(weekday);
    if(weekday_num < 1||weekday_num > 7) {
        cout<<"{ \" status \": \"error\" ,\"message\":\"周几必须是1到7之间的数字\"  }\n "  <<endl;
        return 1;            
    }
      
 
   int time_num=atoi(time); 
if(time_num < 1|| time_num > 12) {
        cout<<"{ \" status \": \"error\" ,\"message\":\"课程时间必须是1到12之间的数字\"  }\n "  <<endl;
        return 1;            
    }



    FILE* check_file = fopen("teacher_schedule.csv", "r");
    if (check_file != NULL) {
        char line[512];
        int conflict = 0;
        
        while (fgets(line, sizeof(line), check_file)) {
            
            char stored_name[50], stored_course[100], stored_weekday[10];
            char stored_time[15], stored_place[300];
            
            // 解析CSV行
            sscanf(line, "%[^,],%[^,],%[^,],%[^,],%[^\n]", 
                   stored_name, stored_course, stored_weekday,
                   stored_time, stored_place);
            
            // 检查冲突条件
            if (
                strcmp(stored_weekday, weekday) == 0 &&
                strcmp(stored_time, time) == 0 &&
                strcmp(stored_place,place) == 0) {
                conflict = 1;
                break;
            }
        }
        fclose(check_file);
        
        if (conflict) {
            printf("{\"status\":\"error\", \"message\":\"排课冲突！该教室在星期%s第%s节已被占用\"}\n",
                  weekday, time);
            return 1;
        }
    }



    FILE* file = fopen("teacher_schedule.csv", "r");  // 以“追加”模式打开文件
    if (file == NULL) {
        printf("{\"status\":\"error\", \"message\":\"无法打开排课数据文件\"}\n");
        return 1;
    }


    fprintf(file, "%s,%s,%s,%s,%s\n", name, course,time,place,weekday);
    fclose(file);  // 记得关文件


   const char* weekday_name[]  =  { "","周一","周二"," 周三 ", " 周四 ", "周五" , "周六" , "周天"   };
   const char*weekday_look=weekday_name[weekday_num];    



    printf(
        "{\"status\":\"success\", \"message\":\"排课成功！\", "
        "\"name\":\"%s\" , \"course\":\"%s\",\"time\":\"%s\",\"place\":\"%s\",\"weekday_look\":\"%s\"}\n",
        name,course,time,place,weekday_look);

    return 0;  
}