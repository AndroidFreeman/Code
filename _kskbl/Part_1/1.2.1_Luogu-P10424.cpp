/*
 * @Date: 2026-03-22 11:59:44
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-22 12:20:03
 * @FilePath: /Code/_kskbl/1.2.1 Luogu-P10424.cpp
 */
#include <bits/stdc++.h>
using namespace std;

bool isGood(int number){
    int position=1;
    while(number>0){
        int now=number%10;
        if(position%2==0){
            if(now%2==1) return false;
        }else{
            if(now%2==0) return false;
        }
        number=number/10;
        position++;
    }
    return true;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int N;
    cin >> N;

    int answer = 0;
    for (int i = 1; i <= N; i++) {
        if (isGood(i)) {
            answer++;
        }
    }

    cout << answer << endl;
    return 0;
}
