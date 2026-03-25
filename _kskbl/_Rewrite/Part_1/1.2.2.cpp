/*
 * @Date: 2026-03-23 11:55:52
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-23 12:26:49
 * @FilePath: /Code/_kskbl/_Rewrite/1.2.2.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    long long mon1, mon2, aoe, gcd;
    cin >> mon1 >> mon2 >> aoe >> gcd;
    int answer = 0;
    int less = min(mon1, mon2);
    int more = max(mon1, mon2);
    if (aoe * 2 > gcd) {
        int times = (less+aoe-1)/aoe;
        answer += times;
        more = more - aoe * times;
    } else {
        answer += (mon1+aoe-1)/aoe + (mon2+gcd-1)/gcd;
    }
    if (more > 0) {
        if (aoe > gcd)
            answer += (more+aoe-1)/aoe;
        else
            answer += (more+gcd-1)/gcd;
    }
    cout << answer;
}