def hello():
    print('Hi! Freeman!')
    print('I LOVE YOU FOREVER!!!')
hello()

def Hello(name):
    print('Hello, '+name+'! I LOVE YOU!!!')
Hello('Freeman')

import random

def getAnswer(answerNumber):
    if answerNumber==1:
        return 'It is certain!'
    elif answerNumber==2:
        return 'It is decidedly so'
    elif answerNumber==3:
        return 'Yes'
r=random.randint(1,3)
fortune=getAnswer(r)
print(fortune)

print('Hello',end=' ')
print('World')
print('Mitsubishi','Suzuki','Yamaha')
print('Mitsubishi','Suzuki','Yamaha',sep=',')

def spam():
    eggs=99
    bacon()
    print(eggs)
def bacon():
    ham=101
    eggs=0
spam()

def spam():
    eggs='spam local'
    print(eggs)
def bacon():
    eggs='bacon local'
    print(eggs)
    spam()
    print(eggs)
def change():
    global eggs
    eggs='changed'
eggs='global'
bacon()
change()
print(eggs)

import time,sys
# indent=0
# indentIncreasing=True
# try:
#     while True:
#         print(' '*indent,end='')
#         print('********')
#         time.sleep(0.1)
#         if indentIncreasing:
#             indent=indent+1
#             if indent==20:
#                 indentIncreasing=False
#         else:
#             indent=indent-1
#             if indent==0:
#                 indentIncreasing=True
# except KeyboardInterrupt:
#     sys.exit()






def countingStar():
    flag=True
    space=0;
    try:
        while True:
            print(' '*space,end='')
            print('********')
            time.sleep(0.1)
            if flag:
                space=space+1
                if space==20:
                    flag=False
            else:
                space=space-1
                if space==0:
                    flag=True
    except KeyboardInterrupt:
        sys.exit()
countingStar()

