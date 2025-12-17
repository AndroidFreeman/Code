#include<bits/stdc++/h>
using namespace std;
int main(){
    cin.tie(0);
    std::ios::sync_with_stdio(false);

    vector<char> a(101);
    vector<char> s(101);
    int i,len,mid,next,top;
    cin<<a;
    len=strlen(a);
    mid=len/2-1;

    top=0;
    for(i=0;i<=mid;i++){
        s[++top]=a[i];
    }
    if(len%2==0){
        next=mid+1;
    }else{
        next=mid+2;
    }
    for(i=next;i<=len-1;i++){
        if(a[i]!=s[top]){
            break;
        }
        top--;
    }
    if(top==0){
        cout<<"YES";
    }else{
        cout<<"NO";
    }
}
