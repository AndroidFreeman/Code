/*
 * @Date: 2026-03-30 11:38:23
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-30 11:49:05
 * @FilePath: /Code/LearnRust/2_var.rs
 */
fn main(){
    let mut x=5;
    println!("The value of x is: {}",x);
    x=6;
    println!("The value of x is: {}",x);

    let(a,mut b):(bool,bool)=(true,false);
    println!("a={:?},b={:?}",a,b);
    b=true;
    assert_eq!(a,b);

    const MAX_POINTS: u32=100_000;

    let x=5;
    let x=x+1;
    {
        let x=x*2;
        println!("The value of x in the inner is {}",x)
    }
    println!("The value of x in the inner is {}",x)

    let guess = "42".parse().expect("Not a number!");
}