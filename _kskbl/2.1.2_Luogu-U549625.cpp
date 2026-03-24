/*
 * @Date: 2026-03-24 11:24:41
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-24 12:31:21
 * @FilePath: /Code/_kskbl/2.1.2_Luogu-U549625.cpp
 */
#include <bits/stdc++.h>
using namespace std;
typedef long long ll;

int main() {
    ios::sync_with_stdio(0);
    cin.tie(0);

    int n;
    cin >> n;
    vector<ll> a(n + 1, 0);
    for (int i = 1; i <= n; i++) cin >> a[i];

    vector<ll> max_ending_at(n + 1);
    ll current_s = 0;
    ll min_s = 0;
    for (int i = 1; i <= n; i++) {
        current_s += a[i];
        max_ending_at[i] = current_s - min_s;
        min_s = min(min_s, current_s);
    }

    vector<ll> max_starting_at(n + 2, 0);
    ll current_suffix_s = 0;
    ll min_suffix_s = 0;
    for (int i = n; i >= 1; i--) {
        current_suffix_s += a[i];
        max_starting_at[i] = current_suffix_s - min_suffix_s;
        min_suffix_s = min(min_suffix_s, current_suffix_s);
    }

    for (int i = 1; i <= n; i++) {
        cout << max_ending_at[i] + max_starting_at[i] - a[i] << " ";
    }
}
