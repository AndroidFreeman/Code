myCat={'size':'fat','color':'gray','disposition':'loud'}
print(myCat['size'])

# birthdays={'Alice':'Apr 1','Bob':'Dec 12','Carol':'Mar 4'}
# while True:
#     print('Enter a name: ')
#     name=input()
#     if name=='':
#         break
#     if name in birthdays:
#         print(birthdays[name]+' '+name)
#     else:
#         print('I do not know '+name)
#         print('Enter your birthday')
#         bday=input()
#         birthdays[name]=bday

eggs={'name':'Zophie','species':'cat','age':'8'}
print(list(eggs))
print(eggs)

for k in eggs.keys():
    print(k)
for v in eggs.values():
    print(v)
for i in eggs.items():
    print(i)

picnicItems={'apple':5,'cpus':2}
