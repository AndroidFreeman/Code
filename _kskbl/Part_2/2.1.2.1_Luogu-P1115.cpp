/*
 * @Date: 2026-03-24 11:53:48
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-24 12:07:49
 * @FilePath: /Code/_kskbl/2.1.2.1_Luogu-P1115.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    typedef long long ll;
    ll total, answer = -2e18, min_s = 0;
    cin >> total;
    vector<ll> number(total + 1, 0);
    for (ll i = 1; i <= total; i++) {
        ll temp;
        cin >> temp;
        number[i] = number[i - 1] + temp;
        answer = max(answer, number[i] - min_s);
        min_s = min(min_s, number[i]);
    }
    cout << answer << endl;
}