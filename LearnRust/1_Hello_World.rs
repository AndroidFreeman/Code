/*
 * @Date: 2026-03-25 17:25:08
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-25 17:29:40
 * @FilePath: /Code/LearnRust/1_Hello_World.rs
 */
fn greet(){
    let english1="Hello!";
    let english2="World!";
    let sets=[english1,english2];
    for set in sets.iter(){
        println!("{}",&set);
    }
}

fn main(){
    greet();
}