/*
 * @Date: 2026-03-23 11:16:47
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-23 11:24:59
 * @FilePath: /Code/_kskbl/_Rewrite/1.1.2.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    int steps;
    cin >> steps;
    while (steps--) {
        long long answer1 = 0, answer2 = 0;
        int total;
        cin >> total;
        string input;
        cin >> input;
        for (int i = 0; i < total * 2; i++) {
            if (i % 2 == 0) {
                if (input[i] != 'A') answer1++;
                if (input[i] != 'B') answer2++;
            } else {
                if (input[i] != 'A') answer2++;
                if (input[i] != 'B') answer1++;
            }
        }
        cout << min(answer1, answer2) / 2 << endl;
    }
}