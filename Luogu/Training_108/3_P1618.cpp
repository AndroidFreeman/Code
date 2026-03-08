/*
 * @Date: 2026-03-08 17:22:45
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-08 17:38:52
 * @FilePath: /Code_Sync/Luogu/Training_108/3_P1618.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int a1, a2, a3;
    if (!(cin >> a1 >> a2 >> a3)) return 0;
    if (a1 == 0 || a2 == 0 || a3 == 0) {
        cout << "No!!!" << endl;
        return 0;
    }
    int answer = 0;
    vector<int> bukket(10, 0);

    for (int i = 123 / a1; i <= 987 / a3; i++) {
        fill(bukket.begin(), bukket.end(), 0);
        bool yes = true;
        int b1 = i * a1, b2 = i * a2, b3 = i * a3;
        if (b3 > 999) break;
        int t1 = b1, t2 = b2, t3 = b3;
        for (int j = 0; j < 3; j++) {
            bukket[t1 % 10]++;
            t1 /= 10;
            bukket[t2 % 10]++;
            t2 /= 10;
            bukket[t3 % 10]++;
            t3 /= 10;
        }
        if (bukket[0] != 0)
            yes = false;
        else {
            for (int k = 1; k <= 9; k++) {
                if (bukket[k] != 1) {
                    yes = false;
                    break;
                }
            }
        }
        if (yes) {
            cout << b1 << " " << b2 << " " << b3 << endl;
            answer++;
        }
    }

    if (answer == 0) cout << "No!!!" << endl;

    return 0;
}