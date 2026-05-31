import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_been_good_system/models/todo_item.dart';

void main() {
  test('TodoItems are sorted by dueAt ascending, then createdAt descending',
      () {
    final items = [
      TodoItem(
        id: '1',
        ownerProfileId: 'test',
        folder: '默认',
        title: 'Task 1 (No due date)',
        isDone: false,
        dueAt: '',
        createdAt: '2023-01-01T10:00:00.000',
        updatedAt: '2023-01-01T10:00:00.000',
      ),
      TodoItem(
        id: '2',
        ownerProfileId: 'test',
        folder: '默认',
        title: 'Task 2 (Due soon)',
        isDone: false,
        dueAt: '2023-12-01 10:00',
        createdAt: '2023-01-02T10:00:00.000',
        updatedAt: '2023-01-02T10:00:00.000',
      ),
      TodoItem(
        id: '3',
        ownerProfileId: 'test',
        folder: '默认',
        title: 'Task 3 (Due later)',
        isDone: false,
        dueAt: '2023-12-05 10:00',
        createdAt: '2023-01-03T10:00:00.000',
        updatedAt: '2023-01-03T10:00:00.000',
      ),
      TodoItem(
        id: '4',
        ownerProfileId: 'test',
        folder: '默认',
        title: 'Task 4 (Done)',
        isDone: true,
        dueAt: '2023-11-01 10:00',
        createdAt: '2023-01-04T10:00:00.000',
        updatedAt: '2023-01-04T10:00:00.000',
      ),
      TodoItem(
        id: '5',
        ownerProfileId: 'test',
        folder: '默认',
        title: 'Task 5 (No due date, newer)',
        isDone: false,
        dueAt: '',
        createdAt: '2023-01-05T10:00:00.000',
        updatedAt: '2023-01-05T10:00:00.000',
      ),
    ];

    items.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      final aDue = a.dueAt.trim().isEmpty ? '9999-12-31' : a.dueAt;
      final bDue = b.dueAt.trim().isEmpty ? '9999-12-31' : b.dueAt;
      final timeCmp = aDue.compareTo(bDue);
      if (timeCmp != 0) return timeCmp;
      return b.createdAt.compareTo(a.createdAt);
    });

    // Expected order:
    // 1. Task 2 (Due soon)
    // 2. Task 3 (Due later)
    // 3. Task 5 (No due date, newer)
    // 4. Task 1 (No due date)
    // 5. Task 4 (Done)

    expect(items[0].id, '2');
    expect(items[1].id, '3');
    expect(items[2].id, '5');
    expect(items[3].id, '1');
    expect(items[4].id, '4');
  });
}
