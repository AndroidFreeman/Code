/*
 * @Date: 2026-03-19 11:50:58
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-19 11:58:22
 * @FilePath: /Code/Luogu/Training_743042/Rewrite/6_B3612.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int length;
    cin >> length;
    vector<int> number(length + 1, 0);
    for (int i = 1; i <= length; i++) {
        int temp;
        cin >> temp;
        number[i] = number[i - 1] + temp;
    }
    int op;
    cin >> op;
    while (op--) {
        int forward, last;
        cin >> forward >> last;
        cout << number[last] - number[forward - 1] << endl;
    }
}