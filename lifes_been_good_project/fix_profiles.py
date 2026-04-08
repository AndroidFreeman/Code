import re

def fix():
    with open('lib/services/local_profiles.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Public methods adding nativeLibDir
    content = re.sub(r'static Future<String\?> ensureStudentAccountByTeacher\(\{(.*?)\}\) async \{', r'static Future<String?> ensureStudentAccountByTeacher({\1, String? nativeLibDir}) async {', content, flags=re.DOTALL)
    content = re.sub(r'static Future<String> loadStudentPosition\(\{(.*?)\}\) async \{', r'static Future<String> loadStudentPosition({\1, String? nativeLibDir}) async {', content, flags=re.DOTALL)
    content = re.sub(r'static Future<List<String>> getTeacherClasses\(\s*String dataDir, String profileId\) async \{', r'static Future<List<String>> getTeacherClasses(\n      String dataDir, String profileId, {String? nativeLibDir}) async {', content)
    content = re.sub(r'static Future<List<String>> getAllClasses\(String dataDir\) async \{', r'static Future<List<String>> getAllClasses(String dataDir, {String? nativeLibDir}) async {', content)
    content = re.sub(r'static Future<void> addTeacherClass\(\s*String dataDir, String profileId, String newClass\) async \{', r'static Future<void> addTeacherClass(\n      String dataDir, String profileId, String newClass, {String? nativeLibDir}) async {', content)
    content = re.sub(r'static Future<void> removeTeacherClass\(\s*String dataDir, String profileId, String classCode\) async \{', r'static Future<void> removeTeacherClass(\n      String dataDir, String profileId, String classCode, {String? nativeLibDir}) async {', content)
    content = re.sub(r'static Future<void> updateProfile\(\{(.*?)\}\) async \{', r'static Future<void> updateProfile({\1, String? nativeLibDir}) async {', content, flags=re.DOTALL)
    content = re.sub(r'static Future<void> updatePassword\(\{(.*?)\}\) async \{', r'static Future<void> updatePassword({\1, String? nativeLibDir}) async {', content, flags=re.DOTALL)
    content = re.sub(r'static Future<Profile> login\(\{(.*?)\}\) async \{', r'static Future<Profile> login({\1, String? nativeLibDir}) async {', content, flags=re.DOTALL)
    content = re.sub(r'static Future<Profile> register\(\{(.*?)\}\) async \{', r'static Future<Profile> register({\1, String? nativeLibDir}) async {', content, flags=re.DOTALL)
    content = re.sub(r'static Future<void> saveAutoLogin\(\{(.*?)\}\) async \{', r'static Future<void> saveAutoLogin({\1, String? nativeLibDir}) async {', content, flags=re.DOTALL)
    content = re.sub(r'static Future<void> clearAutoLogin\(String dataDir\) async \{', r'static Future<void> clearAutoLogin(String dataDir, {String? nativeLibDir}) async {', content)
    content = re.sub(r'static Future<Profile\?> loadAutoLoginProfile\(\{(.*?)\}\) async \{', r'static Future<Profile?> loadAutoLoginProfile({\1, String? nativeLibDir}) async {', content, flags=re.DOTALL)

    # Internal calls
    content = re.sub(r'final rows = await _readRows\(dataDir\);', r'final rows = await _readRows(dataDir, nativeLibDir: nativeLibDir);', content)
    content = re.sub(r'final rows = await _readRowsFromFile\(dataDir, \'students.csv\'\);', r'final rows = await _readRowsFromFile(dataDir, \'students.csv\', nativeLibDir: nativeLibDir);', content)
    content = re.sub(r'final sRows = await _readRowsFromFile\(dataDir, \'students.csv\'\);', r'final sRows = await _readRowsFromFile(dataDir, \'students.csv\', nativeLibDir: nativeLibDir);', content)
    
    content = re.sub(r'await _writeRows\(dataDir, \'profiles.csv\', headers, rows\);', r'await _writeRows(dataDir, \'profiles.csv\', headers, rows, nativeLibDir: nativeLibDir);', content)
    content = re.sub(r'await _writeRows\(dataDir, \'students.csv\', sHeaders, sRows\);', r'await _writeRows(dataDir, \'students.csv\', sHeaders, sRows, nativeLibDir: nativeLibDir);', content)

    content = re.sub(r'final features = NativeFeatures\(dataDir: dataDir\);', r'final features = NativeFeatures(dataDir: dataDir, nativeLibDir: nativeLibDir);', content)

    with open('lib/services/local_profiles.dart', 'w', encoding='utf-8') as f:
        f.write(content)

fix()