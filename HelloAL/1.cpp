//array
#include<bits/stdc++.h>
using namespace std;
void printArr(int *nums,int size){
    for(int i=0;i<size;i++){
        cout<<nums[i]<<" ";
    }
    cout<<endl;
}
int randomAccess(int *nums,int size){
    int randomIndex=rand()%size;
    int randomNum=nums[randomIndex];
    return randomNum;
}
void insert(int *nums,int size,int num,int index){
    for(int i=size-1;i>index;i--){
        nums[i]=nums[i-1];
    }
    nums[index]=num;
}
void remove(int *nums,int size,int index){
    for(int i=index;i<size-1;i++){
        nums[i]=nums[i+1];
    }
}
int main(){
    int arr[10]={0};
    int nums[5]={1,3,2,5,4};
    int* arr1=new int[5];
    int* nums1=new int[5]{1,3,2,5,4};
    int ramdomNum=randomAccess(arr,5);
    printArr(arr,10);
    insert(arr,10,5,1);
    printArr(arr,10);
    remove(arr,10,1);
    printArr(arr,10);
}
