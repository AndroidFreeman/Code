/*
 * @Date: 2026-03-25 22:48:50
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 01:02:39
 * @FilePath: /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/find.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char* argv[]) {
    // 预期参数: argv[1]=数据根目录, argv[2]=文件名, argv[3]=关键词
    // 这样 Dart 就可以把 Android 的私有路径传进来
    if (argc < 3) {
        printf("[]\n");
        return 0;
    }

    char* base_path = argv[1];
    char* filename = argv[2];
    char* keyword = (argc > 3) ? argv[3] : "";

    char path[512];
    // 适配全平台：由外部注入绝对路径
    sprintf(path, "%s/%s.csv", base_path, filename);

    FILE* fp = fopen(path, "r");
    if (!fp) {
        // 如果文件不存在，Android 下不再崩溃，而是优雅返回空数组
        printf("[]\n");
        return 0;
    }

    char line[1024];
    int first = 1;
    printf("[");
    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\r\n")] = 0;
        if (strlen(keyword) == 0 || strstr(line, keyword)) {
            if (!first) printf(",");
            printf("\"%s\"", line);
            first = 0;
        }
    }
    printf("]\n");
    fclose(fp);
    return 0;
}