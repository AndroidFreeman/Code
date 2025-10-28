//P1601
#include<bits/stdc++.h>
using namespace std;
int main(){
    //input
    vector<int> left,right;
    string tleft,tright;
    cin>>tleft>>tright;
    for(int i=tleft.length()-1;i>=0;i--){
        left.push_back(tleft[i]-'0');
    }
    for(int i=tright.length()-1;i>=0;i--){
        right.push_back(tright[i]-'0');
    }

    //plus
    vector<int> sum;
    int carry=0;
    for(int i=0;i<left.size()||i<right.size();i++){
        if(i<left.size()){
            carry+=left[i];
        }
        if(i<right.size()){
            carry+=right[i];
        }
        sum.push_back(carry%10);
        carry=carry/10;
    }
    if(carry){
        sum.push_back(carry);
    }

    //output
    for(int i=sum.size()-1;i>=0;i--){
        cout<<sum[i];
    }
    cout<<endl;
}
