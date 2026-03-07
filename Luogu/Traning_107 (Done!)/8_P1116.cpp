/*
 * @Date: 2026-03-07 16:50:12
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 17:11:03
 * @FilePath: /Code_Sync/Luogu/Traning_107/8_P1116.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int total, step = 0;
    if (!(cin >> total)) return -1;
    vector<int> train(total);
    for (int i = 0; i < total; i++) {
        cin >> train[i];
    }
    for (int i = 0; i < total - 1; i++) {
        for (int j = 0; j < total - 1 - i; j++) {
            if (train[j] > train[j + 1]) {
                step++;
                swap(train[j], train[j + 1]);
            }
        }
    }
    cout << step;
    return 0;
}