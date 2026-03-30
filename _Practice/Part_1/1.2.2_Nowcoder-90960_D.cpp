/*
 * @Date: 2026-03-22 12:21:47
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-22 21:42:07
 * @FilePath: /Code_Sync/_kskbl/1.2.2_Nowcoder-90960_D.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    double a, b, x, y;
    if (!(cin >> a >> b >> x >> y)) return 0;

    int planA = ceil(a / x) + ceil(b / x);

    double low = min(a, b);
    double high = max(a, b);

    int aoe_times = ceil(low / y);
    double rem_high = max(0.0, high - aoe_times * y);
    int planB = aoe_times + ceil(rem_high / x);
    int planC = ceil(max(a, b) / y);
    cout << min({planA, planB, planC}) << endl;

    return 0;
}