#include<bits/stdc++.h>
using namespace std;
int main(){
    //input
    string sa,sb;
    cin>>sa>>sb;
    if(sa=='0'||sb=='0'){
        cout<<'0'<<endl;
        return 0;
    }
    vector<int> A,B;
    for(int i=sa.length()-1;i>=0;i--){
        A.push_back(sa[i]-'0');
    }
    for(int i=sb.length()-1;i>=0;i--){
        B.push_back(sb[i]-'0');
    }

    //process
    vector<int> C(A.size()+B.size(),0);
    for(int i=0;i<B.size();i++){
        for(int j=0;j<A.size();j++){
            C[i+j]+=A[j]*B[i];
        }
    }
    int t=0;
    for(int i=0;i<C.size();i++){
        t+=C[i];
        C[i]=t%10;
        t=t/10;
    }
    int k=C.size()-1;
    while(k>0&&C[k]==0){
        k--;
    }

    //output
    for(int i=k;i>=0;i--){
        cout<<C[i];
    }
    cout<endl;
}
