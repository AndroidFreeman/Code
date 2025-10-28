//P1601
#include<bits/stdc++.h>
using namespace std;
int main(){
    vector<int> left,right;
    string tleft,tright;
    cin>>tleft>>tright;
    for(int i=tleft.length()-1;i>=0;i++){
        left.push_back(tleft[i]-'0');
    }
    for(int i=tright.length()-1;i>=0;i++){
        right.push_back(tright[i]-'0');
    }
}
