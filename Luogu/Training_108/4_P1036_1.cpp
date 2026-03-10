/*
 * @Date: 2026-03-09 20:50:46
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 21:03:57
 * @FilePath: /Code_Sync/Luogu/Training_108/4_P1036_1.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int n,k,answer=0;
vector<int> number;
vector<int> choose;
bool prime(int x){
    if(x==1||x!=2&&x%2==0) return false;
    for(int i=3;i*i<=x;i++) if(x%i==0) return false;
    return true;
}
void dfs(int index,int numberNext,int sum){
    if(index==k){
        if(prime(sum)) answer++;
        return;
    }

    for(int i=numberNext;i<n;i++){
        dfs(index+1,i+1,sum+number[i]);
    }
}
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    if(!(cin>>n>>k)) return 1;
    number.resize(n);
    for(int i=0;i<n;i++) cin>>number[i];
    dfs(0,0,0);
    cout<<answer;
    return 0;
}