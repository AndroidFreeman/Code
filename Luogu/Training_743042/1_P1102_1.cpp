/*
 * @Date: 2026-03-11 22:26:22
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-11 22:33:40
 * @FilePath: /Code_Sync/Luogu/Training_743042/1_P1102_1.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n, c;
    if (!(cin >> n >> c)) return -1;
    vector<long long> number(n);
    map<int, long long> countMap;
    for (int i = 0; i < n; i++) {
        cin >> number[i];
        countMap[number[i]]++;
    }
    long long answer = 0;
    for (int i = 0; i < n; i++) answer += countMap[number[i] - c];
    cout << answer;
    return 0;
}