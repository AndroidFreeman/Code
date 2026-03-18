/*
 * @Date: 2026-03-18 10:47:17
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-18 11:20:16
 * @FilePath: /Code/Luogu/Training_743042/CPP_STL/Set/1_P1059.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    // first, let us know about set
    set<int> mySet;
    mySet.insert(10);
    mySet.insert(20);
    auto [ita, succuss] = mySet.insert(30);
    mySet.erase(ita);
    mySet.erase(10);
    for (int i = 1; i <= 10; i++) mySet.insert(i);
    auto xiaoyu5 = mySet.lower_bound(5);
    advance(xiaoyu5,-1);
    cout << *(xiaoyu5) << endl;
    for (int num : mySet) cout << num << ' ';
    cout << endl;

    if (mySet.find(20) != mySet.end())
        cout << "20 is here" << endl;
    else
        cout << "20 is not here" << endl;
    auto itt = mySet.find(10);
    mySet.erase(20);

    for (int num : mySet) cout << num << " ";
    cout << endl;
    cout << mySet.size() << endl;
    mySet.erase(mySet.begin(), mySet.end());
}