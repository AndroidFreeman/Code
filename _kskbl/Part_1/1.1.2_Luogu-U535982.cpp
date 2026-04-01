/*
 * @Date: 2026-03-22 11:17:13
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-22 11:36:56
 * @FilePath: /Code/_kskbl/1.1.2 Luogu-U535982.cpp
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
        total = total * 2;
        string input;
        cin >> input;

        int diff1 = 0;
        int diff2 = 0;

        for (int i = 0; i < total; i++) {
            if(i%2==0){
                if(input[i]!='A') diff1++;
            }else{
                if(input[i]!='B') diff1++;
            }

            if(i%2==0){
                if(input[i]!='B') diff2++;
            }else{
                if(input[i]!='A') diff2++;
            }
        }

        cout << min(diff1, diff2) / 2 << endl;
    }
}