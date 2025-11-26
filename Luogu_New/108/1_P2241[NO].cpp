#include<bits/stdc++.h>
using namespace std;
long long m,n,rec,sqr;
int main(){
    cin>>n>>m;
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            if(i==j)  sqr+=(n-i)*(m-j);
            else rec+=(n-i)*(m-j);
        }
    }
    cout<<sqr<<" "<<rec<<endl;
}
