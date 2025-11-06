#include<stdio.h>
int main(){
    int stu;
    scanf("%d",&stu);
    if(stu>300||stu<0){
        return 1;
    }
    int chi[stu];
    int math[stu];
    int eng[stu];
    int index[stu];
    int score_total[stu];

    for(int i=0;i<stu;i++){
        scanf("%d %d %d",&chi[i],&math[i],&eng[i]);
        if(chi[i]>100||chi[i]<0||
           math[i]>100||math[i]<0||
           eng[i]>100||eng[i]<0){
            return 1;
           }
        score_total[i]=chi[i]+math[i]+eng[i];
        index[i]=i+1;
    }

    for(int i=0;i<stu-1;i++){
        for(int j=0;j<stu-i-1;j++){
            int need_swap=0;
            if(score_total[j]<score_total[j+1]){
                need_swap=1;
            }else if(score_total[j]==score_total[j+1]){
                if(chi[j]<chi[j+1]){
                    need_swap=1;
                }else if(chi[j]==chi[j+1]){
                    if(index[j]>index[j+1]){
                        need_swap=1;
                    }
                }
            }
            if(need_swap){
                int temp=score_total[j];
                score_total[j]=score_total[j+1];
                score_total[j+1]=temp;
                temp=chi[j];
                chi[j]=chi[j+1];
                chi[j+1]=temp;
                temp=index[j];
                index[j]=index[j+1];
                index[j+1]=temp;
            }
        }
    }
    for(int i=0;i<5;i++){
        printf("%d %d\n",index[i],score_total[i]);
    }
}
