/*
 * @datetime: 2026-06-22 08:38:36
 * @Github: https://github.com/AndroidFreeman
 * @Author: Android_Freeman
 * @relativePath: /LearnRust/Learn_With_The_Book/src/bin/2_1_Guess_Game_Rng.rs
 * @Description:
 */

use std::io;

use rand::Rng;
//Rng是个trait, 定义了随机数生成器实现的方法

fn main() {
    println!("Guess the number!");

    let secret_number = rand::rng().random_range(1..=100);
    //之前可以写rand::thread_rng().gen_range(1..=100);
    //rand::rng() 返回默认的随机数生成器（由操作系统提供种子）
    //.random_range(start..=end) 在闭区间内生成随机数

    println!("The secret number is: {secret_number}");

    println!("Please input your guess.");

    let mut guess = String::new();

    io::stdin()
        .read_line(&mut guess)
        .expect("Failed to read line");

    println!("You guessed: {guess}");
}
