/*
 * @Date: 2026-03-10 21:56:06
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-10 22:07:49
 * @FilePath: /Code_Sync/Luogu/Enum_Practice/2_P1025.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int n, k;
int answer = 0;
void dfs(int index, int min, int sum) {
    if (index == k + 1) {
        if (sum == n) answer++;
        return;
    }
    for (int i = min; i + sum <= n; i++) {
        dfs(index + 1, i, sum + i);
    }
    return;
}
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    if (!(cin >> n >> k)) return -1;
    dfs(1, 1, 0);
    cout << answer;
    return 0;
}
