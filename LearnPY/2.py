name='Freeman'
# name=input('Please enter your name:')
print('Hello',name)
print(3840*2160/1920/1080)
a=10
if a>=0:
    print(a)
else:
    print(-a)
a='ABC'
b=a
a='XYZ'
print(b)
print(10//3)
print(999*999)
print('Hi,%s you have $%d.'%('Freeman',1000000000))
r=2.5
s=3.14*r**2
print(f'The area of a circle with radius {r} is {s:.2f}')
classmate=['Michael','Bob']
print(classmate)
print(len(classmate))
classmate.append('Freeman')
classmate.insert(2,'Android')
print(classmate)
print(classmate.pop())
print(classmate[2])
classmates=('Michael','Bob')

L = [
    ['Apple', 'Google', 'Microsoft'],
    ['Java', 'Python', 'Ruby', 'PHP'],
    ['Adam', 'Bart', 'Bob']
]
# 打印Apple:
print(L[0][0])
# 打印Python:
print(L[1][1])
# 打印Bob:
print(L[2][2])

age=20
if age>=18:
    print('Your age is',age)
    print('Adult')
else:
    print('Your age is',age)
    print('Teenager')

s=input('birth:')
birth=int(s)
if birth<2000:
    print('Before 2000')
else:
    print('After 2000')

args=['gcc','hello.c','world.c']
match args:
    case['gcc']:
        print('gcc:missing source file(s).')
    case['gcc',file1,*files]:
        print('gcc compile: '+file1+','+','.join(files))
    case _:
        print('invalid command.')
