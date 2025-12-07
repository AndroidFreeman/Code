print("hello")
message="hello!"
print(message)
print(message.title())
tmp="\"ni ma ma\""
print(tmp.title())
#首字母大写
print(tmp.upper())
#字母全大写
print(tmp.lower())
#字母全小写
full=f"{message} {tmp} {message}"
print(full)
full=f" {message.title()} {tmp.upper()} "
print("full\tfull")
print(full.rstrip())
#删除右端的空格
print(full.lstrip())
#删除左端的空格
print(full.strip())
#删除两端的空格
url='https://blog.freemanserver.top'
print(url.removeprefix('https://'))
#删除前缀
file='csndm.otto'
print(file.removesuffix('.otto'))
#删除后缀
print(5**5)
#乘方运算
x,y,z=1,2,3
print(x,y,z)
WOCE=100
#没有常亮

#List列表
love=['h','q','y']
print(love[0],love[1],love[2])
tmp=f"Hello {love[0].title()}{love[1].title()}{love[2].title()}"
print(tmp)
motocycles=['honda','yamaha','suzuki']
print(motocycles)
motocycles[0]='ducati'
#列表变量替换
print(motocycles)
motocycles.append('honda')
#列表末尾加入
print(motocycles)
motocycles.insert(0,'CF')
#列表插入
print(motocycles)
del motocycles[0]
#列表删除
print(motocycles)
popped_motocycle=motocycles.pop()
#列表弹出(列表就像一个栈)
print(motocycles)
print(popped_motocycle)
motocycles.remove('ducati')
#直接删除
print(motocycles)
moto=['honda','yamaha','suzuki','ducati']
too_expensive='ducati'
moto.remove(too_expensive)
print(f"A {too_expensive.title()} is too expensive for me.")

###管理列表
cars=['bmw','audi','toyota','subaru']
cars.sort()
#排序
print(cars)
cars.sort(reverse=True)
#排序->倒叙
print(cars)
cars=['bmw','audi','toyota','subaru']
cars.reverse()
#倒叙
print(cars)
print(len(cars))
#长度
print(cars[-1])
#从右至左

mag=['alice','david','carolina']
for i in mag:
    print(f"{i.title()}, that was great")
#for循环
for i in range(2,5,2):
    print(i)
#range()生成一系列的数字
#起点,终点,加数

squares=[]
for i in range(1,11):
    square=i**2
    squares.append(square)
print(squares)
#两者相同
square=[i**2 for i in range(1,11)]
print(square)

print(min(squares))
print(max(squares))
print(sum(squares))
#最大最小总和
print(squares[0:5])
print(squares[:5])
print(squares[6:])
print(squares[-4:])
#切片,起点:终点

my_food=['pizza','falafel','carror cake']
friend_food=my_food[:]
my_food.append('cannoli')
friend_food.append('ice cream')
print(my_food)
print(friend_food)

dim=(200,50)
print(dim[0],dim[1])
dim=(400,100)
print(dim[0],dim[1])
#元组元素不可变,元组可变

cars=['audi','bmw','subaru','toyota']
for car in cars:
    if car=='bmw':
        print(car.upper())
    else:
        print(car.title())

requested_topping='mushrooms'
if requested_topping != 'anchovies':
    print("Hold the anchovies!")
answer=17
if answer!=42:
    print("That is not the answer.")
print(9 in square)
banned_user=['andrew','carolina','david']
user='maria'
if user not in banned_user:
    print(f"{user.title()},you can post a response.")
game_active=True
can_ediy=False
age=19
if age>=18:
    print("You are old enough to vote!")
elif age>60:
    print("Sorry,you are too old to vote.")
else:
    print("Sorry,you are too young.")
available_toppings=['mushrooms','olives',
                    'green peppers']
requested_toppings=['mushrooms','jb','big jb']
for requested_topping in requested_toppings:
    if requested_topping in available_toppings:
        print(f"Adding {requested_topping}.")
    else:
        print(f"Sorry, we don't have {requested_topping}.")
print("Finished making your pizza!")

#字典
alien_0={'color':'green','points':5}
print(alien_0['color'])
print(alien_0['points'])
print(alien_0)
alien_0['x_position']=0
alien_0['y_position']=25
print(alien_0)
alien_0['points']=100
print(alien_0)
del alien_0['color']
print(alien_0)
point_value=alien_0.get('color','NP')
print(point_value)
point_value=alien_0.get('points','NP')
print(point_value)
