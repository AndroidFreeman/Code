/*
 * @Date: 2026-05-14 11:05:18
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-05-14 11:32:47
 * @FilePath: /Code/LearnDS_HBPU/_Rewrite/_kmp2.cpp
 */

#include <bits/stdc++.h>
using namespace std;

void getNextVal(vector<int>& nextval, const string& s) {
    int j = 0;
    nextval[0] = 0;
    for (int i = 1; i < s.size(); i++) {
        while (j > 0 && s[i] != s[j]) 
            j = nextval[j - 1];
        if (s[i] == s[j]) 
            j++;
        if (j > 0 && j < s.size() && s[i] == s[j])
            nextval[i] = nextval[j - 1];
        else
            nextval[i] = j;
    }
}
int strStr(string longer, string shorter) {
    if (shorter.size() == 0) 
        return 0;
    int j = 0;
    vector<int> nextval(shorter.size());
    getNextVal(nextval, shorter);
    for (int i = 0; i < longer.size(); i++) {
        while (j > 0 && longer[i] != shorter[j]) 
            j = nextval[j - 1];
        if (longer[i] == shorter[j]) 
            j++;
        if (j == shorter.size()) 
            return i - shorter.size() + 1;
    }
    return -1;
}
int main() {
    string s = "aaaab";
    vector<int> n(s.size());
    getNextVal(n, s);
    
    cout << "模式串: " << s << endl;
    cout << "NextVal: ";
    for (int x : n) cout << x << " "; 
    cout << endl;
    
    return 0;
}
