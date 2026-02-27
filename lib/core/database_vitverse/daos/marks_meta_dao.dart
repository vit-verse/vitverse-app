import 'package:sqflite/sqflite.dart';

class MarksMetaDao {
  final Database _db;

  MarksMetaDao(this._db);

  Future<void> saveReadSignature(int signature) async {
    await _db.insert('marks_read', {
      'signature': signature,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveReadSignatures(List<int> signatures) async {
    if (signatures.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      for (final sig in signatures) {
        await txn.insert('marks_read', {
          'signature': sig,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> saveAverage(int identityKey, double average) async {
    await _db.insert('marks_avg', {
      'identity_key': identityKey,
      'average': average,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Set<int>> getReadSignatures() async {
    final rows = await _db.query('marks_read');
    return rows.map((r) => r['signature'] as int).toSet();
  }

  Future<Map<int, double>> getAverages() async {
    final rows = await _db.query('marks_avg');
    return {
      for (final r in rows)
        r['identity_key'] as int: (r['average'] as num).toDouble(),
    };
  }

  Future<void> deleteAll() async {
    await _db.delete('marks_read');
    await _db.delete('marks_avg');
  }
}
