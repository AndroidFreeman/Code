/*
 * @Date: 2026-03-09 22:24:59
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 22:38:52
 * @FilePath: /Code_Sync/Luogu/Lanqiao_2022B/1_P8780.cpp
 */
#include <bits/stdc++.h>
using namespace std;

typedef long long ll;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    ll a, b, n;
    if (!(cin >> a >> b >> n)) return 0;
    ll week_sum = 5 * a + 2 * b;
    ll full_weeks = n / week_sum;
    ll day = full_weeks * 7;
    ll remaining_n = n % week_sum;
    if (remaining_n == 0) {
        cout << day << endl;
        return 0;
    }
    for (int i = 1; i <= 7; i++) {
        if (i <= 5) {
            remaining_n -= a;
        } else {
            remaining_n -= b;
        }
        day++;
        if (remaining_n <= 0) {
            cout << day << endl;
            break;
        }
    }
    return 0;
}