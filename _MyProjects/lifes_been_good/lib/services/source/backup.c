/*
 * @Date: 2026-03-25 23:07:49
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 01:05:25
 * @FilePath:
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/backup.c
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/backup.c
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/backup.c
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/backup.c
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/backup.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>

int main(int argc, char* argv[]) {
    // 参数: [1]根目录
    if (argc < 2) return 1;
    char* base = argv[1];

    char bak_dir[512], src[512], dst[512];
    sprintf(bak_dir, "%s/backup", base);

    // 强制创建备份文件夹
#ifdef _WIN32
    mkdir(bak_dir);
#else
    mkdir(bak_dir, 0777);
#endif

    sprintf(src, "%s/classes.csv", base);
    sprintf(dst, "%s/backup/bak_%lld.csv", base, (long long)time(NULL));

    // 使用标准 C 文件流拷贝，避开 system("cp") 的权限坑
    FILE *s = fopen(src, "rb"), *d = fopen(dst, "wb");
    if (s && d) {
        char buf[4096];
        size_t n;
        while ((n = fread(buf, 1, sizeof(buf), s)) > 0) fwrite(buf, 1, n, d);
    }
    if (s) fclose(s);
    if (d) fclose(d);
    printf("BACKUP_DONE");
    return 0;
}