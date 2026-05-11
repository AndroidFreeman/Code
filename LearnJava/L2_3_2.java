/*
 * @Date: 2026-05-04 09:14:10
 * @Github: https://github.com/AndroidFreeman
 * Windows Here!
 * @Author: Android_Freeman
 * @LastEditTime: 2026-05-04 09:24:29
 * @FilePath: \Code_Sync\LearnJava\L2_3_2.java
 */
public class L2_3_2{
    public static void main(String[] args){
        int x=100;
        System.out.println(x);
        x=200;
        System.out.println(x);

        System.out.println("X = "+x);

        StringBuilder sb=new StringBuilder("Hello");
        sb.append(", world");
        sb.insert(5, " Java");
        sb.delete(5,10);
        sb.reverse();

        String result=sb.toString();
        System.out.println(result);

        var sb1=new StringBuilder();
    }
}