import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scan_result.dart';
import '../core/exceptions.dart';

class LocalDbService extends GetxService {
  static const _dbName = 'agrovision.db';
  
  // CAMBIO CLAVE: Subimos la versión a 3 para agregar plantCategory
  static const _dbVersion = 3; 

  Database? _db;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _openDb();
  }

  Future<void> _openDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade, 
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans (
        id            TEXT PRIMARY KEY,
        diseaseClass  TEXT NOT NULL,
        confidence    REAL NOT NULL,
        plantCategory TEXT,        -- NUEVO columna para la categoría (Fruta, Verdura...)
        description   TEXT,        
        diseaseName   TEXT,        
        isPlant       INTEGER NOT NULL DEFAULT 1, 
        treatment     TEXT,
        latitude      REAL,
        longitude     REAL,
        locationName  TEXT,
        timestamp     TEXT NOT NULL,
        imagePath     TEXT,
        isSynced      INTEGER NOT NULL DEFAULT 0
      )
    ''');

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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS scans');
      await db.execute('DROP TABLE IF EXISTS pending_scans');
      await _createTables(db, newVersion);
    }
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
      throw LocalDbException(
        'Error al guardar escaneo',
        technicalDetail: e.toString(),
      );
    }
  }

  Future<List<ScanResult>> getAllScans({int limit = 50}) async {
    try {
      final rows = await _db!.query(
        'scans',
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return rows.map(ScanResult.fromMap).toList();
    } catch (e) {
      throw LocalDbException(
        'Error al leer historial',
        technicalDetail: e.toString(),
      );
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

  Future<List<ScanResult>> getScansWithLocation() async {
    final rows = await _db!.query(
      'scans',
      where: 'latitude IS NOT NULL AND longitude IS NOT NULL',
      orderBy: 'timestamp DESC',
    );
    return rows.map(ScanResult.fromMap).toList();
  }

  // ─── Cola de pendientes ───────────────────────────────────────────────────

  Future<void> savePendingScan({
    required String scanId,
    required String imagePath,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    await _db!.insert('pending_scans', {
      'id': scanId,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingScans() async {
    return _db!.query('pending_scans', orderBy: 'createdAt ASC');
  }

  Future<void> deletePendingScan(String id) async {
    await _db!.delete('pending_scans', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingCount() async {
    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as count FROM pending_scans',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  void onClose() {
    _db?.close();
    super.onClose();
  }
}