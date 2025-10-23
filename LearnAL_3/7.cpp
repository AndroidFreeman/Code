//next_permutation()
#include<bits/stdc++.h>
using namespace std;
int main(){
    //HDU1027
    int a[1001];
    int n,m;
    while(cin>>n>>m){
        for(int i=1;i<=n;i++){
            a[i]=i;
        }
        int b=1;
        do{
            if(b==m){
                break;
            }
            b++;
        }while(next_permutation(a+1,a+n+1));
        for(int i=1;i<n;i++){
            cout<<a[i]<<" ";
        }
        cout<<a[n]<<endl;
    }
}
