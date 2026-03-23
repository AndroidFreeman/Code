/*
 * @Date: 2026-03-23 14:44:37
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-23 15:33:28
 * @FilePath: /Code_Sync/_kskbl/1.2.3_Luogu-P10387.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long answer = 0;
    long long soldierTotal, coinAoe;
    cin >> soldierTotal >> coinAoe;

    vector<pair<long long, long long>> soldier(soldierTotal);
    // chance,coin
    long long coinTotal = 0;

    for (int i = 0; i < soldierTotal; i++) {
        long long p, c;
        cin >> p >> c;
        // coin,chance
        soldier[i].first = c;
        soldier[i].second = p;
        coinTotal += p;
    }

    sort(soldier.begin(), soldier.end());
    long long alreadyTrained = 0;

    for (int i = 0; i < soldierTotal; i++) {
        long long needs = soldier[i].first - alreadyTrained;
        if (needs > 0) {
            if (coinTotal > coinAoe) {
                answer += needs * coinAoe;
                alreadyTrained += needs;
            } else {
                answer += needs * soldier[i].second;
            }
        }
        coinTotal -= soldier[i].second;
    }

    cout << answer << endl;
    return 0;
}