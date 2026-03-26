/*
 * @Date: 2026-03-25 22:58:09
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 01:15:16
 * @FilePath: /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/insert.c
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/insert.c
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/insert.c
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/insert.c
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/insert.c
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/insert.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
    #include <direct.h>
    #include <io.h>
    #define F_OK 0
    #define access _access
    #define mkdir(path, mode) _mkdir(path)
#else
    #include <unistd.h>
    #include <sys/stat.h>
    #include <sys/types.h>
#endif

// 递归创建目录函数 (解决 Android 私有路径多层级问题)
void recursive_mkdir(const char *path) {
    char tmp[512];
    char *p = NULL;
    size_t len;

    snprintf(tmp, sizeof(tmp), "%s", path);
    len = strlen(tmp);
    if (tmp[len - 1] == '/') tmp[len - 1] = 0;
    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;
            mkdir(tmp, 0777);
            *p = '/';
        }
    }
    mkdir(tmp, 0777);
}

int main(int argc, char* argv[]) {
    // 预期：argv[1]=根目录, argv[2]=表名(classes/students), argv[3...]=CSV数据字段
    if (argc < 4) {
        fprintf(stderr, "USAGE: %s <base_path> <table> <data1> [data2...]\n", argv[0]);
        return 1;
    }

    char* base_path = argv[1]; 
    char* table = argv[2];     

    // 1. 递归确保目录存在
    recursive_mkdir(base_path);

    // 2. 安全拼接完整路径 (防止缓冲区溢出)
    char full_path[1024];
    snprintf(full_path, sizeof(full_path), "%s/%s.csv", base_path, table);

    // 3. 追加写入 (使用 "ab" 模式防止 Windows 下的换行符解析问题)
    FILE* fp = fopen(full_path, "ab"); 
    if (fp) {
        // 核心改进：循环处理 argv[3] 之后的所有参数，并用逗号连接
        for (int i = 3; i < argc; i++) {
            fprintf(fp, "%s", argv[i]);
            if (i < argc - 1) {
                fprintf(fp, ",");
            }
        }
        fprintf(fp, "\n"); // 写入换行符
        fclose(fp);
        
        // 输出给 Flutter 确认
        printf("SUCCESS: Recorded to %s\n", table);
    } else {
        fprintf(stderr, "FOPEN_FAILED: %s\n", full_path);
        return 1;
    }

    return 0;
}