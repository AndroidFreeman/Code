//P1042
#include<bits/stdc++.h>
using namespace std;
int main(){
    //input
    string s;
    char ch;
    while((ch=getchar())!='E'){
        if(ch=='W'||ch=='L'){
            s.push_back(ch);
        }
    }

    //11
    int left,right;
    left=0;
    right=0;
    for(int i=0;i<s.size();i++){
        if(s[i]=='W'){
            left+=1;
        }else{
            right+=1;
        }
        if((left>=11&&left-right>=2)||(right>=11&&right-left>=2)){
            cout<<left<<':'<<right<<endl;
            left=0;
            right=0;
        }
    }
    cout<<left<<':'<<right<<endl;
    cout<<endl;

    //21
    left=0;
    right=0;
    for(int i=0;i<s.size();i++){
        if(s[i]=='W'){
            left+=1;
        }else{
            right+=1;
        }
        if((left>=21&&left-right>=2)||(right>=21&&right-left>=2)){
            cout<<left<<':'<<right<<endl;
            left=0;
            right=0;
        }
    }
    cout<<left<<':'<<right<<endl;
    cout<<endl;
}
