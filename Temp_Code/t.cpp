#include <bits/stdc++.h>
using namespace std;
int main()
{
    int number;
        number = 3;
        vector<int> numberList = {0};
        vector<vector<int>> answer;
        numberList.push_back(1);
        answer.push_back({1});
        for (int i = 2; i <= number; i++)
    {
                numberList.push_back(i);
                answer.push_back(numberList);
                for (int j = 0; j < sizeof(numberList); j++)
        {
                        swap(numberList[i], numberList[i - 1]);
                        answer.push_back(numberList);
                   
        }
           
    }
        int length = sizeof(answer);
        for (int i = 0; i < length; i++)
    {
                cout << answer[i] << endl;
           
    }
}