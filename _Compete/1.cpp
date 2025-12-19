#include<iostream>
using namespace std;
int main(){
    int numX=10;
    int numY=90;
    for(int tick=1;tick<=120;tick++){
        if(tick%2==1){
            numY=numY-numX;
        }
        if(tick%4==0){
            numY=numY*2;
        }
        if(tick%6==0){
            numX=numX*2;
        }
    }
    cout<<numY<<endl;
}
