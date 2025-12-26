// //array
// #include<bits/stdc++.h>
// using namespace std;
// int* extend(int *nums,int size,int enlarge){
//     int *res=new int[size+enlarge];
//     for(int i=0;i<size;i++){
//         res[i]=nums[i];
//     }
//     delete[] nums;
//     return res;
// }
// void printArr(int *nums,int size){
//     for(int i=0;i<size;i++){
//         cout<<nums[i]<<" ";
//     }
//     cout<<endl;
// }
// int find(int *nums,int size,int target){
//     for(int i=0;i<size;i++){
//         if(nums[i]==target){
//             return i;
//         }
//     }
//     return -1;
// }
// int traverse(int *nums,int size){
//     int count=0;
//     for(int i=0;i<size;i++){
//         count+=nums[i];
//     }
//     return count;
// }
// int randomAccess(int *nums,int size){
//     int randomIndex=rand()%size;
//     int randomNum=nums[randomIndex];
//     return randomNum;
// }
// void insert(int *nums,int size,int num,int index){
//     for(int i=size-1;i>index;i--){
//         nums[i]=nums[i-1];
//     }
//     nums[index]=num;
// }
// void remove(int *nums,int size,int index){
//     for(int i=index;i<size-1;i++){
//         nums[i]=nums[i+1];
//     }
// }
// int main(){
//     int arr[10]={0};
//     int nums[5]={1,3,2,5,4};
//     int* arr1=new int[5];
//     int* nums1=new int[5]{1,3,2,5,4};
//     int ramdomNum=randomAccess(arr,5);
//     printArr(arr,10);
//     insert(arr,10,5,1);
//     printArr(arr,10);
//     remove(arr,10,1);
//     printArr(arr,10);
//     insert(arr,10,5,1);
//     insert(arr,10,5,6);
//     insert(arr,10,5,9);
//     cout<<traverse(arr,10)<<endl;
//     cout<<find(arr,10,5)<<endl;
// }


















#include<bits/stdc++.h>
using namespace std;
void insert(int* nums,int size,int num,int index){
    for(int i=size-1;i>index;i--){
        nums[i]=nums[i-1];
    }
    nums[index]=num;
}
void delete(int* nums,int size,int index){
    for(int i=index;i<size-1;i++){
        nums[i]=nums[i+1];
    }
}
int traverse(int* nums,int size){
    int count=0;
    for(int i=0;i<size;i++){
        count+=nums[i];
    }
    return count;
}
int find(int* nums,int size,int num){
    for(int i=0;i<size;i++){
        if(nuns[i]==num){
            return i;
        }
    }
    return -1;
}
int *extend(int* nums,int size,int enlarge){
    int* arr=new int[size+enlarge];
    for(int i=0;i<size;i++){
        arr[i]=nums[i];
    }
    delete[] nums;
    return arr;
}
int main(){
    int arr[10];

}
