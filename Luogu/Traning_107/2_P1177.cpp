/*
 * @Date: 2026-03-07 15:21:54
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 15:22:58
 * @FilePath: /Code_Sync/Luogu/Traning_107/2_P1177.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int number;
    cin >> number;
    vector<int> process(number, 0);
    for (int i = 0; i < number; i++) {
        cin >> process[i];
    }
    sort(process.begin(), process.end());
    for (int i : process) {
        cout << i << " ";
    }

    return 0;
}