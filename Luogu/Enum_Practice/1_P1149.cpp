/*
 * @Date: 2026-03-10 21:25:57
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-10 21:53:29
 * @FilePath: /Code_Sync/Luogu/Enum_Practice/1_P1149.cpp
 */
#include <bits/stdc++.h>
using namespace std;

vector<int> numberStick = {6, 2, 5, 5, 4, 5, 6, 3, 7, 6};
int stick, answer;

int check(int x) {
    int sum = 0;
    if (x < 10)
        sum = numberStick[x];
    else {
        int temp = x;
        while (temp != 0) {
            sum += numberStick[temp % 10];
            temp /= 10;
        }
    }
    return sum;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    cin >> stick;
    for (int i = 0; i <= 1000; i++) {
        for (int j = 0; j <= 1000; j++) {
            if (check(i) + check(j) + check(i + j) == stick - 4) answer++;
        }
    }
    cout << answer;
}
