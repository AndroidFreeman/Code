//BubbleSort
#include<bits/stdc++.h>
using namespace std;

void bubblesort(int A[],int n){
    bool sorted=false;
    //设一个bool类型的开关，表示排序状态
    while(!sorted){
    //若未排序，while开始循环
        sorted=true;
        //假设已经完成排序
        for(int i=1;i<n;i++){
            if(A[i-1]>A[i]){
                swap(A[i-1],A[i]);
                sorted=false;
                //如果找到未排序的情况，则sorted=false
            }
        }
        n--;
        //排序完的就不继续参加排列了
    }
}

int countOnes(unsigned int n){
    int ones=0;
    //计数器，用于记录找到了多少个1
    while(0<n){
        ones+=(1&n);
        n>>=1;
        //把输入的值右移一位
        //若15[1111] 则7[0111]
    }
    return ones;
}

int sumI(int A[],int n){
    int sum=0;
    for(int i=0;i<n;i++){
        sum+=A[i];
    }
    return sum;
}

_int64 power2BF(int n){
    _int64 pow=1;
    while(0<n--){
        pow<<=1;
    }
    return pow;
}

int main(){

}
