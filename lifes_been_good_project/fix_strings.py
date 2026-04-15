import sys

def process_file(f_path):
    with open(f_path, 'r', encoding='utf-8') as f:
        text = f.read()

    # replace out.join('\n') + '\n' with '${out.join('\n')}\n'
    text = text.replace("out.join('\\n') + '\\n'", "'${out.join('\\n')}\\n'")
    
    # replace DateTime.now().toUtc().toIso8601String().split('.').first + 'Z' 
    # with '${DateTime.now().toUtc().toIso8601String().split('.').first}Z'
    text = text.replace("DateTime.now().toUtc().toIso8601String().split('.').first + 'Z'", "'${DateTime.now().toUtc().toIso8601String().split('.').first}Z'")

    with open(f_path, 'w', encoding='utf-8') as f:
        f.write(text)

process_file('lib/services/local_profiles.dart')
process_file('lib/services/todos_store.dart')
