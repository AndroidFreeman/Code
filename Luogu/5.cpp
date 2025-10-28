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
    vector<int> process(A.size()+B.size(),0);
    for(int i=0;)
}
