/*
 * @Date: 2026-03-07 14:59:38
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 15:13:30
 * @FilePath: /Code_Sync/Luogu/Traning_107/1_P1271.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int people,choose,temp;
    if(!(cin>>people>>choose)) return -1;
    vector<int> input(choose);
    for(int i=0;i<choose;i++){
        cin>>temp;
        input[i]=temp;
    }
    sort(input.begin(),input.end());
    for(int i:input){
        cout<<i<<" ";
    }
    return 0;
}