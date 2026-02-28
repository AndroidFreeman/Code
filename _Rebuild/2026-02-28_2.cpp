/*
 * @Date: 2026-02-28 17:03:42
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 17:26:16
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_2.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int n;
    cin >> n;
    vector<pair<int, int>> a;
    for (int i = 0; i < n; i++) {
        int id, score;
        cin >> id >> score;
        if (score > 0) {
            a.push_back({score, id});
        }
    }
    sort(a.begin(), a.end());
    a.erase(unique(a.begin(), a.end()), a.end());

    for (int i = 0; i < a.size(); i++) {
        cout << i + 1 << " " << a[i].second << " " << a[i].first << endl;
    }
}
