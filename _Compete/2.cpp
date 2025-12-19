#include <iostream>

using namespace std;

int main() {
    // A 和 E 作为首位数字，不能为 0
    for (int a = 1; a <= 9; a++) {
        for (int b = 0; b <= 9; b++) {
            if (b == a) continue;
            for (int c = 0; c <= 9; c++) {
                if (c == a || c == b) continue;
                for (int d = 0; d <= 9; d++) {
                    if (d == a || d == b || d == c) continue;
                    for (int e = 1; e <= 9; e++) {
                        if (e == a || e == b || e == c || e == d) continue;

                        int original = a * 10000 + b * 1000 + c * 100 + d * 10 + e;
                        int reversed = e * 10000 + d * 1000 + c * 100 + b * 10 + a;

                        // 枚举问号代表的数字 k (2 到 9 之间)
                        for (int k = 2; k <= 9; k++) {
                            if (original * k == reversed) {
                                cout << "找到结果：" << endl;
                                cout << "ABCDE = " << original << endl;
                                cout << "问号 = " << k << endl;
                                cout << "算式: " << original << " x " << k << " = " << reversed << endl;
                            }
                        }
                    }
                }
            }
        }
    }
}
