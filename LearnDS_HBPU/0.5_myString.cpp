/*
 * @Date: 2026-04-20 16:56:15
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-05-07 11:38:49
 * @FilePath: /Code/LearnDS_HBPU/0.5_myString.cpp
 */

#include <bits/stdc++.h>
using namespace std;
const int MaxLen = 255;
const int ChunkSize = 80;

struct myString {
    char ch[MaxLen + 1];
    int length;
};

int myStringCompare(myString tS1, myString tS2) {
    int minLen = (tS1.length < tS2.length) ? tS1.length : tS2.length;
    for (int i = 1; i <= minLen; i++)
        if (tS1.ch[i] != tS2.ch[i]) return tS1.ch[i] - tS2.ch[i];
    return tS1.length - tS2.length;
}

bool mySubString(myString& Sub, myString S, int Position, int Length) {
    if (Position < 1 || Position > S.length || Length < 0) return false;
    int realLen = Length;
    if (Position + Length - 1 > S.length) realLen = S.length - Position + 1;
    for (int i = 1; i <= realLen; i++) Sub.ch[i] = S.ch[Position + i - 1];
    Sub.length = realLen;
    Sub.ch[realLen + 1] = '\0';
    return true;
}

int myStringIndex(myString S, myString Sub, int Length) {
    if (Sub.length <= 0) return 0;
    myString tempS;
    for (int i = 1; i <= S.length - Sub.length + 1; i++) {
        mySubString(tempS, S, i, Sub.length);
        if (myStringCompare(tempS, Sub) == 0) return i;
    }
    return 0;
}

int Index_BF(myString S, myString T, int position){
    int i=position;
    int j=1;
    while(i<=S.length&&j<=T.length){
        if(S.ch[i]==T.ch[j]){
            i++;
            j++;
        }else{
            i=i-j+2;
            j=1;
        }
    }
    if(j>T.length) return i-T.length;
    else return 0;
}

// void KMP_Get_Next(myString T, int next[]){
//     int i=1,j=0;
//     next[1]=0;
//     while(i<T.length){
//         if(j==0||T.ch[i]==T.ch[j]){
//             i++;
//             j++;
//             next[i]=j;
//         }else{
//             j=next[j];
//         }
//     }
// }

void KMP_Get_Next_Val(myString T,int nextval[]){
    int i=1;
    int j=0;
    nextval[1]=0;
    while(i<T.length){
        if(j==0||T.ch[i]==T.ch[j]){
            i++;
            j++;
            if(T.ch[i]!=T.ch[j]){
                nextval[i]=j;
            }else{
                nextval[i]=nextval[j];
            }
        }else{
            j=nextval[j];
        }
    }
}

int Index_KMP(myString S,myString T,int position){
    if(position<1||position>S.length||T.length==0) return 0;
    int next[MaxLen+1];
    KMP_Get_Next_Val(T, next);
    int i=position;
    int j=1;
    while(i<=S.length&&j<=T.length){
        if(j==0||S.ch[i]==T.ch[j]){
            j++;
            i++;
        }else{
            j=next[j];
        }
    }
    if(j>T.length){
        return i-T.length;
    }else{
        return 0;
    }
}

int main() {}