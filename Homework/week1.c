#include<stdio.h>
#include<math.h>
#define PI 3.1415926535
int main(){
    char city[63];
    int idNumber;
    char name[63];
    printf("Enter your city:");
    scanf("%s",city);
    printf("Enter your id number:");
    scanf("%d",&idNumber);
    printf("Enter your name:");
    scanf("%s",name);
    printf("Your city is %s",city);
    printf("Your id number is :%d",idNumber);
    printf("Your name is %s",name);

    float a,b,c;
    printf("Enter your sanjiaoxing:");
    scanf("%f %f %f",&a,&b,&c);
    float s=(a+b+c)/2;
    float area=(sqrt(s*(s-a)*(s-b)*(s-c)));
    printf("The answer is: %f\n",area);

    printf("Enter your rate:");
    float rate;
    scanf("%f",&rate);
    printf("Enter the year for saving:");
    float year;
    scanf("%f",&year);
    printf("Enter your capital:");
    float capital;
    scanf("%f",&capital);
    float deposit;
    deposit=capital+capital*year*(rate/100);
    printf("Your deposit is: %f",deposit);

    float r1,h1,r2,h2;
    float v1,s1,v2,s2;
    printf("Circular cone's r h:");
    scanf("%f%f",&r1,&h1);
    printf("Cylinder's r h:");
    scanf("%f%f",&r2,&h2);
    v1 = PI*r1*r1*h1/3;
    s1 = PI*r1*r1+PI*r1*(sqrt(r1*r1+h1*h1));
    v2 = PI*r2*r2*h2;
    s2 = 2*PI*r2*r2+2*PI*r2*h2;
    printf("Circular cone v:%f s:%f",v1,s1);
    printf("Cylinder v:%f s:%f",v2,s2);

    char number;
    printf("Enter a char:");
    scanf("%c",&number);
    printf("%d",number);

    char input_char;
    printf("Enter a char:");
    scanf(" %c", &input_char);
    if (input_char >= 'a' && input_char <= 'z') {
        char uppercase_char = input_char - 32;
        printf("Char: %c\n", uppercase_char);
        printf("10: %d\n", uppercase_char);
        printf("16: %X\n", uppercase_char);
    } else {
        printf("Wrong\n");
    }

    char c1,c2;
    int n1,n2;
    c1=getchar();
    c2=getchar();
    n1=c1-'0';
    n2=n1*10+(c2-'0');
    printf("%d\n",n2);
}
