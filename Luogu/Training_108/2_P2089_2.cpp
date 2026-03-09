/*
 * @Date: 2026-03-09 12:58:04
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 13:09:50
 * @FilePath: /Code_Sync/Luogu/Training_108/2_P2089_2.cpp
 */
#include <bits/stdc++.h>
using namespace std;
struct Scheme{
    int a[10];
};
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n;
    cin>>n;
    if(n<10||n>30){
        cout<<0;
        return 0;
    }

    vector<Scheme> res;
    for (int a1 = 1; a1 <= 3; a1++) {
    for (int a2 = 1; a2 <= 3; a2++) {
    for (int a3 = 1; a3 <= 3; a3++) {
    for (int a4 = 1; a4 <= 3; a4++) {
    for (int a5 = 1; a5 <= 3; a5++) {
    for (int a6 = 1; a6 <= 3; a6++) {
    for (int a7 = 1; a7 <= 3; a7++) {
    for (int a8 = 1; a8 <= 3; a8++) {
    for (int a9 = 1; a9 <= 3; a9++) {
    for (int a10 = 1; a10 <= 3; a10++) {
        if(a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9 + a10 == n){
            Scheme s = {a1, a2, a3, a4, a5, a6, a7, a8, a9, a10};
            res.push_back(s);
        }
    }}}}}}}}}}

    int answer=res.size();
    cout<<answer<<endl;
    for(int i=0;i<answer;i++){
        for(int j=0;j<10;j++){
            cout<<res[i].a[j];
        }
        cout<<endl;
    }
    
    return 0;
}