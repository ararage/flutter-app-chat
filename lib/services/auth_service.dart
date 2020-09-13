import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:chat/global/environment.dart';

import 'package:chat/models/login_response.dart';
import 'package:chat/models/usuario.dart';

class AuthService with ChangeNotifier{
    
    UsuarioDb usuario;
    bool _autenticando = false;
    final _storage = new FlutterSecureStorage();

    bool get autenticando => this._autenticando;
    set autenticando(bool valor){
      this._autenticando = valor;
      notifyListeners(); // This is called for Redrawing the disabled and enabled button in the login page
    }

    // Token Static Getters
    static Future<String> getToken() async {
      final _storage = new FlutterSecureStorage();
      final _token = await _storage.read(key: 'token');
      return _token;
    }

    static Future<void> deleteToken() async {
      final _storage = new FlutterSecureStorage();
      await _storage.delete(key: 'token');
    }

    Future<bool> login(String email, String password) async {  
      // Flag bool for disabling button
      this.autenticando = true;
      
      final data = {
        'email': email,
        'password': password
      };
      final resp = await http.post(
        '${ Environment.apiUrl }/login',
        body: jsonEncode(data),
        headers: {
          'Content-Type': 'application/json'
        }
      );
      this.autenticando = false;
      if(resp.statusCode == 200){
        final loginResponse = loginResponseFromJson( resp.body );
        this.usuario = loginResponse.usuarioDb;
        await this._guardarToken(loginResponse.token);
        return true;
      }
      return false;
    }

    Future register(String nombre, String email, String password) async {
      this.autenticando = true;
      final data = {
        'nombre': nombre,
        'email': email,
        'password': password
      };
      final resp = await http.post(
        '${ Environment.apiUrl }/login/new',
        body: jsonEncode(data),
        headers: {
          'Content-Type': 'application/json'
        }
      );
      this.autenticando = false;
      if(resp.statusCode == 200){
        final registerResponse = loginResponseFromJson( resp.body );
        this.usuario = registerResponse.usuarioDb;
        await this._guardarToken(registerResponse.token);
        return true;
      }
      final respBody = jsonDecode(resp.body);
      return respBody['message'];
    }

    Future<bool> isLogedIn() async {
      final token = await this._storage.read(key: 'token');
      final resp = await http.get(
        '${ Environment.apiUrl }/login/renew',
        headers: {
          'Content-Type': 'application/json',
          'x-token': token
        }
      );
      if(resp.statusCode == 200){
        final registerResponse = loginResponseFromJson( resp.body );
        this.usuario = registerResponse.usuarioDb;
        await this._guardarToken(registerResponse.token);
        return true;
      }else{
        this.logout();
        return false;
      }
    }

    Future _guardarToken(String token) async {
      return await _storage.write(key: 'token', value: token);
    }

    Future logout() async {
      await _storage.delete(key: 'token');
    }
}