import os

f = 'lib/pages/contacts_page.dart'
with open(f, 'r', encoding='utf-8') as file:
    content = file.read()

content = content.replace("if (p.bio.isNotEmpty)", "if (p.signature.isNotEmpty)")
content = content.replace("p.bio,", "p.signature,")

with open(f, 'w', encoding='utf-8') as file:
    file.write(content)
