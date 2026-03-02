/*
 * @Date: 2026-03-02 20:00:55
 * @Github: https://github.com/AndroidFreeman
 * Linux Kernel: 7.0-rc2-Freeman-V7
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-02 22:51:43
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-03-02_3.cpp
 */

// 有n个重量分别为{w1，w2，…，wn}的物品，
// 它们的价值分别为{v1，v2，…，vn}，
// 给定一个容量为W的背包。
// 设计从这些物品中选取一部分物品放入该背包的方案，
// 每个物品要么选中要么不选中，
// 要求选中的物品不仅能够放到背包中，
// 而且重量和为W具有最大的价值。

#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int storage = 10;
    int itemNumber = 5;
    vector<int> weight = {0, 2, 2, 6, 5, 4};
    vector<int> value = {0, 6, 3, 5, 4, 6};

    int process[storage+5][itemNumber+5];
    memset(process, 0, sizeof(process));

    for (int i = 1; i <= itemNumber; i++) {
        for (int j = 1; j <= storage; j++) {
            if (j < weight[i]) {
                process[j][i] = process[j][i - 1];
            } else {
                process[j][i] = max(process[j][i - 1],
                                    process[j - weight[i]][i - 1] + value[i]);
            }
        }
    }

    int r = storage;
    for (int i = itemNumber; i >= 1; i--) {
        if (process[r][i] != process[r][i - 1]) {
            cout << "Choose " << i << " (weight: " << weight[i]
                 << ", value: " << value[i] << ")" << endl;
            r -= weight[i];
        }
    }
}