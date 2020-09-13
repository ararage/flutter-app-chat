import 'dart:io';

class Environment {
  static String apiUrl = Platform.isAndroid ? 'http://172.21.0.1:3000/api' : 'http://localhost:3000/api';
  static String socketUrl = Platform.isAndroid ? 'http://172.21.0.1:3000' : 'http://localhost:3000';
}