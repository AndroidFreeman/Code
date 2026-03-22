/*
 * @Date: 2026-03-22 10:59:07
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-22 11:15:50
 * @FilePath: /Code/_kskbl/1.1.1 Nowcoder-103948_B.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int total;
    cin >> total;
    vector<long long> number(total, 0);
    for (int i = 0; i < total; i++) cin >> number[i];
    long long x = 0;

    sort(number.begin(), number.end());
    for (int i = 0; i < total; i++) {
        if (i % 2 == 0) {
            x += number[i];
        } else {
            x -= number[i];
        }
    }
    cout << x << endl;
}