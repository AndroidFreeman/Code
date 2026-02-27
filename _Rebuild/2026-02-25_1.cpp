#include<bits/stdc++.h>
using namespace std;
int main(){
    int score,sum=0,plus=0;
    cin>>score;
    while(score!=0){
        sum+=score;
        if(score==1){
            plus=0;
        }
        else{
            if(score==2){
                sum+=plus;
                plus+=2;
            }
        }
        cin>>score;
    }
    cout<<sum<<endl;
}