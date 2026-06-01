/*
 * @Date: 2026-05-14 10:32:00
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-05-14 10:59:23
 * @FilePath: /Code/LearnDS_HBPU/_Rewrite/_kmp1.cpp
 */

#include <bits/stdc++.h>
using namespace std;

void getNext(vector<int>& next, const string& s) {
    int j = 0;
    next[0] = 0;
    for (int i = 1; i < s.size(); i++) {
        while (j > 0 && s[i] != s[j]) 
            j = next[j - 1];
        if (s[i] == s[j]) 
            j++;
        if (j > 0 && s[i] == s[j])
            next[i] = next[j - 1];
        else
            next[i] = j;
    }
}

int strStr(string longer,string shorter){
    if(shorter.size()==0) return 0;
    vector<int> next(shorter.size());
    getNext(next, shorter);
    int j=0;
    for(int i=0;i<longer.size();i++){
        while(j>0&&longer[i]!=shorter[j])
            j=next[j-1];
        if(longer[i]==shorter[j])
            j++;
        if(j==shorter.size())
            return (i-shorter.size()+1);
    }
    return -1;
}


int main() {}