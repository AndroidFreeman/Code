/*
 * @Date: 2026-03-07 15:40:05
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 15:50:47
 * @FilePath: /Code_Sync/Luogu/Traning_107/4_P1059.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int total;
    if (!(cin >> total)) return 0;
    vector<int> number(total);
    for(int i=0;i<total;i++){
        cin>>number[i];
    }
    sort(number.begin(),number.end());
    number.erase(unique(number.begin(),number.end()),number.end());
    cout<<number.size()<<endl;
    for(int i:number){
        cout<<i<<" ";
    }

    return 0;
}