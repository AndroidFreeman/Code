/*
 * @datetime: 2026-06-16 18:04:23
 * @Github: https://github.com/AndroidFreeman
 * @Author: Android_Freeman
 * @relativePath: /LearnRust/Learn_With_The_Book/2_1_Guess_Game.rs
 * @Description:
 */

use std::io;
// 为获取用户输入, 并将结果打印为输出, 则需要把io库引用当前作用域
// io库来自std库

fn main() {
    println!("Guess the number!");
    println!("Please input your guess.");

    // let apples=5;
    //     let语句创建变量, 变量默认不可变
    // let mut bananas=5;
    //     let mut就是可变
    let mut guess = String::new();
    // = 就是把某个值绑定在某个变量上
    // 等号的右边是guess所绑定的值, 就是String::new的结果
    // 这个函数会返回一个String的实例, String是标准库提供的字符串类型
    // ::new中的::表明new是String类型的一个关联函数
    // 关联函数是针对某个类型实现的函数
    // 这个new函数创建了一个新的空字符串
    // 总的来说, 这句话创建了一个可变变量, 绑定到了一个新的String空实例上

    io::stdin()
        //如果开头没有use, 就写成std::io::stdin()
        //stdin函数返回一个std::io::Stdin的实例
        //这是一种代表总段输入标准举兵的类型
        .read_line(&mut guess)
        // 调用了stdin的read_line的方法, 以获取用户输入
        // 我们将&mut guess作为参数传入read_line, 将用户输入存入中国字符串
        // read_line, 无论用户输入什么内容, 都会追加到字符串中, 所以需要一个字符串作为参数
        // & 表示引用, 允许多处代码访问同一处数据, 不用在内存里多次copy
        // 引用默认不可变
        .expect("Failed to read line");
    // .read_line会返回一个Result类型的值, Result是一种枚举类型
    // Result成员是Ok和Err
    // 如果不加.expect会警告

    println!("You guessed :{guess}");
    // {}是占位符
    // 打印变量的值, 变量名可以写进大括号中
    // 打印表达式的执行结果, 可以有以下写法
    // let x = 5;
    // let y = 10;
    // println!("x = {x} and y + 2 = {}", y + 2);
}
