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
while True:
    print('Enter '+str(len(catNames)+1))
    name=input()
    if name=='':
        break
    catNames=catNames+[name]
print('The cat names are:')
for name in catNames:
    print(name+' ')
