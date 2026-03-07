/*
 * @Date: 2026-03-07 16:35:06
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 16:47:59
 * @FilePath: /Code_Sync/Luogu/Traning_107/7_P2676.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int total,bookshelf,count=0;
    if(!(cin>>total>>bookshelf)) return -1;
    vector<int> cow(total);
    for(int i=0;i<total;i++){
        cin>>cow[i];
    }
    sort(cow.begin(),cow.end(),greater<int>());
    int answer=0;
    for(int i=0;i<total;i++){
        count+=cow[i];
        answer++;
        if(count>=bookshelf) break;
    }
    cout<<answer;

    return 0;
}