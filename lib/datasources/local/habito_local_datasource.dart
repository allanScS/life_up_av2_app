import 'package:sqflite/sqflite.dart';

import '../../models/habito.dart';
import 'database_helper.dart';

abstract class HabitoLocalDatasource {
  Future<void> salvarOuAtualizar(Habito habito);
  Future<List<Habito>> listarPorUsuario(int usuarioId);
  Future<List<Habito>> listarPendentes(int usuarioId);
  Future<Habito?> buscarPorId(String id);
  Future<void> removerPorId(String id);
  Future<void> marcarSincronizado(String id, {required bool sincronizado});
}

class HabitoSqfliteDatasource implements HabitoLocalDatasource {
  HabitoSqfliteDatasource({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  @override
  Future<void> salvarOuAtualizar(Habito habito) async {
    final db = await _helper.database;
    await db.insert(
      'habitos',
      habito.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Habito>> listarPorUsuario(int usuarioId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'habitos',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'data_criacao DESC',
    );
    return rows.map(Habito.fromMap).toList();
  }

  @override
  Future<List<Habito>> listarPendentes(int usuarioId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'habitos',
      where: 'usuario_id = ? AND sincronizado = 0',
      whereArgs: [usuarioId],
    );
    return rows.map(Habito.fromMap).toList();
  }

  @override
  Future<Habito?> buscarPorId(String id) async {
    final db = await _helper.database;
    final rows = await db.query('habitos', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Habito.fromMap(rows.first);
  }

  @override
  Future<void> removerPorId(String id) async {
    final db = await _helper.database;
    await db.delete('habitos', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> marcarSincronizado(String id, {required bool sincronizado}) async {
    final db = await _helper.database;
    await db.update(
      'habitos',
      {'sincronizado': sincronizado ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
