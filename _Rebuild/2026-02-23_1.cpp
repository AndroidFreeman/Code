#include <bits/stdc++.h>
using namespace std;
int main() {
    int n, k;
    if (!(cin >> n >> k)) return 0;
    vector<bool> lights(n + 1, false);

    for (int i = 1; i <= k; ++i) {
        for (int j = i; j <= n; j += i) {
            lights[j] = !lights[j];
        }
    }

    bool first = true;
    for (int i = 1; i <= n; ++i) {
        if (lights[i]) {
            if (!first) cout << " ";
            cout << i;
            first = false;
        }
    }
    cout << endl;
}