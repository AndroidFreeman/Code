import re

f = 'lib/pages/class_students_page.dart'
with open(f, 'r', encoding='utf-8') as file:
    content = file.read()

content = content.replace("final avatarPath = _avatars[s.studentNo] ?? '';", "final String avatarPath = _avatars[s.studentNo] as String? ?? '';")

with open(f, 'w', encoding='utf-8') as file:
    file.write(content)
