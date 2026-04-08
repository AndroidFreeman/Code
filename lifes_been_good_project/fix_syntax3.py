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
    
    # We accidentally left extra closing braces inside the replacement.
    # The current string in the file is:
    pattern = r"leading:\s*showDrawerButton\s*\?\s*Builder\(\s*builder:\s*\(context\)\s*\{\s*return\s*IconButton\(\s*icon:\s*const\s*Icon\(Icons\.menu\),\s*onPressed:\s*\(\)\s*\{\s*ScaffoldState\?\s*scaffold\s*=\s*Scaffold\.maybeOf\(context\);\s*if\s*\(scaffold\s*!=\s*null\s*&&\s*!scaffold\.hasDrawer\)\s*\{\s*scaffold\s*=\s*scaffold\.context\s*\.findAncestorStateOfType<ScaffoldState>\(\);\s*\}\s*scaffold\?\.openDrawer\(\);\s*\}\,\s*\);\s*\}\,\s*\)\s*(:\s*const\s*SizedBox\.shrink\(\))?,"
    
    replacement = """leading: showDrawerButton ? Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                ScaffoldState? scaffold = Scaffold.maybeOf(context);
                if (scaffold != null && !scaffold.hasDrawer) {
                  scaffold = scaffold.context
                      .findAncestorStateOfType<ScaffoldState>();
                }
                scaffold?.openDrawer();
              },
            );
          },
        ) : const SizedBox.shrink(),"""
    
    content = re.sub(pattern, replacement, content)
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)

