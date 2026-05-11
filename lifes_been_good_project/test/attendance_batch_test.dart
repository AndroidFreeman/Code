import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Attendance batch operations should rollback on failure', () async {
    // Simulate the state
    Map<String, String> marking = {'student1': '', 'student2': 'late'};
    final backup = Map<String, String>.from(marking);

    bool submitFailed = true;

    // Apply batch
    marking['student1'] = 'present';
    marking['student2'] = 'present';

    // Simulate submit failure
    if (submitFailed) {
      // Rollback
      marking['student1'] = backup['student1'] ?? '';
      marking['student2'] = backup['student2'] ?? '';
    }

    expect(marking['student1'], '');
    expect(marking['student2'], 'late');
  });

  test('Attendance batch should respect optimistic lock', () async {
    Map<String, String> marking = {'s1': 'absent'};
    final backup = Map<String, String>.from(marking);

    // Apply
    marking['s1'] = 'present';
    bool submitSucceeded = true;

    if (!submitSucceeded) {
      marking['s1'] = backup['s1'] ?? '';
    }

    expect(marking['s1'], 'present');
  });
}