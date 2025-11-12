class FreshJuice{
    enum FreshJuiceSize{SMALL,MEDIUM,LARGE}
    FreshJuiceSize size;
}


public class a{
    public static void main(String[] args){
//访问修饰,关键字,返回类型,方法名,string类,字符串数组
        System.out.println("Hello Java");
        FreshJuice juice=new FreshJuice();
        juice.size=FreshJuice.FreshJuiceSize.MEDIUM;
    }
}
