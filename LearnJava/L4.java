/*
 * @Date: 2026-04-30 11:16:13
 * 
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * 
 * @Author: Android_Freeman
 * 
 * @LastEditTime: 2026-04-30 11:48:37
 * 
 * @FilePath: /Code/LearnJava/L4.java
 */
public class L4 {
    public static void main(String[] args) {
        int i = (100 + 200) * (99 - 88);
        int n = 7 * (5 + (i - 9));
        System.out.println(i);
        System.out.println(n);

        int x = 12345 / 67;
        int y = 12345 % 67;
        System.out.println(x);
        System.out.println(y);

        int x1 = 2147483640;
        int y1 = 15;
        x1 -= 15;
        int sum = x1 + y1;

        System.out.println(sum);

        int n1 = 7;
        int a = n1 << 1;
        int b = n1 << 2;
        int c = n1 << 28;
        int d = n1 << 29;
        System.out.println(a);
        System.out.println(b);
        System.out.println(c);
        System.out.println(d);
        System.out.println();

        int n2 = -536870912;
        int a2 = n2 >> 1; // 11110000 00000000 00000000 00000000 = -268435456
        int b2 = n2 >> 2; // 11111000 00000000 00000000 00000000 = -134217728
        int c2 = n2 >> 28; // 11111111 11111111 11111111 11111110 = -2
        int d2 = n2 >> 29; // 11111111 11111111 11111111 11111111 = -1

        int n3 = -536870912;
        int a3 = n3 >>> 1; // 01110000 00000000 00000000 00000000 = 1879048192
        int b3 = n3 >>> 2; // 00111000 00000000 00000000 00000000 = 939524096
        int c3 = n3 >>> 29; // 00000000 00000000 00000000 00000111 = 7
        int d3 = n3 >>> 31; // 00000000 00000000 00000000 00000001 = 1
        //无符号

        int ip1=167776589;
        int ip2=167776412;
        System.out.println(ip1&ip2);

        int n5=5;
        double d5=1.2+24.0/n;
        System.out.println(d5);

        System.out.println();

        double aa=1.0;
        double bb=3.0;
        double cc=-4.0;
        double answer1=(-bb+Math.sqrt(bb*bb-4*aa*cc))/(2*aa);
        double answer2=(-bb-Math.sqrt(bb*bb-4*aa*cc))/(2*aa);
        System.out.println(answer1);
        System.out.println(answer2);
    }
}