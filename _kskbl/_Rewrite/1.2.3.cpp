/*
 * @Date: 2026-03-24 10:21:09
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-24 11:05:29
 * @FilePath: /Code/_kskbl/_Rewrite/1.2.3.cpp
 */
#include <bits/stdc++.h>
using namespace std;
typedef long long ll;

int main() {
    ll n, aoe_price;
    cin >> n >> aoe_price;
    vector<pair<ll, ll>> soldiers(n);
    ll current_total_price = 0;

    for (int i = 0; i < n; i++) {
        ll p, c;
        cin >> p >> c;
        soldiers[i] = {c, p};
        current_total_price += p;
    }

    sort(soldiers.begin(), soldiers.end());

    ll answer = 0;
    ll already_trained = 0;
    for (int i = 0; i < n; i++) {
        ll gap = soldiers[i].first - already_trained;
        if (gap > 0) {
            if (current_total_price > aoe_price) {
                answer += gap * aoe_price;
                already_trained += gap;
            } else {
                answer += gap * soldiers[i].second;
            }
        }
        current_total_price -= soldiers[i].second;
    }
    
    cout << answer << endl;
}