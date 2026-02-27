#include <bits/stdc++.h>
using namespace std;

int main() {
    int n;
    cin >> n;
    vector<vector<int>> ps;
    vector<int> s;
    s.push_back(1);
    ps.push_back(s);
    for (int i = 2; i <= n; i++) {
        vector<vector<int>> ps1;
        for (int j = 0; j < ps.size(); j++) {
            vector<int> cur = ps[j];
            for (int k = 0; k <= cur.size(); k++) {
                vector<int> next_p = cur;
                next_p.insert(next_p.begin() + k, i);
                ps1.push_back(next_p);
            }
        }
        ps = ps1;
    }
    for (int i = 0; i < ps.size(); i++) {
        for (int j = 0; j < n; j++) {
            cout << ps[i][j] << (j == n - 1 ? "" : " ");
        }
        cout << endl;
    }
    return 0;
}