#include<bits/stdc++.h>
using namespace std;
int main(){
    // vector<int> a(11,0);
    // int i,j,t;
    // for(i=1;i<=5;i++){
    //     cin>>t;
    //     a[t]++;
    // }
    // for(i=10;i>=0;i--){
    //     for(j=1;j<=a[i];j++){
    //         cout<<i<<' ';
    //     }
    // }
    // cout<<endl;

    vector<int> book(1001,0);
    int n,t;
    cin>>n;
    for(int i=1;i<=n;i++){
        cin>>t;
        book[t]++;
    }
    for(int i=1000;i>=0;i--){
        for(int j=1;j<=book[i];j++){
            cout<<i;
        }
    }
    cout<<endl;
}
