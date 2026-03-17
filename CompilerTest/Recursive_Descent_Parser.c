/*
 * @Date: 2026-03-17 13:00:20
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-17 13:00:21
 * @FilePath: /Code_Sync/CompilerTest/Recursive_Descent_Parser.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

const char*src;

// 预声明函数，处理递归依赖
double expression();
double term();
double factor();

// 错误处理
void error(const char*msg){
    fprintf(stderr,"Error: %s\n",msg);
    exit(1);
}

// 核心：处理数字和括号 (最底层)
double factor(){
    if(*src=='('){
        src++;
        double val=expression();
        if(*src==')')src++;
        else error("Expected ')'");
        return val;
    }
    if(isdigit(*src)){
        double val=strtod(src,(char**)&src);
        return val;
    }
    error("Unexpected character");
    return 0;
}

// 处理乘除 (中层)
double term(){
    double val=factor();
    while(*src=='*'||*src=='/'){
        char op=*src++;
        if(op=='*')val*=factor();
        else val/=factor();
    }
    return val;
}

// 处理加减 (顶层)
double expression(){
    double val=term();
    while(*src=='+'||*src=='-'){
        char op=*src++;
        if(op=='+')val+=term();
        else val-=term();
    }
    return val;
}

int main(){
    char input[256];
    printf("Enter expression: ");
    fgets(input,sizeof(input),stdin);
    src=input;
    
    // 跳过空白字符的简单处理可以在此处或解析函数中增加
    printf("Result: %g\n",expression());
    return 0;
}