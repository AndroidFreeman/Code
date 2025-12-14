#include<bits/stdc++.h>
using namespace std;
int main(){
    vector<int> book(1001,0);
    int n,t;
    cin>>n;
    for(int i=1;i<=n;i++){
        cin>>t;
        book[t]++;
    }
    for(int i=1000;i>=0;i--){
        for(int j=1;book[i]>=j;j++){
            cout<<i;
        }
    }
    cout<<endl;
}
