/*
 * @Date: 2026-03-18 11:24:49
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-18 11:28:43
 * @FilePath: /Code/Luogu/Training_743042/CPP_STL/Set/1_P1059.cpp
 */
#include<bits/stdc++.h>
using namespace std;
int main(){
    set<int> student;
    int total;
    cin>>total;
    for(int i=0;i<total;i++){
        int score;
        cin>>score;
        student.insert(score);
    }
    cout<<student.size()<<endl;
    for(int i:student) cout<<i<<" ";
}