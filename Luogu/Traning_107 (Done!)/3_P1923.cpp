/*
 * @Date: 2026-03-07 15:25:43
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 15:33:04
 * @FilePath: /Code_Sync/Luogu/Traning_107/3_P1923.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    // int total,choose;
    // if(!(cin>>total>>choose)) return -1;
    // vector<int> number(total);
    // for(int i=0;i<total;i++){
    //     cin>>number[i];
    // }
    // sort(number.begin(),number.end());
    // cout<<number[choose];

    int n, k;
    if (!(cin >> n >> k)) return 0;
    vector<int> a(n);
    for (int i = 0; i < n; ++i) {
        cin >> a[i];
    }
    nth_element(a.begin(), a.begin() + k, a.end());
    cout << a[k] << endl;

    return 0;
}