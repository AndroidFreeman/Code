#include <iostream>
using namespace std;
int main() {
    int cock, hen, chick;
    for (cock = 1; cock < 20; cock++) {
        for (hen = 1; hen < 33; hen++) {
            chick = 100 - cock - hen;
            if (chick > 0 && chick % 3 == 0) {
                if (5 * cock + 3 * hen + chick / 3 == 100) {
                    cout << "公鸡: " << cock 
                         << " 只, 母鸡: " << hen 
                         << " 只, 小鸡: " << chick << " 只" << endl;
                }
            }
        }
    }
}