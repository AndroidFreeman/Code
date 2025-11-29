#include <stdio.h>
#define NUMBER 1005
// Program1
void revstr(char* string){
    int j=0;
    int i=0;
    for(;string[j]!='\0';j++);
    j--;
    for(;i<j;i++,j--){
        char t=string[i];
        string[i]=string[j];
        string[j]=t;
    }
}

// Program2
int strcmp(char* s1,char* s2){
    int res;
    int i=0;
    for(i=0;s1[i]==s2[i]&&s1[i]!='\0';i++);
    res=s1[i]-s2[i];
    if(res>0){
        res=1;
    }else{
        if(res<0){
            res=-1;
        }
    }
    return res;
}

// Program3
int strlen(char* str){
    int len=0;
    while(str[len]!='\0'){
        len++;
    }
    return len;
}

// Program4
void strcat(char* ch1,char* ch2){
    int len1=0;
    while(ch1[len1]!='\0'){
        len1++;
    }
    int i=0;
    while(ch2[i]!='\0'){
        ch1[len1]=ch2[i];
        len1++;
        i++;
    }
    ch1[len1]='\0';
}

// Program5
//我们来写一个String Remove的功能
void srtrmv_new(char* ch){
    int index=0;
    while(ch[index]>='0'||ch[index]<='9'){
        index++;
    }

}
void srtrmv(char* ch){
    //Step1-获得字符串长度

    //在C语言中,我们可以用遍历的方法获取
    int len=0;
    //首先初始化字符串长度为0
    while(ch[len]!='\0'){
        len++;
    }
    //Q:这个循环是什么意思?
    //A:如果当前数组存储的值不是终止符时,数组长度+1

    //Step2-Process

    //这里有两张方法实现(我只想到两种)
    //1.对原数组操作
    //  这个方法比较麻烦(在学数据结构之前)
    //  需要对内存进行移位操作

    //2.建立一个答案数组
    //  本程序采用此方法

    char ans[NUMBER];
    //先创建一个答案数组
    int ans_len=0;
    //初始化答案数组长度为0;
    for(int i=0;i<len;i++){
    //循环范围为原数组长度
        if(ch[i]<'0' || ch[i]>'9'){
            ans[ans_len]=ch[i];
            ans_len++;
        }
        //如果数组里的值不在字符0到字符9之间,存储到ans数组
        //并对答案数组的长度+1
    }
    ans[ans_len]='\0';
    //在数组末尾补上终止符
    //上面len变量中并没有将终止符加入,需手动补
    printf("%s\n",ans);
}

int main(){
    // Program1
    char ch[NUMBER];
    scanf("%[^\n]",ch41);
    getchar();
    revstr(ch);
    puts(ch);
    printf("\n");

    // Program2
    char ch21[NUMBER];
    scanf("%[^\n]",ch21);
    getchar();
    char ch22[NUMBER];
    scanf("%[^\n]",ch22);
    getchar();
    int p2=strcmp(ch21,ch22);
    printf("%d\n",p2);

    // Program3
    int strlen3=strlen(ch21);
    printf("%d\n",strlen3);

    // Program4
    char ch41[NUMBER*2];
    scanf("%[^\n]",ch41);
    getchar();
    char ch42[NUMBER];
    scanf("%[^\n]",ch42);
    getchar();
    strcat(ch41,ch42);
    printf("%s\n", ch41);

    // Program5
    char ch5[NUMBER];
    //创建一个大小为200的数组变量
    scanf("%[^\n]",ch5);
    //这个东西有点意思
    //读取一行含有空格的字符串,直到遇到换行符为止
    getchar();
    //因为\n不会存入ch5里面,但是缓冲区仍然存在\n
    //用一个getchar()消耗掉
    srtrmv(ch5);
}
