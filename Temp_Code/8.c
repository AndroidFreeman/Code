#include<bits/stdc++.h>
using namespace std;
int main(){
    int big,mid,small;
    for(big=1;big<20;big++){
        for(mid=1;mid<32;mid++){
            small=100-mid-big;
            if(small%3&&5*big+3*mid+small/3==100){
                cout<<big<<" "<<mid<<" "<<small<<endl;
            }
        }
    }
}
