/*
 * @Date: 2026-03-11 17:42:15
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-11 21:24:15
 * @FilePath: /Code_Sync/Luogu/Training_743042/1_P1102.cpp
 */

// --- 75 ---

// #include <bits/stdc++.h>
// using namespace std;

// int main() {
//     ios::sync_with_stdio(false);
//     cin.tie(nullptr);

//     int n,c;
//     int answer=0;
//     if(!(cin>>n>>c)) return -1;
//     vector<int> number(n);
//     for(int i=0;i<n;i++) cin>>number[i];
//     for(int i=n-1;i>=0;i--){
//         for(int j=0;j<n;j++){
//             if((number[i]-number[j]==c)&&(i!=j)) answer++;
//         }
//     }
//     cout<<answer;
//     return 0;
// }

// --- 100 ---
#include <bits/stdc++.h>
using namespace std;
typedef long long ll;
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n, c;
    if (!(cin >> n >> c)) return -1;
    vector<int> number(n);
    unordered_map<int, ll> countMap;
    for (int i = 0; i < n; i++) {
        cin >> number[i];
        countMap[number[i]]++;
    }

    ll answer = 0;
    for (int i = 0; i < n; i++) answer += countMap[number[i] - c];
    cout << answer;
    return 0;
}