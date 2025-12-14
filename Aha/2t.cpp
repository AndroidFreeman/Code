#include<bits/stdc++.h>
using namespace std;
int main(){
    int cap;
    cin>>cap;
    vector<int> number(cap+5);
    for(int i=0;i<cap;i++){
        cin>>number[i];
    }
    for(int i=0;i<cap-1;i++){
        for(int j=0;j<cap-i-1;j++){
            if(number[j+1]>number[j]){
                swap(number[j+1],number[j]);
            }
        }
    }
    for(int i=0;i<cap;i++){
        cout<<number[i]<<" ";
    }
}
