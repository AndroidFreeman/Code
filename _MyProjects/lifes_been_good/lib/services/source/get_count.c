/*
 * @Date: 2026-03-25 23:08:52
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-25 23:08:53
 * @FilePath:
 * /Code_Sync/_MyProjects/lifes_been_good/lib/services/source/get_count.c
 */
#include <stdio.h>

int main() {
    int count = 0;
    FILE* cf = fopen("data/backup_count.txt", "r");
    if (cf) {
        fscanf(cf, "%d", &count);
        fclose(cf);
    }
    printf("%d", count);
    return 0;
}