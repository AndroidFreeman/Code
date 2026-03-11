/*
 * @Date: 2026-03-11 22:35:57
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-11 23:00:37
 * @FilePath: /Code_Sync/Luogu/Training_743042/2_P1918.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    int total;
    cin >> total;
    unordered_map<long long, long long> bottleMap;
    vector<int> bottle(total);
    for (int i = 0; i < total; i++) {
        cin >> bottle[i];
        bottleMap[bottle[i]] = i + 1;
    }
    int chance;
    cin >> chance;
    vector<int> step(chance);
    for (int i = 0; i < chance; i++) cin >> step[i];
    for (int i = 0; i < chance; i++) cout << bottleMap[step[i]] << endl;
}