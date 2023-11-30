import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repositories/cache_info_repository.dart';
import 'package:flutter_cache_manager/src/storage/cache_info_repositories/helper_methods.dart';
import 'package:flutter_cache_manager/src/storage/cache_object.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:isar/isar.dart';





class IsarCacheObjectProvider extends CacheInfoRepository
    with CacheInfoRepositoryHelperMethods {
  late Isar db;
  String? _path;
  String databaseName;

  /// Either the path or the database name should be provided.
  /// If the path is provider it should end with '{databaseName}.db',
  /// for example: /data/user/0/com.example.example/databases/imageCache.db
  IsarCacheObjectProvider({String? path, required this.databaseName}) : _path = path;
  String? get path => _path;
  @override
  Future<bool> open() async {
    if (!shouldOpenOnNewConnection()) {
      return openCompleter!.future;
    }
    // databaseFactory = databaseFactoryFfi;
    final path = await _getPath();
    await File(path).parent.create(recursive: true);

    db = await Isar.open(
      [CacheObjectSchema],
      directory: path,
        name: databaseName
    );

    // db = await openDatabase(path, version: 3,
    //     onCreate: (Database db, int version) async {
    //   await db.execute('''
    //   create table $_tableCacheObject (
    //     ${CacheObject.columnId} integer primary key,
    //     ${CacheObject.columnUrl} text,
    //     ${CacheObject.columnKey} text,
    //     ${CacheObject.columnPath} text,
    //     ${CacheObject.columnETag} text,
    //     ${CacheObject.columnValidTill} integer,
    //     ${CacheObject.columnTouched} integer,
    //     ${CacheObject.columnType} text,
    //     ${CacheObject.columnEncoding} text,
    //     ${CacheObject.columnLength} integer
    //     );
    //     create unique index $_tableCacheObject${CacheObject.columnKey}
    //     ON $_tableCacheObject (${CacheObject.columnKey});
    //   ''');
    // }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
    //   // Migration for adding the optional key, does the following:
    //   // Adds the new column
    //   // Creates a unique index for the column
    //   // Migrates over any existing URLs to keys
    //   if (oldVersion <= 1) {
    //     var alreadyHasKeyColumn = false;
    //     try {
    //       await db.execute('''
    //         alter table $_tableCacheObject
    //         add ${CacheObject.columnKey} text;
    //         ''');
    //     } on DatabaseException catch (e) {
    //       if (!e.isDuplicateColumnError(CacheObject.columnKey)) rethrow;
    //       alreadyHasKeyColumn = true;
    //     }
    //     await db.execute('''
    //       update $_tableCacheObject
    //         set ${CacheObject.columnKey} = ${CacheObject.columnUrl}
    //         where ${CacheObject.columnKey} is null;
    //       ''');
    //
    //     if (!alreadyHasKeyColumn) {
    //       await db.execute('''
    //         create index $_tableCacheObject${CacheObject.columnKey}
    //           on $_tableCacheObject (${CacheObject.columnKey});
    //         ''');
    //     }
    //   }
    //   if (oldVersion <= 2) {
    //     try {
    //       await db.execute('''
    //     alter table $_tableCacheObject
    //     add ${CacheObject.columnLength} integer;
    //     ''');
    //     } on DatabaseException catch (e) {
    //       if (!e.isDuplicateColumnError(CacheObject.columnLength)) rethrow;
    //     }
    //   }
    // });
    return opened();
  }

  @override
  Future<dynamic> updateOrInsert(CacheObject cacheObject, {bool setTouchedToNow = true}) async {
    // if (cacheObject.id == null) {
    //   return insert(cacheObject);
    // } else {
    //   return update(cacheObject);
    // }
    if (setTouchedToNow) {
      cacheObject.touched = clock.now();
    }
    return await db.writeTxn(() async {
      return await db.cacheObjects.put(cacheObject); // insert & update
    });
  }

  @override
  Future<CacheObject> insert(CacheObject cacheObject,
      {bool setTouchedToNow = true}) async {
    if (setTouchedToNow) {
      cacheObject.touched = clock.now();
    }
    // var o = cacheObject.toMap(setTouchedToNow: setTouchedToNow);
    return await db.writeTxn(() async {
      final id = await db!.cacheObjects.put(cacheObject);
      return cacheObject.copyWith(id: id);
    });
  }

  @override
  Future<CacheObject?> get(String key) async {
    final recipe = await db!.cacheObjects.getByKey(key);
    return recipe;

    // final List<Map<dynamic, dynamic>> maps = await db!.query(_tableCacheObject,
    //     columns: null, where: '${CacheObject.columnKey} = ?', whereArgs: [key]);
    // if (maps.isNotEmpty) {
    //   return CacheObject.fromMap(maps.first.cast<String, dynamic>());
    // }
    // return null;
  }

  @override
  Future<int> delete(int id) async {
    var result = await db.cacheObjects.delete(id);
    return result ? 1 : 0;
    // return db!.delete(_tableCacheObject,
    //     where: '${CacheObject.columnId} = ?', whereArgs: [id]);
  }

  @override
  Future<int> deleteAll(Iterable<int> ids) async {
    return await db.writeTxn(() async {
      var count = await db.cacheObjects.deleteAll(ids.toList());
      return count;
    });

    // return db!.delete(_tableCacheObject,
    //     where: '${CacheObject.columnId} IN (${ids.join(',')})');
  }

  @override
  Future<int> update(CacheObject cacheObject, {bool setTouchedToNow = true}) async {
    return await db.writeTxn(() async {
      var id = await db!.cacheObjects.put(cacheObject);
      return id;
    });

    // return db!.update(
    //   _tableCacheObject,
    //   cacheObject.toMap(setTouchedToNow: setTouchedToNow),
    //   where: '${CacheObject.columnId} = ?',
    //   whereArgs: [cacheObject.id],
    // );
  }

  @override
  Future<List<CacheObject>> getAllObjects() async {
    var all = await db!.cacheObjects.where().findAll();
    return all;
    // return CacheObject.fromMapList(
    //   await db!.query(_tableCacheObject, columns: null),
    // );
  }

  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) async {
    var t = DateTime.now().subtract(const Duration(days: 1));
    var all = db.cacheObjects.filter().touchedLessThan(t).sortByTouchedDesc().offset(capacity).limit(100).findAll();
    return all;

    // return CacheObject.fromMapList(await db!.query(
    //   _tableCacheObject,
    //   columns: null,
    //   orderBy: '${CacheObject.columnTouched} DESC',
    //   where: '${CacheObject.columnTouched} < ?',
    //   whereArgs: [
    //     DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch
    //   ],
    //   limit: 100,
    //   offset: capacity,
    // ));
  }

  @override
  Future<List<CacheObject>> getOldObjects(Duration maxAge) async {

    var t = DateTime.now().subtract(maxAge);
    var all = db.cacheObjects.filter().touchedLessThan(t).sortByTouchedDesc().limit(100).findAll();
    return all;

    // return CacheObject.fromMapList(await db!.query(
    //   _tableCacheObject,
    //   where: '${CacheObject.columnTouched} < ?',
    //   columns: null,
    //   whereArgs: [DateTime.now().subtract(maxAge).millisecondsSinceEpoch],
    //   limit: 100,
    // ));
  }

  @override
  Future<bool> close() async {
    if (!shouldClose()) return false;
    await db!.close();
    return true;
  }

  @override
  Future<void> deleteDataFile() async {
    await _getPath();
  }

  @override
  Future<bool> exists() async {
    final path = await _getPath();
    return File(path).exists();
  }

  Future<String> _getPath() async {
    Directory directory;
    if (_path != null) {
      directory = File(_path!).parent;
    } else {
      directory = await getApplicationSupportDirectory();
      _path = directory.path;
    }
    await directory.create(recursive: true);
    // if (_path == null || !_path!.endsWith('.db')) {
    //   _path = join(directory.path, '$databaseName.db');
    // }
    await _migrateOldDbPath(_path!);
    return _path!;
  }

  // Migration for pre-V2 path on iOS and macOS
  Future<void> _migrateOldDbPath(String newDbPath) async {
    return;
    // final oldDbPath = join(await getDatabasesPath(), '$databaseName.db');
    // if (oldDbPath != newDbPath && await File(oldDbPath).exists()) {
    //   try {
    //     await File(oldDbPath).rename(newDbPath);
    //   } on FileSystemException {
    //     // If we can not read the old db, a new one will be created.
    //   }
    // }
  }
}
