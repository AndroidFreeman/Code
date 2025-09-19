#include<stdio.h>
#include<ctype.h>
int main(){
    // int len=0;
    // printf("Enter a message: ");
    // while(getchar()!='\n'){
    //     len++;
    // }
    // printf("Your length is %d\n",len);

    // int eight=077;
    // int sixteen1=0x77;
    // int sixteen2=0XABC;
    // printf("%d %d %d",eight,sixteen1,sixteen2);

    // printf("Enter phone number:");
    // char ch;
    // while((ch=getchar())!='\n'){
    //     switch(ch){
    //         case 'A':case 'B':case 'C':
    //             putchar('2');
    //             break;
    //         case 'D':case 'E':case 'F':
    //             putchar('3');
    //             break;
    //         case 'G':case 'H':case 'I':
    //             putchar('4');
    //             break;
    //         case 'J':case 'K':case 'L':
    //             putchar('5');
    //             break;
    //         case 'M':case 'N':case 'O':
    //             putchar('6');
    //             break;
    //         case 'P':case 'Q':case 'R':case 'S':
    //             putchar('7');
    //             break;
    //         case 'T':case 'U':case 'V':
    //             putchar('8');
    //             break;
    //         case 'W':case 'X':case 'Y':case 'Z':
    //             putchar('9');
    //             break;
    //         default:
    //             putchar(ch);
    //             break;
    //     }
    // }

    emini

2.5 Pro


PRO
与 Gemini 对话
编写可以把字母格式的电话号码翻译成数值格式的程序：

156

122 第 7 章 基本类型

Enter phone number: CALLATT

2255288

（如果没有电话在身边，参考这里给出的字母在键盘上的对应关系：2=ABC、3=DEF、4=GHI、5=JKL、

6=MNO、7=PQRS、8=TUV、9=WXYZ。）原始电话号码中的非字母字符（例如数字或标点符号）保持不变：

Enter phone number: 1-800-COL-LECT

1-800-265-5328

 可以假设任何用户输入的字母都是大写字母





显示思路
好的，这是一个符合您要求的C语言程序。

C 代码
C

#include <stdio.h> // 引入标准输入输出库

int main(void) {
    char ch; // 声明一个字符变量，用于存储用户输入的每个字符

    // 提示用户输入电话号码
    printf("Enter phone number: ");

    // 使用 while 循环逐个读取字符，直到用户按下回车键（'\n'）
    while ((ch = getchar()) != '\n') {
        // 使用 switch 语句判断当前字符
        switch (ch) {
            // 如果字符是 A, B, 或 C，则输出 2
            case 'A': case 'B': case 'C':
                putchar('2');
                break;
            // 如果字符是 D, E, 或 F，则输出 3
            case 'D': case 'E': case 'F':
                putchar('3');
                break;
            // 如果字符是 G, H, 或 I，则输出 4
            case 'G': case 'H': case 'I':
                putchar('4');
                break;
            // 如果字符是 J, K, 或 L，则输出 5
            case 'J': case 'K': case 'L':
                putchar('5');
                break;
            // 如果字符是 M, N, 或 O，则输出 6
            case 'M': case 'N': case 'O':
                putchar('6');
                break;
            // 如果字符是 P, Q, R, 或 S，则输出 7
            case 'P': case 'Q': case 'R': case 'S':
                putchar('7');
                break;
            // 如果字符是 T, U, 或 V，则输出 8
            case 'T': case 'U': case 'V':
                putchar('8');
                break;
            // 如果字符是 W, X, Y, 或 Z，则输出 9
            case 'W': case 'X': case 'Y': case 'Z':
                putchar('9');
                break;
            // 如果字符不是以上任何字母，则原样输出
            default:
                putchar(ch);
                break;
        }
    }

    // 在输出电话号码后打印一个换行符，使命令行界面更整洁
    putchar('\n');

    return 0; // 程序正常结束
}
程序如何工作
包含头文件：#include <stdio.h> 用于支持输入/输出函数，如 printf, getchar 和 putchar。

提示用户输入：程序首先会打印 "Enter phone number: " 来提示用户。

循环读取字符：

while ((ch = getchar()) != '\n') 是程序的核心。getchar() 函数会从键盘读取一个字符。

这个循环会一直执行，每次读取一个字符并赋值给变量 ch，直到用户按下回车键（\n）为止。

翻译字符：

switch (ch) 语句检查 ch 变量的值。

C语言 switch 语句有一个“贯穿” (fall-through) 的特性。例如，case 'A': case 'B': case 'C': 表示如果 ch 是 'A'、'B' 或 'C' 中的任何一个，都会执行它们下方的 putchar('2'); 代码。

break; 语句用于在执行完一个 case 的代码后跳出 switch 结构，防止程序继续执行下一个 case。

处理非字母字符：

如果输入的字符不是 'A' 到 'Z' 之间的任何一个字母，那么 switch 语句中前面的 case 都不会匹配。

这时，程序会执行 default: 块中的代码，即 putchar(ch);，它会把这个非字母字符（如数字 '1' 或标点符号 '-'）原封不动地打印出来。

结束和换行：当循环结束后（用户按了回车），程序会执行 putchar('\n');，在输出的数字电话号码末尾添加一个换行，这样命令行的提示符会显示在新的一行，看起来更美观。

运行示例
示例 1:

Enter phone number: CALLATT
2255288
示例 2:

Enter phone number: 1-800-COL-LECT
1-800-265-5328

在十字拼字游戏中，玩家利用小卡片组成英文单词，每张卡片包含一个英文字母和面值。面值根据

字母稀缺程度的不同而不同。（面值与字母的对应关系如下：1——AEILNORSTU；2——DG；3——

BCMP；4——FHVWY；5——K；8——JX；10——QZ。）编写程序，通过对单词中字母的面值求和

来计算单词的值：

Enter a word: pitfall

Scrabble value: 12

 编写的程序应该允许单词中混合出现大小写字母。提示：使用 toupper 库函数。





显示思路
当然，这里是计算十字拼字游戏（Scrabble）单词分值的C语言程序。

这个程序会读取用户输入的单词，并根据您提供的字母分值规则计算总分。它能够正确处理大小写混合的输入。

C 代码
C

#include <stdio.h>   // 引入标准输入输出库，用于 printf, getchar
#include <ctype.h>   // 引入字符处理库，用于 toupper 函数

    char ch;
    int score = 0;
    printf("Enter a word: ");
    while ((ch = getchar()) != '\n') {
        ch = toupper(ch);
        switch (ch) {
            case 'A': case 'E': case 'I': case 'L': case 'N':
            case 'O': case 'R': case 'S': case 'T': case 'U':
                score += 1; // score = score + 1;
                break;
            case 'D': case 'G':
                score += 2;
                break;
            case 'B': case 'C': case 'M': case 'P':
                score += 3;
                break;
            case 'F': case 'H': case 'V': case 'W': case 'Y':
                score += 4;
                break;
            case 'K':
                score += 5;
                break;
            case 'J': case 'X':
                score += 8;
                break;
            case 'Q': case 'Z':
                score += 10;
                break;
        }
    }
    printf("Scrabble value: %d\n", score);
}

