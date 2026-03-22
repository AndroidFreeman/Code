/*
 * @Date: 2026-03-19 11:24:11
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-19 11:44:36
 * @FilePath: /Code/Luogu/Training_743042/6_B3612.cpp
 */
#include <bits/stdc++.h>
using namespace std;
const int MAXN=1e5+5;
long long s[MAXN];
int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);
    int n;
    if(!(cin>>n)) return 0;

    for(int i=1;i<=n;i++){
        int a;
        cin>>a;
        s[i]=s[i-1]+a;
    }

    int m;
    cin>>m;
    while(m--){
        int l,r;
        cin>>l>>r;
        cout<<s[r]-s[l-1]<<endl;
    }


















    //TLE
    // ios::sync_with_stdio(false);
    // cin.tie(0);
    // vector<int> number;
    // int total;
    // cin >> total;
    // number.resize(total + 1);
    // for (int i = 1; i <= total; i++) cin >> number[i];

    // int op;
    // cin >> op;
    // while (op--) {
    //     long long answer = 0;
    //     int index1, index2;
    //     cin >> index1 >> index2;
    //     for (int j = index1; j <= index2; j++) answer += number[j];
    //     cout << answer << endl;
    // }
}