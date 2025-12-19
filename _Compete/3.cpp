#include <iostream>
using namespace std;
int main() {
    // a, b, c, d 分别代表四轮喝酒时的人数
    // a 为初始人数，不超过 20
    for (int a = 20; a >= 4; a--) {
        for (int b = a - 1; b >= 3; b--) {
            for (int c = b - 1; c >= 2; c--) {
                for (int d = c - 1; d >= 1; d--) {
                    // 使用整数运算判断 1/a + 1/b + 1/c + 1/d == 1
                    long long left = (long long)b * c * d + (long long)a * c * d +
                                     (long long)a * b * d + (long long)a * b * c;
                    long long right = (long long)a * b * c * d;
                    if (left == right) {
                        cout << a << "," << b << "," << c << "," << d << ",0" << endl;
                    }
                }
            }
        }
    }
}
