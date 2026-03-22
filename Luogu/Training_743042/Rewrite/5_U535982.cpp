/*
 * @Date: 2026-03-19 11:16:20
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-19 11:20:58
 * @FilePath: /Code/Luogu/Training_743042/Rewrite/5_U535982.cpp
 */
#include<bits/stdc++.h>
using namespace std;
int main(){
    ios::sync_with_stdio(false);
    cin.tie(0);

    int op;
    cin>>op;
    while(op--){
        int number;
        string input;
        cin>>number>>input;
        int answer1=0,answer2=0;
        for(int i=0;i<number*2;i++){
            if(i%2==0){
                if(input[i]!='A') answer1++;
            }else{
                if(input[i]!='B') answer1++;
            }
            if(i%2==0){
                if(input[i]!='B') answer2++;
            }else{
                if(input[i]!='A') answer2++;
            }
        }
        cout<<min(answer1,answer2)/2<<endl;
    }
}