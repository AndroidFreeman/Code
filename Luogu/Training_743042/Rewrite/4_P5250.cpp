/*
 * @Date: 2026-03-19 02:14:15
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-19 02:36:33
 * @FilePath: /Code/Luogu/Training_743042/Rewrite/4_P5250.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);
    int total;
    cin >> total;
    set<int> woodSet;
    while (total--) {
        int op, wood;
        cin >> op >> wood;
        if (op == 1) {
            auto [it, success] = woodSet.insert(wood);
            if (!success) cout << "Already Exist" << "\n";
        }
        if (op == 2) {
            if (woodSet.empty()) {
                cout << "Empty";
                continue;
            } else {
                auto it = woodSet.lower_bound(wood);
                if (it != woodSet.end() && *it == wood) {
                    cout << *it << endl;
                    woodSet.erase(it);
                } else {
                    if (it == woodSet.begin()) {
                        cout<<*woodSet.begin()<<endl;
                        woodSet.erase(woodSet.begin());
                    }else if(it==woodSet.end()){
                        cout<<*prev(it)<<endl;
                        woodSet.erase(prev(it));
                    }else{
                        auto right=it;
                        auto left=prev(it);
                        if(wood-*left<=*right-wood){
                            cout<<*left<<endl;
                            woodSet.erase(left);
                        }else{
                            cout<<*right<<endl;
                            woodSet.erase(right);
                        }
                    }
                }
            }
        }
    }
}