// #include<bits/stdc++.h>
// using namespace std;
// //Student
// struct Student{
//     int id,chinese,total;
// };
// //Compare Law
// bool cmp(Student a,Student b){
//     if(a.total!=b.total){
//         return a.total>b.total;
//     }
//     if(a.chinese!=b.chinese){
//         return a.chinese>b.chinese;
//     }
//     return a.id<b.id;
// }
// int main(){
//     //prepare
//     std::ios::sync_with_stdio(false);
//     cin.tie(0);
//     //input
//     int stu_num;
//     cin>>stu_num;
//     vector<Student> stu(stu_num);
//     for(int i=0;i<stu_num;i++){
//         int chi,mat,eng;
//         cin>>chi>>mat>>eng;
//         stu[i].id=i+1;
//         stu[i].chinese=chi;
//         stu[i].total=chi+mat+eng;
//     }
//     //process
//     sort(stu.begin(),stu.end(),cmp);
//     //output
//     for(int i=0;i<5;i++){
//         cout<<stu[i].id<<" "<<stu[i].total<<endl;
//     }
// }











#include<bits/stdc++.h>
using namespace std;
struct Student{
    int id,chinese,total;
}
int main(){
    //prepare
    std::ios::sync_with_stdio(false);
    cin.tie(0);
    //input
    int s_num;
    cin>>s_num;
    vector<Student> stu(s_num);
    for(int i=0;i<s_num;i++){
        int chi,math,eng;
        cin>>chi>>math>>eng;
        stu[i].chi=chi;
        stu[i].id=i+1;
        stu[i].total=chi+math+eng;
        
    }
}








