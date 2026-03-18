/*
 * @Date: 2026-03-18 11:29:57
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-18 12:26:07
 * @FilePath: /Code/Luogu/Training_743042/4_P5250.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main(){
    ios::sync_with_stdio(false);
    cin.tie(0);
    int total;
    if(!(cin>>total)) return -1;
    set<int> wood;

    while(total--){
        int op,len;
        cin>>op>>len;
        if(op==1){
            auto[it,success]=wood.insert(len);
            if(!success) cout<<"Already Exist"<<endl;
        }else{
            if(wood.empty()){
                cout<<"Empty"<<endl;
            }
        }
    }



}

















//TLE
/*
int main() {
    int operationNumber;
    ios::sync_with_stdio(false);
    cin.tie(0);
    if (!(cin >> operationNumber)) return 0;
    set<int> wood;
    for (int index = 1; index <= operationNumber; index++) {
        int operation, woodInput;
        if (!(cin >> operation >> woodInput)) break;
        if (operation == 1) {
            auto [location, inserted] = wood.insert(woodInput);
            if (!inserted) cout << "Already Exist" << endl;
        }

        if (operation == 2) {
            if (wood.empty()) {
                cout << "Empty" << endl;
            } else if (wood.count(woodInput)) {
                wood.erase(woodInput);
                cout << woodInput << endl;
            } else {
                int woodBegin = *wood.begin();
                int woodEnd = *wood.rbegin();
                int maxNumber = -1, minNumber = -1;
                for (int i = woodInput; i <= woodEnd; i++) {
                    if (wood.count(i)) {
                        maxNumber = i;
                        break;
                    }
                }
                for (int i = woodInput; i >= woodBegin; i--) {
                    if (wood.count(i)) {
                        minNumber = i;
                        break;
                    }
                }
                if (minNumber == -1) {
                    cout << maxNumber << endl;
                    wood.erase(maxNumber);
                } else if (maxNumber == -1) {
                    cout << minNumber << endl;
                    wood.erase(minNumber);
                } else {
                    if (abs(woodInput - minNumber) <=
                        abs(woodInput - maxNumber)) {
                        cout << minNumber << endl;
                        wood.erase(minNumber);
                    } else {
                        cout << maxNumber << endl;
                        wood.erase(maxNumber);
                    }
                }
            }
        }
    }
    return 0;
}
*/