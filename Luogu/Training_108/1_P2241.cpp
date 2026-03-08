/*
 * @Date: 2026-03-08 10:23:29
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-08 10:45:59
 * @FilePath: /Code_Sync/Luogu/Training_108/1_P2241.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long n, m, zheng = 0, chang = 0;
    cin >> n >> m;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            if (i == j)
                zheng += (n - i) * (m - j);
            else
                chang += (n - i) * (m - j);
        }
    }
    cout << zheng << ' ' << chang;
    return 0;
}