// To parse this JSON data, do
//
//     final loginResponse = loginResponseFromJson(jsonString);

import 'dart:convert';
import 'package:chat/models/usuario.dart';

LoginResponse loginResponseFromJson(String str) => LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
    LoginResponse({
        this.ok,
        this.usuarioDb,
        this.token,
    });

    bool ok;
    UsuarioDb usuarioDb;
    String token;

    factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        ok: json["ok"],
        usuarioDb: UsuarioDb.fromJson(json["usuarioDB"]),
        token: json["token"],
    );

    Map<String, dynamic> toJson() => {
        "ok": ok,
        "usuarioDB": usuarioDb.toJson(),
        "token": token,
    };
}
