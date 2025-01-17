import 'package:clock/clock.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar/isar.dart';

part 'cache_object.g.dart';

@collection
class CacheObject {
  static const columnId = '_id';
  static const columnUrl = 'url';
  static const columnKey = 'key';
  static const columnPath = 'relativePath';
  static const columnETag = 'eTag';
  static const columnValidTill = 'validTill';
  static const columnTouched = 'touched';
  static const columnType = 'type';
  static const columnEncoding = 'encoding';
  static const columnLength = 'length';

  CacheObject(
      this.url, {
        // String? key,
        required this.key,
        required this.relativePath,
        required this.validTill,
        this.eTag,
        // this.id,
        this.length,
        this.type,
        this.encoding,
        this.touched,
      }) {
    // key = key ?? getUrlKey(url);
  }
  // CacheObject(
  //     this.url, {
  //       String? key,
  //       required this.relativePath,
  //       required this.validTill,
  //       this.eTag,
  //       this.id,
  //       this.length,
  //       this.type,
  //       this.encoding,
  //       this.touched,
  //     }) : key = key ?? getUrlKey(url); // url;

  CacheObject.fromMap(Map<String, dynamic> map)
      :
  // id = map[columnId] as Id,
        url = map[columnUrl] as String,
  // key = map[columnKey] as String? ?? map[columnUrl] as String,
        key = map[columnKey] as String? ?? getUrlKey(map[columnUrl]) as String,
        relativePath = map[columnPath] as String,
        validTill =
        DateTime.fromMillisecondsSinceEpoch(map[columnValidTill] as int),
        eTag = map[columnETag] as String?,
        length = map[columnLength] as int?,
        type = map[columnType] as String?,
        encoding = map[columnEncoding] as String?,
        touched =
        DateTime.fromMillisecondsSinceEpoch(map[columnTouched] as int);

  /// Internal ID used to represent this cache object
  @Name("id")
  Id? id; //  = Isar.autoIncrement;

  /// The URL that was used to download the file
  @Name("url")
  String url;

  /// The key used to identify the object in the cache.
  ///
  /// This key is optional and will default to [url] if not specified
  @Name("key")
  @Index(unique: true, caseSensitive: false)
  final String key;

  /// Where the cached file is stored
  @Name("path")
  String relativePath;

  /// When this cached item becomes invalid
  @Name("validTill")
  DateTime validTill;

  /// eTag provided by the server for cache expiry
  @Name("eTag")
  String? eTag;

  /// The length of the cached file
  int? length;
  String? type;
  String? encoding;

  /// When the file is last used
  DateTime? touched;

  Map<String, dynamic> toMap({bool setTouchedToNow = true}) {
    final map = <String, dynamic>{
      columnUrl: url,
      columnKey: key,
      columnPath: relativePath,
      columnETag: eTag,
      columnValidTill: validTill.millisecondsSinceEpoch,
      columnTouched:
      (setTouchedToNow ? clock.now() : touched)?.millisecondsSinceEpoch ??
          0,
      columnLength: length,
      columnType: type,
      columnEncoding: encoding,
      // if (id != null) columnId: id,
    };
    return map;
  }
  static String getUrlKey(String url) {
    var u = Uri.parse(url);
    // u.scheme
    var key = url.replaceFirst('${u.scheme}://', '');
    // var key = "${u.host}/${u.path}${u.query != '' ? '?${u.query}' : ''}";
    // return key;
    return md5.convert(utf8.encode(key)).toString();

  }
  static List<CacheObject> fromMapList(List<Map<String, dynamic>> list) {
    return list.map((map) => CacheObject.fromMap(map)).toList();
  }

  CacheObject copyWith({
    String? url,
    Id? id,
    String? relativePath,
    DateTime? validTill,
    String? eTag,
    int? length,
    String? type,
    String? encoding,
  }) {
    return CacheObject(
      url ?? this.url,
      // id: id ?? this.id,
      key: key,
      relativePath: relativePath ?? this.relativePath,
      validTill: validTill ?? this.validTill,
      eTag: eTag ?? this.eTag,
      length: length ?? this.length,
      type: type ?? this.type,
      encoding: encoding ?? this.encoding,
      touched: touched,
    );
  }
}
