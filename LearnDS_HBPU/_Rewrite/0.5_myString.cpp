/*
 * @Date: 2026-04-20 18:18:29
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-27 17:23:57
 * @FilePath: /Code/LearnDS_HBPU/_Rewrite/0.5_myString.cpp
 */
#include<bits/stdc++.h>
using namespace std;

const int MaxLen=255;

struct myString{
    char ch[MaxLen+1];
    int length;
};

int myStringCompare(myString tS1, myString tS2){
    for(int i=1;i<=min(tS1.length,tS2.length);i++)
        if(tS1.ch[i]!=tS2.ch[i]) return tS1.ch[i]-tS2.ch[i];
    return tS1.length-tS2.length;
}

bool mySubString(myString& Sub, myString S,int Position,int Length){
    if(Position<1||Position>S.length||Length<0)return false;
    int realLen=Length;
    if(Position+Length-1>S.length) realLen=S.length-Position+1;
    Sub.length=realLen;
    Sub.ch[realLen+1]='\0';
    return true;
}

int myStringIndex(myString S,myString Sub,int Length){
    if(Sub.length<=0) return 0;
    myString tempS;
    for(int i=1;i<=S.length-Sub.length+1;i++){
        mySubString(tempS, S, i, Sub.length);
        if(myStringCompare(tempS, Sub)==0) return i;
    }
    return 0;
}

int main(){

}