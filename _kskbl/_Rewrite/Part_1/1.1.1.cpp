/*
 * @Date: 2026-03-23 11:10:51
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-23 11:15:00
 * @FilePath: /Code/_kskbl/_Rewrite/1.1.1.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    int total;
    long long answer = 0;
    cin >> total;
    vector<int> number(total, 0);
    for (int i = 0; i < total; i++) cin >> number[i];
    sort(number.begin(), number.end());
    for (int i = 0; i < total; i++) {
        if (i % 2 == 0)
            answer += number[i];
        else
            answer -= number[i];
    }
    cout << answer << endl;
}