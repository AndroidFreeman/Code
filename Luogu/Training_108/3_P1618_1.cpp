/*
 * @Date: 2026-03-09 13:40:27
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 13:53:59
 * @FilePath: /Code_Sync/Luogu/Training_108/3_P1618_1.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int A,B,C;
    if(!(cin>>A>>B>>C)) return -1;
    if(A==0){
        cout<<"No!!!"<<endl;
        return 0;
    }
    int total_solutions=0;
    for(int i=123/A;i<=999/C;i++){
        int b1=i*A;int b2=i*B;int b3=i*C;
        int bukket[10]={0};
        int temp1=b1;
        while (temp1>0) {
            bukket[temp1%10]++;
            temp1/=10;
        }
        int temp2=b2;
        while (temp2>0) {
            bukket[temp2%10]++;
            temp2/=10;
        }
        int temp3=b3;
        while (temp3>0) {
            bukket[temp3%10]++;
            temp3/=10;
        }
        bool ok=true;
    }
    


    return 0;
}