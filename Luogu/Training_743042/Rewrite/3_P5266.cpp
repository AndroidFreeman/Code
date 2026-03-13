/*
 * @Date: 2026-03-13 17:09:34
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-13 17:28:16
 * @FilePath: /Code_Sync/Luogu/Training_743042/Rewrite/3_P5266.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    map<string,int> student;
    int total;
    cin>>total;
    for(int i=0;i<total;i++){
        int op;
        cin>>op;
        string name;
        if(op==1){
            int score;
            cin>>name>>score;
            student[name]=score;
            cout<<"OK"<<endl;
        }
        if(op==2){
            cin>>name;
            if(student.count(name)){
                cout<<student[name]<<endl;
            }else {
                cout<<"Not found"<<endl;
            }
        }
        if(op==3){
            cin>>name;
            if(student.count(name)){
                student.erase(name);
                cout<<"Deleted successfully"<<endl;
            }else {
                cout<<"Not found"<<endl;
            }
        }
        if(op==4){
            cout<<student.size()<<endl;
        }
    }

    return 0;
}