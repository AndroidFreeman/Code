/*
 * @Date: 2026-02-28 19:26:28
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 21:16:08
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_5.cpp
 */

// CPP STL Learn
// stack

#include <bits/stdc++.h>

#include <functional>
#include <iostream>
#include <queue>
#include <vector>
using namespace std;
int main() {
    // first in last out
    stack<int> stk;
    stk.push(1);

    stk.push(2);
    stk.pop();
    int a = stk.top();
    cout << a << endl;

    // first in first out
    queue<int> qu;
    qu.push(1);
    qu.push(2);
    qu.push(3);
    qu.pop();
    int aa = qu.front();
    cout << aa << endl;
    aa = qu.back();
    cout << aa << endl;

    // priority_queue
    priority_queue<int> pque1;
    priority_queue<int, vector<int>, greater<int>> pque2;

    pque1.push(1);
    pque1.push(2);
    pque1.push(3);
    pque1.push(4);
    pque1.pop();
    cout << pque1.top() << endl;

    // set
    set<int> st1;
    set<int, greater<int>> st2;

    st1.insert(11);
    st1.insert(12);
    st1.insert(13);
    st1.insert(14);
    for (auto ele : st1) {
        cout << ele << endl;
    }

    // map
    map<int, int> mp1;
    map<int, int, greater<int>> mp2;

    mp1[1] = 2;
    auto iti = mp1.find(2);
    mp1.erase(2);
    mp1[1] = 2;
    for (auto pr : mp1) {
        cout << pr.first << ' ' << pr.second << endl;
    }

    // string
    string s1;
    string s2 = "Whoa!";
    string s3(3, 'F');

    // iterator
}