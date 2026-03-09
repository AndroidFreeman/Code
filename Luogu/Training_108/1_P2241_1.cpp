/*
 * @Date: 2026-03-09 11:24:26
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 12:57:07
 * @FilePath: /Code_Sync/Luogu/Training_108/1_P2241_1.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long n,m;
    cin>>n>>m;
    long long sq=0,rect=0;
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            if(i==j){
                sq+=(n-i-1)*(m-j-1);
            }else{
                rect+=(n-i-1)*(m-j+1);
            }
        }
    }
    cout<<sq<<' '<<rect;

    return 0;
}