//Not Ready
//https://www.lanqiao.cn/problems/3150/learning/?page=1&first_category_id=1&problem_id=3150
//2026.1.25

#include<bits/stdc++.h>
using namespace std;
int main(){
    int n,k;
    int total=0;
    n=6,k=7;
    vector<int> a(n);
    a={7,4,6,2,1,6};
    // for(int i=1;i<=n;i++){
    //     cin>>a[i-1];
    // }

    for(int i=0;i<n;i++){
        bool flag=false;
        if(a[i]==k){
            a[i]=0;
            total++;
            flag=true;
        }
        if(flag){
            for(int i=0;i<n;i++){
                if(a[i]==k){
                    a[i]=0;
                }
            }
        }
    }

    cout<<total;

    return 0;
}