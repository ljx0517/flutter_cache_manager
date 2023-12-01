import 'package:file/file.dart';

abstract class FileSystem {
  get fileDir;
  Future<File> createFile(String name);
}
