//array
#include<bits/stdc++.h>
using namespace std;
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
    for(int i=0;i<5;i++){
        cout<<arr[i]<<" ";
    }
    insert(arr,10,5,1);
    for(int i=0;i<10;i++){
        cout<<arr[i]<<" ";
    }
    cout<<endl;
    remove(arr,10,5);
    for(int i=0;i<10;i++){
        cout<<arr[i]<<" ";
    }
    cout<<endl;
}
