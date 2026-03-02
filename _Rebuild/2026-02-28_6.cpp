/*
 * @Date: 2026-02-28 21:15:33
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 22:02:41
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_6.cpp
 */
/*
📘 蓝桥杯专项练习：【简单】括号大作战
【题目描述】
在蓝桥王国的代码工厂里，程序员们经常会写出各种嵌套的括号。为了保证代码能正常运行，系统需要检查括号的匹配是否合法。
给定一个只包含三种括号的字符串：圆括号 ()、方括号 [] 和 花括号
{}。请你判断该字符串是否合法。 【合法标准】 左括号必须用相同类型的右括号闭合。
左括号必须以正确的顺序闭合。
每个右括号必须有一个对应的相同类型的左括号。
【示例】
输入："{[()]}" -> 输出：YES
输入："([)]" -> 输出：NO（顺序错误）
输入："([]" -> 输出：NO（左括号多余）
输入：")(" -> 输出：NO（右括号先出现）
*/
#include <bits/stdc++.h>
using namespace std;
// 丢人啊 重来一遍
/*
int main() {
    stack<char> check_left;
    stack<char> check_right;
    bool check;
    string input;
    // cin>>input;
    input="{Fuck[sh[it(eat)]]}";
    //left-> ( [ [ {
    //right-> } ] ] )
    for(int i=0;i<input.size();i++){
        char temp=input[i];
        if(temp=='{'||temp=='['||temp=='('){
            check_left.push(temp);
        }else if (temp=='}'||temp==']'||temp==')') {
            check_right.push(temp);
        }
    }
    stack<char> rright;
    int value=check_left.size();
    for(int i=0;i<value;i++){
        char temp;
        temp=check_right.top();
        check_right.pop();
        rright.push(temp);
    }
    for(int i=0;i<value;i++){
        char left=check_left.top();
        check_left.pop();
        char right=rright.top();
        rright.pop();
        if((left=='('&&right==')')||(left=='{'&&right=='}')||(left=='['&&right==']')){
            check=true;
        }else {
            cout<<"No"<<endl;
            return 0;
        }
    }
    if(check) cout<<"Yes"<<endl;
}
*/

int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    string input;
    // cin>>input;
    input = "{Fuck[sh[it(eat)]]}";
    stack<char> stk;

    for (int i = 0; i < input.size(); i++) {
        char c = input[i];
        if (c == '(' || c == '[' || c == '{') {
            stk.push(c);
        } else if (c == ')' || c == ']' || c == '}') {
            if (stk.empty()) {
                cout << "No" << endl;
                return 0;
            }
            char top = stk.top();
            if ((c == ')' && top == '(') || (c == ']' && top == '[') ||
                (c == '}' && top == '{')) {
                stk.pop();
            } else {
                cout << "No" << endl;
                return 0;
            }
        }
    }
    if (stk.empty()) {
        cout << "Yes" << endl;
    } else {
        cout << "No" << endl;
    }
}