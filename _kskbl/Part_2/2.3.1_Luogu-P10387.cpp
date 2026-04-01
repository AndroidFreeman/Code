/*
 * @Date: 2026-03-25 20:16:59
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 10:04:25
 * @FilePath: /Code/_kskbl/Part_2/2.3.1_Luogu-P10387.cpp
 */
#include<bits/stdc++.h>
using namespace std;

typedef long long ll;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    ll total, aoe;
    if (!(cin >> total >> aoe)) return 0;
    ll singleLevelupCoin = 0;
    vector<pair<ll, ll>> soldier(total);
    for (ll i = 0; i < total; i++) {
        ll coin, level;
        cin >> coin >> level;
        soldier[i].first = level;
        soldier[i].second = coin;
        singleLevelupCoin += coin; 
    }

    sort(soldier.begin(), soldier.end());

    ll answer = 0;
    ll aoeNumber = 0;

    for (ll i = 0; i < total; i++) {
        ll needLevel = soldier[i].first - aoeNumber;
        if (needLevel > 0) {
            if (singleLevelupCoin > aoe) {
                answer += (ll)needLevel * aoe;
                aoeNumber += needLevel;
            } else {
                answer += (ll)needLevel * singleLevelupCoin;
                aoeNumber += needLevel; 
            }
        }
        singleLevelupCoin -= soldier[i].second;
    }

    cout << answer << endl;
    return 0;
}
