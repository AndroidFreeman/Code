/*
 * @Date: 2026-03-07 15:51:36
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 16:07:29
 * @FilePath: /Code_Sync/Luogu/Traning_107/5_P1093.cpp
 */
#include <bits/stdc++.h>
using namespace std;

struct Student{
    int chi,math,eng,id,total;
};
bool compare(Student &a,Student &b){
    if(a.total!=b.total) return a.total>b.total;
    if(a.chi!=b.chi) return a.chi>b.chi;
    return a.id<b.id;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int capacity;
    cin>>capacity;
    vector<Student> student(capacity);
    for(int i=0;i<capacity;i++){
        student[i].id=i+1;
        cin>>student[i].chi>>student[i].math>>student[i].eng;
        student[i].total=student[i].chi+student[i].math+student[i].eng;
    }
    sort(student.begin(),student.end(),compare);
    for(int i=0;i<5;i++){
        cout<<student[i].id<<" "<<student[i].total<<endl;
    }

    return 0;
}