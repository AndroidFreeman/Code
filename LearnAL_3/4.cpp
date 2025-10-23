//Set
#include<bits/stdc++.h>
using namespace std;
int main(){
    set<int> T;
    T.insert(1);
    T.insert(2);
    T.insert(3);
    T.erase(2);
    auto it=T.find(3);
    cout<<*it<<endl;

    //HDU2094
    set<string> A,B;
    string s1,s2;
    int n;
    while(cin>>n&&n){
        for(int i=0;i<n;i++){
            cin>>s1>>s2;
            A.insert(s1);
            A.insert(s2);
            B.insert(s2);
        }
        if(A.size()-B.size()==1){
            cout<<"Yes"<<endl;
        }else{
            cout<<"No"<<endl;
        }
        A.clear();
        B.clear();
    }
}
