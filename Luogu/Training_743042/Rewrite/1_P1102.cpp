/*
 * @Date: 2026-03-13 16:56:59
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-13 17:01:41
 * @FilePath: /Code_Sync/Luogu/Training_743042/Rewrite/1_P1102.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n,c;
    if(!(cin>>n>>c)) return -1;
    vector<int > input(n);
    unordered_map<long long,long long> number;
    long long answer=0;
    for(int i=0;i<n;i++) {
        cin>>input[i];
        number[input[i]]++;
    }
    for(int i=0;i<n;i++){
        answer+=number[input[i]-c];
    }
    
    cout<<answer;

    return 0;
}