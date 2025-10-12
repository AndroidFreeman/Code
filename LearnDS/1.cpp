#include<iostream>
using namespace std;

void bubblesort1A(int a[],int n){
    bool sorted=false;
    while(!sorted){
        sorted=true；
        for(int i=1;i<n;i++){
            if(A[i-1]<A[i]){
                swap(A[i-1],A[i]);
                sorted=false;
            }
        }
        n--;
    }
}

int main(){

}
