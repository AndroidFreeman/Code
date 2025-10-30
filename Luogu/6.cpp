//P1009
#include<bits/stdc++.h>
using namespace std;
int main(){
    //input
    int input,output,temp;
    cin>>input;
    //process
    for(int i=input;i<=0;i--){
        for(int j=input;j<=0;j--){
            temp+=i*j;
        }
        output+=temp;
    }
    //output
    cout<<output;
}
