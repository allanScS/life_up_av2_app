import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'lifeup_av2.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE habitos (
  id TEXT PRIMARY KEY,
  usuario_id INTEGER NOT NULL,
  nome TEXT NOT NULL,
  descricao TEXT,
  tipo TEXT NOT NULL,
  ativo INTEGER NOT NULL DEFAULT 1,
  data_criacao TEXT NOT NULL,
  sincronizado INTEGER NOT NULL DEFAULT 0
)
''');
        await db.execute('''
CREATE TABLE metas (
  id TEXT PRIMARY KEY,
  usuario_id INTEGER NOT NULL,
  tipo TEXT NOT NULL,
  titulo TEXT NOT NULL,
  descricao TEXT,
  valor_objetivo REAL NOT NULL,
  valor_atual REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL,
  data_criacao TEXT NOT NULL,
  sincronizado INTEGER NOT NULL DEFAULT 0
)
''');
        await db.execute('''
CREATE TABLE registros (
  id TEXT PRIMARY KEY,
  usuario_id INTEGER NOT NULL,
  habito_id TEXT,
  valor REAL NOT NULL,
  observacao TEXT,
  data_registro TEXT NOT NULL,
  sincronizado INTEGER NOT NULL DEFAULT 0
)
''');
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
