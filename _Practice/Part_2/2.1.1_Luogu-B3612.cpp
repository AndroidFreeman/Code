/*
 * @Date: 2026-03-24 11:07:27
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-24 11:23:08
 * @FilePath: /Code/_kskbl/2.1.1_Luogu-B3612.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    typedef long long ll;
    int total;
    cin >> total;
    vector<ll> number(total + 1, 0);
    for (int i = 1; i <= total; i++) {
        int input;
        cin >> input;
        number[i] = number[i - 1] + input;
    }
    int op;
    cin >> op;
    while (op--) {
        int first, second;
        cin >> first >> second;
        cout << number[second] - number[first - 1] << endl;
    }
}