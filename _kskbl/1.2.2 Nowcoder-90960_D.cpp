/*
 * @Date: 2026-03-22 12:21:47
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-22 12:25:59
 * @FilePath: /Code/_kskbl/1.2.2 Nowcoder-90960_D.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int a = 0, b = 0, x = 0, y = 0;
    cin >> a >> b >> x >> y;
    int step = 0;

    if (x > y) {
        int temp = max(a, b);
        int temp1;
        if (temp % x != 0) temp1 = 1;
        cout <<temp/x+temp1<<endl;
    }
}