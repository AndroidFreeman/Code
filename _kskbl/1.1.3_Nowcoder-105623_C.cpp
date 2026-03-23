/*
 * @Date: 2026-03-22 11:39:30
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-22 11:56:10
 * @FilePath: /Code/_kskbl/1.1.3 Nowcoder-105623_C.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int op;
    cin >> op;
    while (op--) {
        int total;
        cin >> total;
        vector<int> number(total, 0);
        vector<char> input(total, 0);
        for (int i = 0; i < total; i++) cin >> number[i];
        for (int i = 0; i < total; i++) cin >> input[i];

        int wrong = 0;
        for (int i = 0; i < total; i++) {
            if (input[i] == '<') {
                if (number[i] >= 0) wrong++;
                number[i]=-1;
            } else if (input[i] == '>') {
                if (number[i] <= 0) wrong++;
                number[i]=1;
            } else if (input[i] == 'Z') {
                if ((number[i - 1] * number[i]) <= 0) wrong++;
                number[i]=number[i-1];
            }
        }
        
        cout << wrong << endl;
    }
}