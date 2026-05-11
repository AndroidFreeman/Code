/*
 * @Date: 2026-04-30 10:40:24
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-30 11:15:22
 * @FilePath: /Code/LearnJava/L3.java
 */
public class L3 {
    public static void main(String[] args) {
        int x=100;
        System.out.println(x);
        x=200;
        System.out.println(x);
        System.out.println(x+x);

        int i1=10;
        int i2=-11;
        int i3=i1%i2;
        System.out.println(i3);
        int i4=1_000_000;
        int i5=0xff0000;
        int i6=0b100000;
        System.out.println(i4);
        System.out.println(i5);
        System.out.println(i6);

        long i7=10000000L;
        float f1=3.14f;
        float f2=4.15f;
        System.out.println(f2);
        double d1=1.79e308;
        System.out.println(d1);

        boolean b1=true;
        boolean b2=false;
        boolean isGreater=5>3;
        int age=12;
        boolean isAdult=age>=18;

        String s="hello";
        //引用类型

        char a='A';
        char zh='中';
        System.out.println(a);
        System.out.println(zh);

        final double PI=3.14;
        double r=5.0;
        double area = PI*r*r;
        System.out.println(area);

        // StringBuilder sb=new StringBuilder();
        var sb = new StringBuilder();
        //我们Java也有自己的auto

        
    }
}