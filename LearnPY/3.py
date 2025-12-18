#This program says hello and asks for my name.
print('Hello World!')
print('What is your name?')
myName=input()
print('It is good to meet you, '+myName)
print('The length of your name is: '+str(len(myName)))
# print(len(myName))
print('What is your age?')
myAge=20
print('You will be '+str(int(myAge)+1)+' in a year.')
# print(myName*5)

# name='Freeman'
# passwd='swordnewnew'
# if name=='Freeman':
#     print('Hello,Freeman')
#     if passwd=='swordnewnew':
#         print('Access granted.')
#     else:
#         print('Wrong passwd.')

while True:
    print('Who are you?')
    name=input()
    if name!='Freeman':
        print('Get away!')
        continue
    print('Hello Freeman! passwd pls')
    passwd=input()
    if passwd!='swordnewnew':
        print('Get away!')
    else:
        break
print('Access granted')
