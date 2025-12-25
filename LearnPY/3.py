# #This program says hello and asks for my name.
# print('Hello World!')
# print('What is your name?')
# myName=input()
# print('It is good to meet you, '+myName)
# print('The length of your name is: '+str(len(myName)))
# # print(len(myName))
# print('What is your age?')
# myAge=20
# print('You will be '+str(int(myAge)+1)+' in a year.')
# # print(myName*5)

# # name='Freeman'
# # passwd='swordnewnew'
# # if name=='Freeman':
# #     print('Hello,Freeman')
# #     if passwd=='swordnewnew':
# #         print('Access granted.')
# #     else:
# #         print('Wrong passwd.')

# # while True:
# #     print('Who are you?')
# #     name=input()
# #     if name!='Freeman':
# #         print('Get away!')
# #         continue
# #     print('Hello Freeman! passwd pls')
# #     passwd=input()
# #     if passwd!='swordnewnew':
# #         print('Get away!')
# #     else:
# #         break
# # print('Access granted')

# print('My name is')
# for i in range(5):
#     print('Jimmy Five Times (' +str(i)+ ')')
# i=0
# while i<5:
#     print('Jimmy Five Times ('+str(i)+')')
#     i=i+1
# for i in range(12,16):
#     print(i)
# for i in range(0,10,2):
#     print(i)
# for i in range(5,-1,-1):
#     print(i)
# import random
# for i in range(5):
#     print(random.randint(1,10))
# import sys
# while True:
#     print('Type exit to exit')
#     response='exit'
#     # if response=='exit':
#     #     sys.exit()
#     print('You typed '+ response +'.')

# import random
# secretNumber=random.randint(1,100)
# print('You need to guess a number 1-100')

# for guessesTaken in range(1,7):
#     print('Take a guess')
#     guess=int(input())
#     if guess<secretNumber:
#         print('Your guess is too low')
#     elif guess>secretNumber:
#         print('Your guess is too high')
#     else:
#         break
# if guess == secretNumber:
#     print('Good job!')
# else:
#     print('No')

# print('Another game')

import sys
import random

print('Rock, Paper, Scissors')

wins = 0
losses = 0
ties = 0

while True:
    # 打印当前战绩
    print('%s Wins, %s Losses, %s Ties' % (wins, losses, ties))

    while True:
        print('Enter your move: (r)ock (p)aper (s)cissors or (q)uit')
        playerMove = input()
        if playerMove == 'q':
            sys.exit()
        if playerMove == 'r' or playerMove == 'p' or playerMove == 's':
            break
        print('Type one of r, p, s, or q.')

    # 显示玩家选择
    if playerMove == 'r':
        print('ROCK versus...')
    elif playerMove == 'p':
        print('PAPER versus...')
    elif playerMove == 's':
        print('SCISSORS versus...')

    # 电脑随机出拳
    randomNumber = random.randint(1, 3)
    if randomNumber == 1:
        computerMove = 'r'
        print('ROCK')
    elif randomNumber == 2:
        computerMove = 'p'
        print('PAPER')
    elif randomNumber == 3:
        computerMove = 's'
        print('SCISSORS')

    # 结果判定
    if playerMove == computerMove:
        print('It is a tie!')
        ties = ties + 1
    elif (playerMove == 'r' and computerMove == 's') or \
         (playerMove == 'p' and computerMove == 'r') or \
         (playerMove == 's' and computerMove == 'p'):
        print('You win!')
        wins = wins + 1
    else:
        print('You lose!')
        losses = losses + 1
