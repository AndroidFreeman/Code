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
}
