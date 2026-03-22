/*
 * @Date: 2026-03-19 02:46:24
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-19 03:07:55
 * @FilePath: /Code/Luogu/Training_743042/Rewrite/4_P5250_2.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    int total;
    cin >> total;
    set<int> woodSet;
    while (total--) {
        int op, wood;
        cin >> op >> wood;
        if (op == 1) {
            auto [it, success] = woodSet.insert(wood);
            if (!success) cout << "Already Exist" << endl;
        }
        if (op == 2) {
            if (woodSet.empty()) {
                cout << "Empty" << endl;
            } else {
                auto it=woodSet.lower_bound(wood);
                if(it!=woodSet.end()&&*it==wood) {
                    cout<<*it<<endl;
                    woodSet.erase(it);
                }else {
                    if(it==woodSet.begin()){
                        cout<<*it<<endl;
                        woodSet.erase(it);
                    }else if (it==woodSet.end()) {
                        cout<<*prev(it)<<endl;
                        woodSet.erase(prev(it));
                    }else{
                        auto left=prev(it);
                        auto right=it;
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