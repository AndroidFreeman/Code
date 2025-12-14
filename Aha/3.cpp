#include<bits/stdc++.h>
using namespace std;
vectot<int> a(1001);
int n;

void quicksort(int left,int right){
    int i,j,t,temp;
    if(left>right){
        return;
    }
    temp=a[left];
    i=left;
    j=right;
    while(i!=j){
        while(a[j]>=temp&&i<j){
            j--;
        }
        while(a[i]<=temp&&i<j){
            i++;
        }
    }
}
