import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:chat/widgets/chat_message.dart';

import 'package:provider/provider.dart';

import 'package:chat/services/chat_service.dart';
import 'package:chat/services/auth_service.dart';
import 'package:chat/services/socket_service.dart';

import 'package:chat/models/messages_response.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin{
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  ChatService chatService;
  SocketService socketService;
  AuthService authService;

  List<ChatMessage> _messages = [
  ];

  bool _estaEscribiendo = false;

  @override
  void initState() { 
    super.initState();

    this.chatService = Provider.of<ChatService>(context, listen: false);
    this.socketService = Provider.of<SocketService>(context, listen: false);
    this.authService = Provider.of<AuthService>(context, listen: false);

    this.socketService.socket.on('private-message', _listenMessage);

    _loadHistoryMessages(this.chatService.targetUser.uuid);
  }

  void _loadHistoryMessages(String uuid) async{
    List<Message> chat = await this.chatService.getChat(uuid);
    print(chat);
    final history = chat.map((m)=> ChatMessage(
      texto: m.message,
      uuid: m.from,
      animationController: new AnimationController(vsync: this, duration: Duration(milliseconds: 0))..forward(),
    ));
    setState(() {
      this._messages.insertAll(0, history);
    });
  }

  void _listenMessage(dynamic payload){
    print(payload);
    ChatMessage message = new ChatMessage(
      uuid: payload['from'], 
      texto: payload['message'],
      animationController: AnimationController(vsync: this, duration: Duration(milliseconds: 300)),
    );
    setState(() {
      _messages.insert(0, message);
    });

    message.animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final targetUser = this.chatService.targetUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          children: [
            CircleAvatar(
              child: Text(targetUser.nombre.substring(0,2), style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.blue[100],
              maxRadius: 14,
            ),
            SizedBox(
              height: 3,
            ),
            Text(targetUser.nombre,
                style: TextStyle(color: Colors.black87, fontSize: 10))
          ],
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: Container(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _messages[i],
                reverse: true,
              ),
            ),
            Divider(
              height: 1,
            ),
            Container(
              color: Colors.white,
              child: _inputChat(),
            )
          ],
        ),
      ),
    );
  }

  Widget _inputChat() {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmit,
                onChanged: (String texto) {
                  // TODO: Cuando hay un valor para enviar el mensaje
                  setState(() {
                    if (texto.trim().length > 0) {
                      _estaEscribiendo = true;
                    } else {
                      _estaEscribiendo = false;
                    }
                  });
                },
                decoration:
                    InputDecoration.collapsed(hintText: 'Enviar Mensaje'),
                focusNode: _focusNode,
              ),
            ),
            // Botón de enviar
            Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                child: Platform.isIOS
                    ? CupertinoButton(
                        child: Text('Enviar'),
                        onPressed: _estaEscribiendo
                            ? () => _handleSubmit(_textController.text.trim())
                            : null,
                      )
                    : Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.0),
                        child: IconTheme(
                          data: IconThemeData(color: Colors.blue[400]),
                          child: IconButton(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            icon: Icon(Icons.send),
                            onPressed: _estaEscribiendo
                                ? () =>
                                    _handleSubmit(_textController.text.trim())
                                : null,
                          ),
                        )))
          ],
        ),
      ),
    );
  }

  _handleSubmit(String text) {
    if (_textController.text.length == 0) return;

    _textController.clear(); // Limpiamos el texto
    _focusNode.requestFocus(); // No deja que se cierre el teclado al dar enter
    
    final newMessage = new ChatMessage(
      uuid: authService.usuario.uuid,
      texto: text,
      animationController: AnimationController(vsync: this, duration: Duration(milliseconds: 200)),
    );
    setState(() {
      _messages.insert(0, newMessage);
      newMessage.animationController.forward(); // Continua la animación, es REQUERIDO ESTE METODO
      _estaEscribiendo = false;
    });

    this.socketService.emit('private-message', {
      'from': this.authService.usuario.uuid,
      'to': this.chatService.targetUser.uuid,
      'message': text
    });
  }

  @override
  void dispose(){
    // Clean Memory for Animation messages
    for( ChatMessage message in _messages){
      message.animationController.dispose();
    }
    this.socketService.socket.off('private-message');
    super.dispose();
  }
}
