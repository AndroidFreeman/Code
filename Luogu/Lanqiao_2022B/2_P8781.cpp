/*
 * @Date: 2026-03-09 22:39:43
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 22:54:16
 * @FilePath: /Code_Sync/Luogu/Lanqiao_2022B/2_P8781.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n;
    if (!(cin >> n)) return 0;

    for (int i = 1; i <= n; i++) {
        int maxHeight = max(i - 1, n - i) * 2;
        cout << maxHeight << "\n";
    }

    return 0;
}