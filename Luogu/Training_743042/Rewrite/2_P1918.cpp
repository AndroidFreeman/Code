/*
 * @Date: 2026-03-13 17:03:34
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-13 17:07:52
 * @FilePath: /Code_Sync/Luogu/Training_743042/Rewrite/2_P1918.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int total;
    cin>>total;
    vector<int> bottle(total);
    unordered_map<long long,long long> bottleMap;
    for(int i=0;i<total;i++) {
        cin>>bottle[i];
        bottleMap[bottle[i]]=i+1;
    }
    int times;
    cin>>times;
    vector<int> shoot(times);
    for(int i=0;i<times;i++) cin>>shoot[i];
    for(int i=0;i<times;i++){
        cout<<bottleMap[shoot[i]]<<endl;
    }
    
    


    return 0;
}