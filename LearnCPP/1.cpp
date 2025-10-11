#include<iostream>
using namespace std;             //WHY UNS
class MyClass{
    public:static int class_var; //WHY PUBLIC:STATIC
};
int MyClass::class_var=100;
int main(){
    cout<<"Hello,World!"<<endl;
    int i=10;
    float f=static_cast<float>(i)+0.01;
    int j=static_cast<int>(f);
    cout<<i<<"  "<<f<<"  \a"<<j<<endl;
    cout<<MyClass::class_var<<endl;
    auto f=3.14;
}
