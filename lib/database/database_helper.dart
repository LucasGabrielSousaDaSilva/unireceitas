import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/usuario.dart';
import '../models/receita.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('unireceitas.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    String path;
    if (kIsWeb) {
      path = fileName;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      path = join(dir.path, fileName);
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, fileName);
    }
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE receitas (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        ingredientes TEXT NOT NULL,
        modo_preparo TEXT NOT NULL,
        acesso TEXT NOT NULL DEFAULT 'privada',
        proprietario_id TEXT NOT NULL,
        FOREIGN KEY (proprietario_id) REFERENCES usuarios(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE receita_imagens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receita_id TEXT NOT NULL,
        imagem BLOB NOT NULL,
        ordem INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (receita_id) REFERENCES receitas(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== USUARIOS ====================

  Future<int> insertUsuario(Usuario usuario) async {
    final db = await database;
    return await db.insert('usuarios', usuario.toMap());
  }

  Future<List<Usuario>> getUsuarios() async {
    final db = await database;
    final maps = await db.query('usuarios');
    return maps.map((map) => Usuario.fromMap(map)).toList();
  }

  Future<Usuario?> getUsuarioByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'usuarios',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (maps.isEmpty) return null;
    return Usuario.fromMap(maps.first);
  }

  Future<int> updateUsuario(Usuario usuario) async {
    final db = await database;
    return await db.update(
      'usuarios',
      usuario.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }

  // ==================== RECEITAS ====================

  Future<void> insertReceita(Receita receita) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('receitas', receita.toMap());
      for (int i = 0; i < receita.imagens.length; i++) {
        await txn.insert('receita_imagens', {
          'receita_id': receita.id,
          'imagem': receita.imagens[i],
          'ordem': i,
        });
      }
    });
  }

  Future<List<Receita>> getReceitas() async {
    final db = await database;
    final receitaMaps = await db.query('receitas');
    final List<Receita> receitas = [];
    for (final map in receitaMaps) {
      final imagensMaps = await db.query(
        'receita_imagens',
        where: 'receita_id = ?',
        whereArgs: [map['id']],
        orderBy: 'ordem ASC',
      );
      final imagens =
          imagensMaps.map((m) => m['imagem'] as Uint8List).toList();
      receitas.add(Receita.fromMap(map, imagens));
    }
    return receitas;
  }

  Future<void> updateReceita(Receita receita) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'receitas',
        receita.toMap(),
        where: 'id = ?',
        whereArgs: [receita.id],
      );
      await txn.delete(
        'receita_imagens',
        where: 'receita_id = ?',
        whereArgs: [receita.id],
      );
      for (int i = 0; i < receita.imagens.length; i++) {
        await txn.insert('receita_imagens', {
          'receita_id': receita.id,
          'imagem': receita.imagens[i],
          'ordem': i,
        });
      }
    });
  }

  Future<int> deleteReceita(String id) async {
    final db = await database;
    return await db.delete(
      'receitas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
