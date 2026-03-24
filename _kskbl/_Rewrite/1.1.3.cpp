/*
 * @Date: 2026-03-23 11:26:45
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-23 11:33:18
 * @FilePath: /Code/_kskbl/_Rewrite/1.1.3.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    int steps;
    cin >> steps;
    while (steps--) {
        int total;
        cin >> total;
        vector<long long> number(total, 0);
        string chara;
        for (int i = 0; i < total; i++) cin >> number[i];
        cin >> chara;
        long long answer = 0;

        for (int i = 0; i < total; i++) {
            if (chara[i] == '<') {
                if (number[i] >= 0) answer++;
                number[i] = -1;
            } else if (chara[i] == '>') {
                if (number[i] <= 0) answer++;
                number[i] = 1;
            } else if (chara[i] == 'Z') {
                if (number[i] * number[i - 1] <= 0) answer++;
                number[i] = number[i - 1];
            }
        }
        cout << answer << "\n";
    }
}