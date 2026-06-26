import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('sqflite_ffi works', () async {
    final db = await openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY)');
    await db.insert('test', {'id': 1});
    final result = await db.query('test');
    expect(result.length, 1);
    await db.close();
  });
}
