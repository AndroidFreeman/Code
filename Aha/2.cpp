#include<bits/stdc++.h>
using namespace std;
int main(){
    int cap;
    cin>>cap;
    vector<int> a(cap+5);
    for(int i=1;i<=cap;i++){
        cin>>a[i];
    }
    for(int i=1;i<=cap-1;i++){
        for(int j=1;j<=cap-i;j++){
            if(a[j]<a[j+1]){
                swap(a[j],a[j+1]);
            }
        }
    }
    for(int i=1;i<=cap;i++){
        cout<<a[i]<<" ";
    }
}
