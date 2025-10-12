#include<iostream>
using namespace std;

class printData{
    public:
        void print(int i){
            cout<<"int:"<<i<<endl;
        }
        void print(double f){
            cout<<"float:"<<f<<endl;
        }
        void print(char c[]){
            cout<<"string:"<<c<<endl;
        }
};

int main(){
    printData pd;
    pd.print(5);
    pd.print(5.5);
    char c[]="Hello!";
    pd.print(c);
}
