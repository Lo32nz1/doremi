import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  var dir = "/home/user/Music/";
  var file = "/home/user/Music/song.txt";
  var r = p.relative(file, from: dir);
  print(r);
  
  var dir2 = "/home/user/Music";
  var file2 = "/home/user/Music/song.txt";
  var r2 = p.relative(file2, from: dir2);
  print(r2);
  
  print(p.normalize(file) == file);
}
