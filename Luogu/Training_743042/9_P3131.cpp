/*
 * @Date: 2026-03-19 12:00:58
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-19 12:23:46
 * @FilePath: /Code/Luogu/Training_743042/9_P3131.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int n;
    cin>>n;

    vector<int> first_pos(7,-1);
    first_pos[0]=0;
    long long current_sum=0;
    int max_len=0;

    for(int i=1;i<=n;i++){
        int id;
        cin>>id;
        current_sum+=id;
        int rem=current_sum%7;
    }
















    // ios::sync_with_stdio(false);
    // cin.tie(0);
    // int n;
    // if (!(cin >> n)) return 0;
    // vector<int> cow(n);
    // for (int i = 0; i < n; i++) {
    //     cin >> cow[i];
    // }
    // int max_length = 0;
    // for (int i = 0; i < n; i++) {
    //     long long current_sum = 0;
    //     for (int j = i; j < n; j++) {
    //         current_sum += cow[j];
    //         if (current_sum % 7 == 0) {
    //             int current_length = j - i + 1;
    //             if (current_length > max_length) {
    //                 max_length = current_length;
    //             }
    //         }
    //     }
    // }
    // cout << max_length << endl;
    // return 0;
}
