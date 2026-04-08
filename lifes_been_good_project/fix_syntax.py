import os
import re

files_to_fix = [
    'lib/pages/todos_page.dart',
    'lib/pages/contacts_page.dart',
    'lib/pages/attendance_page.dart',
    'lib/pages/class_students_page.dart',
    'lib/pages/class_attendance_overview_page.dart'
]

for f in files_to_fix:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Original logic replaced: scaffold?.openDrawer(); },) : const SizedBox.shrink(),
    # Looking at the code in attendance_page.dart:
    #         scaffold?.openDrawer();
    #       },
    #     );
    #   },
    # ),
    # Let's fix it by adding the proper closing braces.
    content = content.replace("scaffold?.openDrawer(); },) : const SizedBox.shrink(),", "scaffold?.openDrawer();\n              },\n            );\n          },\n        ) : const SizedBox.shrink(),")
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)
