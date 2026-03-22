/*
 * @Date: 2026-03-19 03:10:03
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-19 11:12:32
 * @FilePath: /Code/Luogu/Training_743042/5_U535982.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int total;
    if (!(cin >> total)) return 0;
    
    while (total--) {
        int n;
        string s;
        cin >> n >> s;

        int diff1 = 0;
        int diff2 = 0;
        int len = 2 * n;

        for (int i = 0; i < len; i++) {
            if (i % 2 == 0) {
                if (s[i] != 'A') diff1++;
            } else {
                if (s[i] != 'B') diff1++;
            }
            
            if (i % 2 == 0) {
                if (s[i] != 'B') diff2++;
            } else {
                if (s[i] != 'A') diff2++;
            }
        }

        int ans = min(diff1, diff2);
        cout << ans / 2 << endl;
    }
}
