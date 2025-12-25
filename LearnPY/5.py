spam=["cat","bat","rat","elephant"]
print(spam[0])
print(spam)
print(spam[-1])
print(spam[1:3])
print(spam[0:-1])
print(spam[:2])
print(len(spam))
spam[1]=91
print(spam)
tmp=[91,69]
print(spam+tmp)
temp=tmp
print(temp)
del spam[0]
print(spam)
catNames=[]
# while True:
#     print('Enter '+str(len(catNames)+1))
#     name=input()
#     if name=='':
#         break
#     catNames=catNames+[name]
# print('The cat names are:')
# for name in catNames:
#     print(name+' ')
supplies=['pens','staplers','flamethrowers','binders']
for index,item in enumerate(supplies):
    print(str(index)+' '+item)

import random
pets=['Dog','Cat','Moose']
print(random.choice(pets))
random.shuffle(pets)
print(pets)
spam=['hello','hi','howdy','heyas']
print(spam.index('hello'))
pets.append('Bat')
pets.insert(1,'Chicken')
print(pets)
pets.remove('Cat')
print(pets)
# pets.insert(1,'Chicken')
pets.insert(1,'Chicken')
pets.remove('Chicken')
# pets.remove('Chicken')
print(pets)
pets.sort()
print(pets)
spam=['a','z','A','Z']
spam.sort(key=str.lower)
print(spam)
print(pets)
pets.reverse()
print(pets)
print(type(('Hello',)))
print(type(('Hello')))
print(type((42)))
print(tuple(('cat','dog',5)))
print(list(['cat','dog',5]))
print(list('Hello'))

spam=[0,1,2,3,4]
cheese=spam
cheese[0]='Hello!'
print(spam)
print(id('Howdy'))
print(id(spam+cheese))
