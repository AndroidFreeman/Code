/*
 * @Date: 2026-03-09 13:11:39
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 13:17:44
 * @FilePath: /Code_Sync/Luogu/Training_108/2_P2089_3.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int n;
int temp[15];
vector<vector<int>> res;

void dfs(int step,int sum){
    if(step==10){
        if(sum==n){
            vector<int> plan;
            for(int i=0;i<10;i++) plan.push_back(temp[i]);
            res.push_back(plan);
        }
        return;
    }

    for(int i=1;i<=3;i++){
        temp[step]=i;
        dfs(step+1,sum+1);
    }
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    cin>>n;
    dfs(0,0);
    cout<<res.size()<<endl;
    for(int i=0;i<res.size();i++){
        for(int j=0;j<10;j++){
            cout<<res[i][j];
        }
        cout<<endl;
    }

    return 0;
}