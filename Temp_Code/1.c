#include<stdio.h>
// Program1 所需：计算阶乘（返回 double 以防止溢出）
double Fun1T(int number){
    double answer=1;
    for(int i=number;i>0;i--){
        answer=answer*i;
    }
    return answer;
}
// Program1 所需：计算组合数 C(n, m)
double Fun1(int input_1,int input_2){
    double upper=Fun1T(input_1);
    double down1=Fun1T(input_2);
    double down2=Fun1T(input_1-input_2);
    double answer=(upper/(down1*down2));
    return answer;
}

// Program2 所需：补全 Fun2，用于计算整数阶乘
int Fun2(int number){
    int answer=1;
    for(int i=number;i>0;i--){
        answer=answer*i;
    }
    return answer;
}

int main(){
    // --- Program1: 计算组合数 ---
    printf("Please input two numbers for Combination C(n,m):\n");
    int input_1,input_2;
    int bigger,smaller;

    scanf("%d %d",&input_1,&input_2);

    // 自动判定大小，确保 n >= m
    if(input_1>input_2){
        smaller=input_2;
        bigger=input_1;
    }else{
        smaller=input_1;
        bigger=input_2;
    }

    double ans_1=Fun1(bigger,smaller);
    printf("Result of Combination: %lf\n",ans_1);





    // --- Program2: 计算阶乘之和 ---
    // printf("Please input n for Sum of Factorials:\n");
    int i,n,sum=0;
    scanf("%d",&n);
    //输入数字3
    for(i=1;i<=n;i++){
        sum+=Fun2(i); // 调用补全后的 Fun2
    }
    printf("Sum of factorials: %d\n",sum);
}

