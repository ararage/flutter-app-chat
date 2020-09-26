import 'package:chat/global/environment.dart';
import 'package:chat/models/messages_response.dart';
import 'package:chat/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:chat/models/usuario.dart';

class ChatService with ChangeNotifier {

  UsuarioDb targetUser;

  Future<List<Message>> getChat(String userId) async {
    final resp = await http.get(
      '${ Environment.apiUrl }/messages/$userId',
        headers: {
          'Content-Type': 'application/json',
          'x-token': await AuthService.getToken()
        }
    );
    final messagesResponse = messagesResponseFromJson(resp.body);
    return messagesResponse.messages;
  }
}
