import 'package:sqflite/sqflite.dart';

import '../../models/meta.dart';
import 'database_helper.dart';

abstract class MetaLocalDatasource {
  Future<void> salvarOuAtualizar(Meta meta);
  Future<List<Meta>> listarPorUsuario(int usuarioId);
  Future<List<Meta>> listarPendentes(int usuarioId);
  Future<Meta?> buscarPorId(String id);
  Future<void> removerPorId(String id);
}

class MetaSqfliteDatasource implements MetaLocalDatasource {
  MetaSqfliteDatasource({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  @override
  Future<void> salvarOuAtualizar(Meta meta) async {
    final db = await _helper.database;
    await db.insert(
      'metas',
      meta.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Meta>> listarPorUsuario(int usuarioId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'metas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'data_criacao DESC',
    );
    return rows.map(Meta.fromMap).toList();
  }

  @override
  Future<List<Meta>> listarPendentes(int usuarioId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'metas',
      where: 'usuario_id = ? AND sincronizado = 0',
      whereArgs: [usuarioId],
    );
    return rows.map(Meta.fromMap).toList();
  }

  @override
  Future<Meta?> buscarPorId(String id) async {
    final db = await _helper.database;
    final rows = await db.query('metas', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Meta.fromMap(rows.first);
  }

  @override
  Future<void> removerPorId(String id) async {
    final db = await _helper.database;
    await db.delete('metas', where: 'id = ?', whereArgs: [id]);
  }
}
