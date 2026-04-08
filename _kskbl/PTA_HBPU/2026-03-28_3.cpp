#include <iostream>
#include <cstdio>

using namespace std;

int main() {
    int A, B;
    if (!(cin >> A >> B)) return 0;
    int target = A + B;
    int input;
    int current_second = 1;
    while (cin >> input) {
        if (input == target) {
            int h = current_second / 3600;
            int m = (current_second % 3600) / 60;
            int s = current_second % 60;
            printf("%d Accepted %02d:%02d:%02d\n", input, h, m, s);
            return 0;
        }
        if (current_second == 10799) {
            printf("%d Wrong Answer 02:59:59\n", input);
            return 0;
        }
        current_second += 2;
        if (current_second > 10800) break;
    }
}