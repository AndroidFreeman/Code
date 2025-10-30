#include<stdio.h>
//解法2
int inputNumber() {
    int score;
    int checker;
    while (1){
        printf("请输入成绩 (0-100, -1 结束):");
        checker=scanf("%d",&score);
        if (ret==1) {
            if (score==-1||(score>=0&&score<=100)){
                return score;
            }
            printf("成绩无效，请输入0-100之间的分数。\n");
        } else {
            printf("输入无效，请输入一个数字。\n");
        }
        while (getchar()!='\n');
    }
}
//单独拉一个模块检测合法性输入(多数据输入我会使用这个方案)

//解法3
//用CPP写,用字符串接受输入值,stringstream读取输入,再转化成数字
//include<bits/stdc++.h>
//using namespace std;
// int getValidScore() {
//     string line;
//     int score;
//     while(true) {
//         cout<<"Enter a number(0-100),-1 to cancle";
//         if(!getline(cin,line)) {
//             return -1;
//         }
//         stringstream temp(line);
//         if(temp>>score) {
//             char trash;
//             if(temp>>trash) {
//                 cout<<"ErrorCode1\n";
//             }else{
//                 if(score==-1||(score >= 0 && score <= 100)) {
//                     return score;
//                 }
//                 cout<<"ErrorCode2\n";
//             }
//         }else{
//             cout<<"ErrorCode3\n";
//         }
//     }
// }

int main(){
	int score;
	int count = 0;
	int max = 0, min = 100;
	float sum = 0;
	printf("请输入成绩（以输入-1作为结束）\n");
	while(1)
	{

        //scanf("%d",&score);
        //这个地方跟我想的地方一样,我上课就在想是不是缓冲区的问题
        //受限于学了CPP忘了格式化输入,当时未能及时给出答案

        //解法1
        int checker;
        checker=scanf("%d",&score);
	    if (!checker){
	   	  while(getchar()!='\n');
	    }
        //scanf会返回bool值,用bool值来判断输入是否合法,用循环消耗掉缓冲区

        //解法2续
        //number=inputNumber();


        //解法4
        //我记得有个scanf_s的东西,但是Linux用的C89,那我也懒得学了()

	   if(score == -1){
	   	  break;
	   }

	   if(score<0 || score>100 ){
	   	printf("成绩无效，请输入0-100之间的分数\n");
	   	continue;
	   }

	   count++;
	   sum+=score;

	   if(score>max){
	    max=score;
	   }
	   if(score<min){
	   	min=score;
	   }
   }

	   if(count>0){
	   	  printf("\n统计结果：\n");
	   	  printf("总人数：%d\n",count);
	   	  printf("最高分：%d\n",max);
	   	  printf("最低分：%d\n",min);
	   	  printf("平均分：%.2f\n",sum/count);
	   }
	   else {
	   	printf("没有输入有效成绩！");
	   }

	return 0;

}
