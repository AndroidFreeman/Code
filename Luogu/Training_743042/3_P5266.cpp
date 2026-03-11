/*
 * @Date: 2026-03-11 23:03:50
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-11 23:14:36
 * @FilePath: /Code_Sync/Luogu/Training_743042/3_P5266.cpp
 */
#include <bits/stdc++.h>
using namespace std;
struct Student{
    int id=0,score=0;
    string name;
};
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int total;
    cin>>total;
    map<string,long long> student;
    while(total--){
        int op;
        cin>>op;
        string name;
        long long score;
        if(op==1){
            cin>>name>>score;
            student[name]=score;
            cout<<"OK"<<endl;
        }else if (op==2) {
            cin>>name;
            if(student.count(name)) cout<<student[name]<<endl;
            else cout<<"Not found"<<endl;
        }else if (op==3) {
            cin>>name;
            if(student.erase(name)) cout<<"Deleted successfully"<<endl;
            else cout<<"Not found"<<endl;
        }
        else if (op==4) {
            cout<<student.size()<<endl;
        }
    }


    return 0;
}