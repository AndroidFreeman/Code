/*
 * @Date: 2026-03-09 22:58:02
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 23:19:45
 * @FilePath: /Code_Sync/Luogu/Lanqiao_2022B/3_P8782.cpp
 */
#include <iostream>
#include <algorithm>
#include <vector>

using namespace std;

const int MOD = 1e9 + 7;

int main() {
    int n, ma, mb;
    cin >> n;

    cin >> ma;
    vector<int> a(ma);
    for (int i = ma - 1; i >= 0; i--) cin >> a[i];

    cin >> mb;
    vector<int> b(mb);
    for (int i = mb - 1; i >= 0; i--) cin >> b[i];

    long long ans = 0;
    int max_len = max(ma, mb);

    for (int i = max_len - 1; i >= 0; i--) {
        int cur_a = (i < ma) ? a[i] : 0;
        int cur_b = (i < mb) ? b[i] : 0;
        
        int base = max({2, cur_a + 1, cur_b + 1});
        
        ans = (ans * base + cur_a - cur_b + MOD) % MOD;
    }

    cout << ans << endl;
    return 0;
}