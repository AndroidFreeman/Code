#include<bits/stdc++.h>
using namespace std;
int main(){
    //prepare
    std::ios::sync_with_stdio(false);
    cin.tie(0);

    //input
    int N,NA,NB;
    cin>>N>>NA>>NB;
    vector<int> A(NA);
    vector<int> B(NB);
    for(int i=0;i<NA;i++){
        cin>>A[i];
        A[i]++;
    }
    for(int i=0;i<NB;i++){
        cin>>B[i];
        B[i]++;
    }

    for(int i=0;i<NA*N;i++){
        int j=0;
        if(j==6){
            j=0;
        }
        A[i]=a[j];
        j++
    }
    for(int i=0;i<NB*N;i++){
        int j=0;
        if(j==5){
            j=0;
        }
        B[i]=b[j];
        j++
    }
    //process
    int lenA=A.length();
    int lenB=B.length();
    int len;
    if(lenA>lenB){
        len=lenA;
    }else{
        len=lenB;
    }
    int sa=0;
    int sb=0;
    for(int i=0;i<len;i++){
        if(A[i]==B[i]){
            sa+=0;
            sb+=0;
        }
        if(A[i]==1&&(B[i]==3||B[i]==4)){
            sa+=1;
        }else{
            sb+=1;
        }
        if(A[i]==2&&(B[i]==1||B[i]==4)){
            sa+=1;
        }else{
            sb+=1;
        }
        if(A[i]==3&&(B[i]==))
    }
}
