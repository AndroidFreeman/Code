/*
 * @Date: 2026-03-25 23:04:11
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-25 23:04:12
 * @FilePath:
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/delete.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * LBG Core - Delete Plugin
 * 逻辑：流式读写，过滤关键词，重定向覆盖
 */
int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("ERROR: 缺少删除关键词\n");
        return 1;
    }

    char* keyword = argv[1];
    char* file_path = "data/data.csv";
    char* temp_path = "data/data.tmp";

    FILE* fp = fopen(file_path, "r");
    if (!fp) {
        printf("ERROR: 找不到数据文件，无需删除\n");
        return 0;
    }

    FILE* tp = fopen(temp_path, "w");
    if (!tp) {
        printf("ERROR: 无法创建临时文件\n");
        fclose(fp);
        return 1;
    }

    char line[1024];
    int delete_count = 0;

    // 逐行读取，如果不包含关键词，就写入临时文件
    while (fgets(line, sizeof(line), fp)) {
        if (strstr(line, keyword)) {
            delete_count++;
            continue;  // 跳过这一行，实现删除
        }
        fputs(line, tp);
    }

    fclose(fp);
    fclose(tp);

    // 用临时文件覆盖原文件
    if (delete_count > 0) {
        remove(file_path);
        rename(temp_path, file_path);
        printf("SUCCESS: 已清理 %d 条包含 [%s] 的记录\n", delete_count,
               keyword);
    } else {
        remove(temp_path);  // 没删掉东西，直接删掉临时文件
        printf("INFO: 未发现匹配记录，文件未改动\n");
    }

    return 0;
}