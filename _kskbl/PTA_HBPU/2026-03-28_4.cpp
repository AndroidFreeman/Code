#include <iostream>
#include <cmath>

using namespace std;
bool isPrime(int x) {
    if (x < 2) return false;
    for (int i = 2; i * i <= x; i++) {
        if (x % i == 0) return false;
    }
    return true;
}

int reverseNum(int x) {
    int res = 0;
    while (x > 0) {
        res = res * 10 + x % 10;
        x /= 10;
    }
    return res;
}

int main() {
    int n, k;
    if (!(cin >> n >> k)) return 0;

    int foundCount = 0; // 记录找到的反素数个数
    int current = n;    // 从输入的 n 开始往后找

    while (foundCount < k) {
        // 1. 先看当前数是不是素数
        if (isPrime(current)) {
            int rev = reverseNum(current);
            // 2. 核心判断：不是回文数 && 翻转后依然是素数
            if (current != rev && isPrime(rev)) {
                cout << current << endl;
                foundCount++; // 达成目标，计数加一
            }
        }
        current++; // 继续考察下一个数
    }

    return 0;
}