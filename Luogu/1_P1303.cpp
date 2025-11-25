#include<bits/stdc++.h>
using namespace std;
int a[2005],b[2005],c[4005];
int main(){
    //Begin

    //优化IO速度
    ios::sync_with_stdio(false);
    cin.tie(0);

    string s1,s2;
    cin>>s1>>s2;

    //特殊情况->用户输入0
    if(s1=="0"||s2=="0"){
        cout<<0<<endl;
        return 0;
    }

    //获取长度
    int len1=s1.length();
    int len2=s2.length();

    //用vector存储数字
    vector<int> a(len1),b(len2),c(len1+len2,0);

    //倒序处理:将字符串转化为数字
    for(int i=0;i<len1;i++){
        a[i]=s1[len1-i-1]-'0';
    }
    for(int i=0;i<len2;i++){
        b[i]=s2[len2-i-1]-'0';
    }


    //Process

    //a的第i位乘以b的第j位,累加到c的j+i位
    for(int i=0;i<len1;i++){
        for(int j=0;j<len2;j++){
            //处理进位,保留个位,十位进到下一位
            c[i+j]+=a[i]*b[j];
            c[i+j+1]+=c[i+j]/10;
            c[i+j]%=10;
        }
    }

    //从最高位检查,查出第一个非零数字
    int len_c=len1+len2;
    while(len_c>1&&c[len_c-1]==0){
        len_c--;
    }

    //倒叙输出
    for(int i=len_c-1;i>=0;i--){
        cout<<c[i];
    }
    cout<<endl;
}
