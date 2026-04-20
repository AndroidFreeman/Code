/*
 * @Date: 2026-04-20 16:56:15
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-20 18:11:35
 * @FilePath: /Code/LearnDS_HBPU/0.5_myString.cpp
 */
#include <bits/stdc++.h>
using namespace std;
const int MaxLen = 255;
const int ChunkSize = 80;

// struct Chunk{
//     char ch[ChunkSize];
//     struct Chunk* next;
// };

// struct myStringL{
//     Chunk *head, *tail;
//     int length;
// };

// struct myStringH{
//     char *ch;
//     int length;
// };

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

int main() {}