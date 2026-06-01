/*
 * @Date: 2026-05-11 17:06:32
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-05-14 10:47:38
 * @FilePath: /Code/LearnDS_HBPU/_Rewrite/_kmp.cpp
 */


#include <bits/stdc++.h>
using namespace std;

void getNext(vector<int>& next, const string& s) {
    int j = 0;
    next[0] = 0;
    for (int i = 1; i < s.size(); i++) {
        while (j > 0 && s[i] != s[j]) j = next[j - 1];
        if (s[i] == s[j]) j++;
        next[i] = j;
    }
}

void getNextVal(vector<int>& nextval, const string& s) {
    int j = 0;
    nextval[0] = 0;
    for (int i = 1; i < s.size(); i++) {
        while (j > 0 && s[i] != s[j]) j = nextval[j - 1];
        if (s[i] == s[j]) j++;
        // nextval[i] = j;

        if (j > 0 && s[i] == s[j]) nextval[i]=nextval[j-1];
        else nextval[i]=j;
    }
}

int strStr(string haystack, string needle) {
    if (needle.size() == 0) return 0;
    vector<int> next(needle.size());
    getNext(next, needle);
    int j = 0;
    for (int i = 0; i < haystack.size(); i++) {
        while (j > 0 && haystack[i] != needle[j]) j = next[j - 1];
        if (haystack[i] == needle[j]) j++;
        if (j == needle.size()) return (i - needle.size() + 1);
    }
    return -1;
}

int main() {}