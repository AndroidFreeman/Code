import re

f = 'lib/pages/contacts_page.dart'
with open(f, 'r', encoding='utf-8') as file:
    content = file.read()

replacement = """
                _buildProfileItem(Icons.person_outline, loc.t('昵称', 'Nickname'), p.displayName, cs, tt),
                _buildProfileItem(Icons.badge_outlined, loc.t('名字', 'Name'), p.realName.isEmpty ? p.displayName : p.realName, cs, tt),
                _buildProfileItem(
                    p.role == 'teacher' ? Icons.badge_outlined : Icons.badge_outlined,
                    p.role == 'teacher' ? loc.t('工号', 'Staff No.') : loc.t('学号', 'Student No.'),
                    p.role == 'teacher' ? p.staffNo : p.studentNo,
                    cs,
                    tt),
                if (p.role != 'teacher')
                  _buildProfileItem(Icons.class_outlined, loc.t('班级', 'Class'), p.classCode, cs, tt),
                if (p.dorm.isNotEmpty)
                  _buildProfileItem(Icons.apartment_outlined, loc.t('寝室号', 'Dormitory'), p.dorm, cs, tt),
                if (p.phone.isNotEmpty)
                  _buildProfileItem(Icons.phone_outlined, loc.t('电话号', 'Phone'), p.phone, cs, tt),
                if (p.signature.isNotEmpty)
                  _buildProfileItem(Icons.edit_note_outlined, loc.t('个性签名', 'Bio'), p.signature, cs, tt),
"""

content = re.sub(r"_buildProfileItem\(Icons\.person_outline, loc\.t\('姓名', 'Name'\), p\.fullName, cs, tt\),\s*_buildProfileItem\(\s*p\.role == 'teacher' \? Icons\.badge_outlined : Icons\.badge_outlined,\s*p\.role == 'teacher' \? loc\.t\('工号', 'Staff No\.'\) : loc\.t\('学号', 'Student No\.'\),\s*p\.role == 'teacher' \? p\.staffNo : p\.studentNo,\s*cs,\s*tt\),\s*if \(p\.role != 'teacher'\)\s*_buildProfileItem\(Icons\.class_outlined, loc\.t\('班级', 'Class'\), p\.classCode, cs, tt\),\s*if \(p\.dormNumber\.isNotEmpty\)\s*_buildProfileItem\(Icons\.apartment_outlined, loc\.t\('寝室号', 'Dormitory'\), p\.dormNumber, cs, tt\),\s*if \(p\.phone\.isNotEmpty\)\s*_buildProfileItem\(Icons\.phone_outlined, loc\.t\('电话', 'Phone'\), p\.phone, cs, tt\),", replacement, content, flags=re.DOTALL)

with open(f, 'w', encoding='utf-8') as file:
    file.write(content)

