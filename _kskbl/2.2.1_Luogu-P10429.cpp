/*
 * @Date: 2026-03-25 18:34:46
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-25 19:58:53
 * @FilePath: /Code/_kskbl/2.2.1_Luogu-P10429.cpp
 */

#include <bits/stdc++.h>
using namespace std;

typedef long long ll;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    ll total;
    if (!(cin >> total)) return 0;
    vector<ll> number(total + 1);
    for (ll i = 1; i <= total; i++) cin >> number[i];
    ll answer = 2e18;
    set<ll> right;

    for (ll i = total - 1; i >= 1; i--) {
        ll rightTotal = 0;
        for (ll j = i + 1; j <= total; j++) {
            rightTotal += number[j];
            right.insert(rightTotal);
        }

        ll leftTotal = 0;
        for (ll j = i; j >= 1; j--) {
            leftTotal += number[j];

            auto it = right.lower_bound(leftTotal);

            if (it != right.end()) 
                answer = min(answer, *it - leftTotal);

            if (it != right.begin())
                answer = min(answer, leftTotal - *prev(it));
        }
    }
    cout << answer << endl;
    return 0;
}
