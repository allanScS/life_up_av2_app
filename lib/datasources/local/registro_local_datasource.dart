import 'package:sqflite/sqflite.dart';

import '../../models/registro.dart';
import 'database_helper.dart';

abstract class RegistroLocalDatasource {
  Future<void> salvarOuAtualizar(Registro registro);
  Future<List<Registro>> listarPorUsuario(int usuarioId);
  Future<List<Registro>> listarPendentes(int usuarioId);
  Future<Registro?> buscarPorId(String id);
  Future<void> removerPorId(String id);
}

class RegistroSqfliteDatasource implements RegistroLocalDatasource {
  RegistroSqfliteDatasource({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  @override
  Future<void> salvarOuAtualizar(Registro registro) async {
    final db = await _helper.database;
    await db.insert(
      'registros',
      registro.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Registro>> listarPorUsuario(int usuarioId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'registros',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'data_registro DESC',
    );
    return rows.map(Registro.fromMap).toList();
  }

  @override
  Future<List<Registro>> listarPendentes(int usuarioId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'registros',
      where: 'usuario_id = ? AND sincronizado = 0',
      whereArgs: [usuarioId],
    );
    return rows.map(Registro.fromMap).toList();
  }

  @override
  Future<Registro?> buscarPorId(String id) async {
    final db = await _helper.database;
    final rows = await db.query('registros', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Registro.fromMap(rows.first);
  }

  @override
  Future<void> removerPorId(String id) async {
    final db = await _helper.database;
    await db.delete('registros', where: 'id = ?', whereArgs: [id]);
  }
}
