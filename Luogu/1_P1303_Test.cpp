#include<bits/stdc++.h>
using namespace std;
int main(){
    //优化io速度
    ios::sync_with_stdio(false);
    cin.tie(0);

    string s1,s2;
    cin>>s1>>s2;
    if(s1=="0"||s2=="0"){
        cout<<0<<endl;
        return 0;
    }
    int len1=s1.length();
    int len2=s2.length();

    vector<int> a(len1),b(len2),c(len1+len2,0);

    for(int i=0;i<len1;i++){
        a[i]=s1[len1-1-i]-'0';
    }
    for(int i=0;i<len2;i++){
        b[i]=s2[len2-i-1]-'0';
    }

    //Process
    for(int i=0;i<len1;i++){
        for(int j=0;j<len2;j++){
            c[i+j]+=a[i]*b[j];
            c[i+j+1]+=c[i+j]/10;
            c[i+j]%=10;
        }
    }

    int len_c=len1+len2;
    while(len_c>=1&&c[len_c-1]==0){
        len_c--;
    }

    //Output
    for(int i=len_c-1;i>=0;i++){
        cout<<c[i];
    }

}
