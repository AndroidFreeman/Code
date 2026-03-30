/*
 * @Date: 2026-03-23 11:34:49
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-23 11:54:46
 * @FilePath: /Code/_kskbl/_Rewrite/1.2.1.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int input;
    cin >> input;
    long long answer = 0;

    for (long long i = 1; i <= input; i++) {
        int number = i;
        bool flag = true;
        bool isGood = true;
        while (number > 0) {
            int now = number % 10;
            if (flag == true) {
                if (now % 2 == 0) isGood = false;
            } else {
                if (now % 2 == 1) isGood = false;
            }
            if (!isGood) break;
            flag = !flag;
            number = number / 10;
        }
        if (isGood) answer++;
    }
    cout << answer;
}
