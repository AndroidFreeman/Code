/*
 * @Date: 2026-03-07 17:13:06
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 21:49:29
 * @FilePath: /Code_Sync/Luogu/Traning_107/9_P1152.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int capacity;
    cin >> capacity;
    vector<long long> number(capacity);
    vector<long long> minus(capacity - 1);
    for (int i = 0; i < capacity; i++) {
        cin >> number[i];
    }
    for (int i = 0; i < capacity - 1; i++) {
        minus[i] = abs(number[i + 1] - number[i]);
    }
    sort(minus.begin(), minus.end());
    for (int i = 0; i < capacity - 1; i++) {
        if (i + 1 != minus[i]) {
            cout << "Not jolly";
            return 0;
        }
    }
    cout << "Jolly";
}