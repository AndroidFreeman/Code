#include<stdio.h>

void bubbleSort(int arr[],int n){
    int temp;
    for(int i=0;i<n-1;i++){
        for(int j=0;j<n-1-i;j++){
            if(arr[j]<arr[j+1]){
                temp=arr[j];
                arr[j]=arr[j+1];
                arr[j+1]=temp;
            }
        }
    }
}

void printArray(int arr[],int size){
    for(int i=0;i<size;i++){
        printf("%d ",arr[i]);
    }
    printf("\n");
}

int main(){
    int n;
    scanf("%d",&n);
    int arr[n];
    for(int o=0;o<n;o++){
        scanf("%d",&arr[o]);
    }
    printArray(arr,n);
    bubbleSort(arr,n);
    printArray(arr,n);
}
