#include <stdio.h>
#include <string.h>
extern int b;
const int a = 19;
int add(int age,int a);
int Plus(int num3, int num4);
#define MAX 100
#define STR "csndm"
//enumerate
enum Color{
    RED,
    GREEN,
    BLUE
};
enum Sex {
    HELICOPTER,
    MALE,
    FEMALE
};

int main(void) {
    printf("Hello, World!\n");
    printf("%zu\n", sizeof(char));
    printf("%zu\n", sizeof(short));
    printf("%zu\n", sizeof(int));
    printf("%zu\n", sizeof(long));
    printf("%zu\n", sizeof(float));
    printf("%zu\n", sizeof(long long));
    printf("%zu\n", sizeof(double));
    printf("%zu\n", sizeof(long double));

    short age = 19;
    double high = 181.2;
    double weight = 108.2;
    int num1=1;
    //scanf("%d", &num1);
    const int num2=num1;
    printf("%d\n",num1+num2);

    int sum=add(age,a);
    printf("%d\n",sum);

    int arr[MAX]={1999};
    printf("%d\n",arr[0]);
    printf("%s\n",STR);
    enum Color c=RED;
    enum Sex man=MALE;
    // printf("Kobe:%s\n",man);

    char arr1[]="abc";
    char arr2[]={'a','b','c'};
    printf("%s\n",arr1);
    printf("%s\n",arr2);
    printf("%zu\n",strlen(arr1));
    printf("%zu\n",strlen(arr2));
    printf("C:\\windows\\system32.dll\n");

    int input=0;
    printf("Choose0/1\n");
    scanf("%d",&input);
    if(input==1) {
        printf("1\n");
    }
    else if(input==0) {
        printf("0\n");
    }
    else {
        printf("fuck\n");
    }

    int line = 0;
    while(line<=10) {
        printf("%d\n",line);
        line++;
    }

    int num3=1;
    int num4=3;
    int plus=Plus(num3,num4);
    printf("%d\n",plus);

    //Array
    int arr10[10]={0,1,2,3,4,5,6,7,8,9};
    printf("%d\n",arr10[8]);
    for(int i=0;i<10;i++) {
        printf("%d ",arr10[i]);
    }
    printf("")
    char ch[];

    

}

int add(int num1, int num2) {
    return num1 + num2;
}

int Plus(int num3, int num4){
    return num3 + num4;
}


