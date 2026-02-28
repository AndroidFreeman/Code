#include <bits/stdc++.h>
using namespace std;

struct Item
{
    int id;
    int weight;
    int value;
    float priority;
};

bool compare(Item a, Item b)
{
    return a.priority > b.priority;
}

int main()
{
    int number = 4;
    int weightMax = 6;
    vector<int> weights = {5, 3, 2, 1};
    vector<int> values = {4, 4, 3, 1};
    vector<Item> items;

    for (int i = 0; i < number; i++)
    {
        float p = (float)values[i] / weights[i];
        items.push_back({i + 1, weights[i], values[i], p});
    }
    sort(items.begin(), items.end(), compare);

    int weightTotal = 0, valueTotal = 0;
    vector<int> itemNow;
    for (int i = 0; i < number; i++)
    {
        if (weightTotal + items[i].weight <= weightMax)
        {
            weightTotal += items[i].weight;
            valueTotal += items[i].value;
            itemNow.push_back(items[i].id);
        }
    }

    cout << "The winner is: ";
    for (int id : itemNow)
    {
        cout << id << " ";
    }
    cout << endl;
    cout << "Total weight: " << weightTotal << endl;
    cout << "Total value: " << valueTotal << endl;
}