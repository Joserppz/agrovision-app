import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scan_result.dart';
import '../core/exceptions.dart';

// Usamos sqflite directo por simplicidad — si el proyecto crece
// se puede migrar a Drift sin cambiar la interfaz pública de este servicio

class LocalDbService extends GetxService {
  static const _dbName    = 'agrovision.db';
  static const _dbVersion = 1;

  Database? _db;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _openDb();
  }

  Future<void> _openDb() async {
    final dir  = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Tabla principal de escaneos
    await db.execute('''
      CREATE TABLE scans (
        id            TEXT PRIMARY KEY,
        diseaseClass  TEXT NOT NULL,
        confidence    REAL NOT NULL,
        treatment     TEXT,
        latitude      REAL,
        longitude     REAL,
        locationName  TEXT,
        timestamp     TEXT NOT NULL,
        imagePath     TEXT,
        isSynced      INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Cola de escaneos pendientes de sincronizar (sin resultado aún)
    await db.execute('''
      CREATE TABLE pending_scans (
        id            TEXT PRIMARY KEY,
        imagePath     TEXT NOT NULL,
        latitude      REAL,
        longitude     REAL,
        locationName  TEXT,
        createdAt     TEXT NOT NULL
      )
    ''');
  }

  // ─── Escaneos ─────────────────────────────────────────────────────────────

  Future<void> saveScan(ScanResult scan) async {
    try {
      await _db!.insert(
        'scans',
        scan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw LocalDbException('Error al guardar escaneo', technicalDetail: e.toString());
    }
  }

  Future<List<ScanResult>> getAllScans({int limit = 50}) async {
    try {
      final rows = await _db!.query(
        'scans',
        orderBy: 'timestamp DESC',
        limit:   limit,
      );
      return rows.map(ScanResult.fromMap).toList();
    } catch (e) {
      throw LocalDbException('Error al leer historial', technicalDetail: e.toString());
    }
  }

  Future<ScanResult?> getScanById(String id) async {
    final rows = await _db!.query('scans', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ScanResult.fromMap(rows.first);
  }

  Future<void> deleteScan(String id) async {
    await _db!.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  // Todos los escaneos con coordenadas (para el mapa)
  Future<List<ScanResult>> getScansWithLocation() async {
    final rows = await _db!.query(
      'scans',
      where:   'latitude IS NOT NULL AND longitude IS NOT NULL',
      orderBy: 'timestamp DESC',
    );
    return rows.map(ScanResult.fromMap).toList();
  }

  // ─── Cola de pendientes ───────────────────────────────────────────────────

  Future<void> savePendingScan({
    required String scanId,
    required String imagePath,
    double?  latitude,
    double?  longitude,
    String?  locationName,
  }) async {
    await _db!.insert('pending_scans', {
      'id':          scanId,
      'imagePath':   imagePath,
      'latitude':    latitude,
      'longitude':   longitude,
      'locationName': locationName,
      'createdAt':   DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingScans() async {
    return _db!.query('pending_scans', orderBy: 'createdAt ASC');
  }

  Future<void> deletePendingScan(String id) async {
    await _db!.delete('pending_scans', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingCount() async {
    final result = await _db!.rawQuery('SELECT COUNT(*) as count FROM pending_scans');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  void onClose() {
    _db?.close();
    super.onClose();
  }
}