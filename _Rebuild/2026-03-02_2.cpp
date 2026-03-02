/*
 * @Date: 2026-03-02 19:20:08
 * @Github: https://github.com/AndroidFreeman
 * Linux Kernel: 7.0-rc2-Freeman-V7
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-02 23:00:11
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-03-02_2.cpp
 */

// 求将正整数n无序拆分成最大数为k（称为n的k拆分）
// 的拆分方案个数，要求所有的拆分方案不重复。

#include <bits/stdc++.h>
using namespace std;
const int MAXN = 101;
int dp(int number, int max) {
    int temp[MAXN][MAXN];
    for (int i = 1; i <= number; i++) {
        for (int j = 1; j <= max; j++) {
            if (j == 1 || i == 1) {
                temp[i][j] = 1;
            } else if (i == j) {
                temp[i][j] = 1 + temp[i][j - 1];
            } else if (i < j) {
                temp[i][j] = temp[i][i];
            } else {
                temp[i][j] = temp[i - j][j] + temp[i][j - 1];
            }
        }
    }
    return temp[number][max];
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int number, max;
    // cin>>number>>max;
    number = 5, max = 5;
    cout << dp(number, max) << endl;
}