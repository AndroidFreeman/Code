import 'dart:io';

void main() {
  final dir = Directory('lib/pages');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    
    // Remove if (_loading) Positioned LinearProgressIndicator
    final pattern1 = RegExp(r'if\s*\(_loading\)\s*const\s*Positioned\(\s*top:\s*0,\s*left:\s*0,\s*right:\s*0,\s*child:\s*LinearProgressIndicator\(\),\s*\),?', multiLine: true);
    content = content.replaceAll(pattern1, '');

    // Replace RefreshIndicator(onRefresh: _refresh, child: X) with X
    final pattern2 = RegExp(r'RefreshIndicator\(\s*onRefresh:\s*_refresh,\s*child:\s*(AnimatedSwitcher[\s\S]*?),\s*\)\s*,', multiLine: true);
    // Actually, RefreshIndicator can wrap different things. Let's just find RefreshIndicator(onRefresh: _refresh, child: 
    // It's safer to do this with simple string replacement if we know the structure.
    
    // Instead of regex for nested parens, let's do a simple string replacement for the specific files.
    file.writeAsStringSync(content);
  }
}
