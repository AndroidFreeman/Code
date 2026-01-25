#include<stdio.h>
#include<string.h>

//Program1
struct date{
    int year;
    int month;
    int day;
};

//Program2
//为了除法运算准确，建议将int改为float
typedef struct Complex{
    float r;
    float i;
}Complex;

Complex add(Complex a,Complex b){
    Complex result;
    result.r=a.r+b.r;
    result.i=a.i+b.i;
    return result;
}

Complex sub(Complex a,Complex b){
    Complex result;
    result.r=a.r-b.r;
    result.i=a.i-b.i;
    return result;
}

Complex mutiple(Complex a,Complex b){
    Complex result;
    result.r=a.r*b.r-a.i*b.i;
    result.i=a.r*b.i+a.i*b.r;
    return result;
}

Complex div(Complex a,Complex b){
    Complex result;
    float d=b.r*b.r+b.i*b.i;
    if(d==0){
        printf("Error: Divisor is 0\n");
        result.r=0; result.i=0;
        return result;
    }
    result.r=(a.r*b.r+a.i*b.i)/d;
    result.i=(a.i*b.r-a.r*b.i)/d;
    return result;
}

//Program3
struct stu{
    int num;
    char sex;
    char name[20];
    struct date birthday;
    float score[4];
    float ave;
};

//Program4
union IntChar{
    unsigned int num;
    char ch[4];
};

void Input(struct stu*a){
    printf("ID:");
    scanf("%d",&a->num);
    printf("Name:");
    scanf("%s",a->name);
    printf("Sex:");
    getchar(); //吃掉回车
    scanf("%c",&a->sex);
    printf("yyyy/mm/dd:");
    scanf("%d%d%d",&a->birthday.year,&a->birthday.month,&a->birthday.day);
    printf("Enter scores:");
    float sum=0;
    for(int i=0;i<4;i++){
        scanf("%f",&a->score[i]);
        sum+=a->score[i];
    }
    a->ave=sum/4.0;
}

void Output(struct stu*a){
    printf("ID:%d Name:%s Sex:%c Ave:%.2f\n",a->num,a->name,a->sex,a->ave);
}

void Inputarray(struct stu a[],int n){
    for(int i=0;i<n;i++){
        printf("\n---Student %d---\n",i+1);
        Input(&a[i]);
    }
}

void Outputarray(struct stu a[],int n){
    for(int i=0;i<n;i++){
        Output(&a[i]);
    }
}

void Searchname(struct stu a[],int n,char ch[]){
    int found=0;
    for(int i=0;i<n;i++){
        if(strcmp(ch,a[i].name)==0){
            printf("\nFind it! No.%d:\n",i);
            Output(&a[i]);
            found=1;
        }
    }
    if(!found){
        printf("404 Not Found\n");
    }
}

void Sortname(struct stu a[],int n){
    struct stu temp;
    for(int i=0;i<n-1;i++){
        for(int j=0;j<n-1-i;j++){
            if(strcmp(a[j].name,a[j+1].name)>0){
                temp=a[j];
                a[j]=a[j+1];
                a[j+1]=temp;
            }
        }
    }
    printf("Sorted\n");
}

int main(){
    //Program1
//    struct date Date;
//    printf("Date(yyyy mm dd):");
//    scanf("%d%d%d",&Date.year,&Date.month,&Date.day);
//    int days[13]={0,31,28,31,30,31,30,31,31,30,31,30,31};
//    if((Date.year%4==0&&Date.year%100!=0)||Date.year%400==0){
//        days[2]=29;
//    }
//    int answer=0;
//    for(int i=1;i<Date.month;i++){
//        answer+=days[i];
//    }
//    answer+=Date.day;
//    printf("Total days:%d\n\n",answer);

    //Program2
//    Complex input1,input2;
//    Complex output1,output2,output3,output4;
//    printf("Complex1(real image):");
//    scanf("%f%f",&input1.r,&input1.i);
//    printf("Complex2(real image):");
//    scanf("%f%f",&input2.r,&input2.i);
//    output1=add(input1,input2);
//    output2=sub(input1,input2);
//    output3=mutiple(input1,input2);
//    output4=div(input1,input2);
//    printf("Add->%.2f+%.2fi\n",output1.r,output1.i);
//    printf("Sub->%.2f+%.2fi\n",output2.r,output2.i);
//    printf("Mutiple->%.2f+%.2fi\n",output3.r,output3.i);
//    printf("Div->%.2f+%.2fi\n\n",output4.r,output4.i);

    //Program4
//    union IntChar u_obj;
//    printf("Enter Unsigned Integer:");
//    scanf("%u",&u_obj.num);
//    printf("ASCII Chars:");
//    //从低地址开始输出
//    for(int i=0;i<4;i++){
//        printf("%c",u_obj.ch[i]);
//    }
//    printf("\n\n");

    //Program3
    struct stu students[50];
    int n=0,choice;
    char search_name[20];
    printf("Enter student number:");
    scanf("%d",&n);
    if(n>50)n=50;
    Inputarray(students,n);
    while(1){
        printf("\n========MENU========\n");
        printf("1.Show all\n");
        printf("2.Search\n");
        printf("3.Sort\n");
        printf("0.Exit\n");
        printf("Choose:");
        scanf("%d",&choice);
        switch(choice){
            case 1:
                printf("\n---List---\n");
                Outputarray(students,n);
                break;
            case 2:
                printf("\nEnter name:");
                scanf("%s",search_name);
                Searchname(students,n,search_name);
                break;
            case 3:
                printf("\n---Sorted---\n");
                Sortname(students,n);
                Outputarray(students,n);
                break;
            case 0:
                printf("End\n");
                return 0;
            default:
                printf("Error\n");
        }
    }
}