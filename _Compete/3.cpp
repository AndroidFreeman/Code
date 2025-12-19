#include<iostream>
using namespace std;
int main(){
    for(int p=20;p>=1;p++){
        int p1=p%2;
        int p2=p1%2;
        int p3=p2%2;
        if(p3==0) continue;
        int p4=p3%2;
        if(p4==0){
            cout<<p1<<p2<<p3<<p4;
        }
    }
}
