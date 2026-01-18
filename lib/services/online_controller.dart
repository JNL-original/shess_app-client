
// Онлайн логика
import 'dart:async';
import 'dart:convert';
import 'package:chess_app/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../configs/config.dart';
import '../models/chess_piece.dart';
import '../models/game.dart';
import 'base_notifier.dart';

part 'online_controller.g.dart';

@riverpod
class OnlineGame extends _$OnlineGame with GameBaseNotifier{
  StreamSubscription? _socketSubscription;

  @override
  GameState build(String roomId) {
    print("--- Начался метод build ---");
    ref.listen(webSocketProvider(roomId), (previous, next) {
      next.whenData((channel) {
        _socketSubscription?.cancel();
        _socketSubscription = null;
        _setupSubscription(channel);
      });
    });

    final socketAsync = ref.read(webSocketProvider(roomId));
    if (socketAsync.hasValue) {
      Future.microtask(() => _setupSubscription(socketAsync.value!));
    }
    ref.onDispose(() {
      _socketSubscription?.cancel();
      _socketSubscription = null;
    });
    print("--- Возвращаю начальное состояние ---");
    return GameState.initial(OnlineConfig()).copyWith(status: GameStatus.connecting);
  }

  void _setupSubscription(WebSocketChannel channel) {
    if (_socketSubscription != null) return;
    _socketSubscription = _subscript(channel);
    channel.sink.add(jsonEncode({'type': 'connect'}));
    print("--- CONNECT отправлен ---");
  }

  StreamSubscription<dynamic> _subscript(channel) {
    print("--- УСТАНОВЛЕНА ПОДПИСКА НА СТРИМ ---");
    return channel.stream.listen((message) {
      print("--- ПОЛУЧЕННО СООБЩЕНИЕ ---");
      print(message);
      final data = jsonDecode(message);
      if (!ref.mounted) return;
      if (data['type'] == 'sync') {
        state = GameState.fromMap(data['data']);
        final readyList = data['ready'];
        if(readyList != null && state.status == GameStatus.lobby){
          List<bool?> aliveList = state.alive;
          for( int i = 0; i < 4; i ++){
              aliveList[i] = readyList[i.toString()];//если null то пустое место
          }
          state = state.copyWith(aliveList: aliveList);
        }
      }
      else if(data['type'] == 'notExist'){
        state = state.copyWith(status: GameStatus.notExist);
        channel.sink.close(1000);
      }
      else{
        if(data['turn'] == null || data['turn']!= state.turn + 1) {channel.sink.add(jsonEncode({'type': 'connect'}));}
        else{
          switch(data['type']){
            case 'lobby':
              _handleLobby(data);
            case 'update':
              _handleUpdate(data);
            default:
              channel.sink.add(jsonEncode({'type': 'connect'}));
          }
        }
      }
    },
      onError: (err) {
        print("WS Error: $err");
      },
      onDone: () => print("Connection closed"),);
  }

  @override
  bool makeMove(int fromIndex, int toIndex) {
    final socket = ref.read(webSocketProvider(roomId)).value;
    if (socket != null) {
      socket.sink.add(jsonEncode({
        'type': 'move',
        'from': fromIndex,
        'to': toIndex,
      }));
      return true;
    }
    return false;
  }

  @override
  Stalemate? checkmate() {
    throw UnimplementedError();//никогда не выполнится
  }

  @override
  void continueGameAfterPromotion(ChessPiece piece) {
    final socket = ref.read(webSocketProvider(roomId)).value;
    if (socket != null) {
      socket.sink.add(jsonEncode({
        'type': 'promotion',
        'who': piece.toMap(),
      }));
    }
  }

  void iAmReady({Color? color, String? name}){
    List<bool?> alive = List.of(state.alive);
    alive[state.myPlayerIndex!] = true;
    state = state.copyWith(aliveList: alive);
    Map<String, dynamic> message = {};
    message['type'] = 'ready';
    if(color != null) message['color'] = color.value;
    if(name != null) message['name'] = name;
    final socket = ref.read(webSocketProvider(roomId)).value;
    if (socket != null) socket.sink.add(jsonEncode(message));
  }
  void cancelReady(){
    List<bool?> alive = List.of(state.alive);
    alive[state.myPlayerIndex!] = false;
    state = state.copyWith(aliveList: alive);
    final socket = ref.read(webSocketProvider(roomId)).value;
    if (socket != null) {
      socket.sink.add(jsonEncode({
        'type': 'cancelReady',
      }));
    }
  }
  void changeLobbyProperty({Color? color, String? name}){
    Map<String, dynamic> message = {};
    message['type'] = 'change';
    if(color != null) message['color'] = color.value;
    if(name != null) message['name'] = name;
    final socket = ref.read(webSocketProvider(roomId)).value;
    if (socket != null) socket.sink.add(jsonEncode(message));
  }

  @override
  void nextPlayer() {} //переход к следующему игроку и его проверку реализует сервер

  void _handleLobby(Map<String, dynamic> data){
    final readyList = data['ready'];
    if(readyList != null){
      List<bool?> aliveList = state.alive;
      for( int i = 0; i < 4; i ++){
        aliveList[i] = readyList[i.toString()];//если null то пустое место
      }
      OnlineConfig config = state.config as OnlineConfig;
      final colorsHEX = data['colors'];
      Map<int, Color>? colors;
      if(colorsHEX != null){
        final rawColors = colorsHEX as Map<String, dynamic>?;
        final Map<int, Color> parsedColors = rawColors?.map(
              (k, v) => MapEntry(int.parse(k), Color(v as int)),
        ) ?? {-1: Colors.grey, 0: Colors.yellow, 1: Colors.blue, 2: Colors.red, 3: Colors.green};
        colors = parsedColors.cast<int, Color>();
      }
      Map<int, String>? names;
      if (data['names'] != null) {
        final Map<String, dynamic> rawNames = data['names'];
        names = rawNames.map((key, value) => MapEntry(int.parse(key), value.toString())).cast<int, String>();
      }
      config = config.copyWith(colors: colors, names: names);

      final statusString = data['status'];
      GameStatus? status;
      if(statusString != null) {
        status = GameStatus.values.byName(statusString);
      }
      state = state.copyWith(aliveList: aliveList, newConfig: config, status: status, turn: data['turn']);
    }
  }
  void _handleUpdate(Map<String, dynamic> data){
    final updateData = data['data'];
    if(updateData == null || updateData.isEmpty) return;
    final configUpdate = updateData['config'];
    OnlineConfig? config;
    if(configUpdate != null) config = OnlineConfig.fromMap(configUpdate);
    final currentPlayerUpdate = updateData['currentPlayer'];
    final promotionPawnUpdate = updateData['promotionPawn'];
    final statusUpdate = updateData['status'];
    GameStatus? status;
    if(statusUpdate != null) status = GameStatus.values.byName(statusUpdate);
    final enPassantUpdate = updateData['enPassant'];
    Map<int, List<int>>? enPassant;
    if(enPassantUpdate != null){
      enPassant = (enPassantUpdate as Map).map((k, v) => MapEntry(int.parse(k), List<int>.from(v)));
    }
    final aliveUpdate = updateData['alive'];
    List<bool>? alive;
    if(aliveUpdate != null) alive = List<bool>.from(aliveUpdate);
    final kingsUpdate = updateData['kings'];
    List<int>? kings;
    if(kingsUpdate != null) kings = List<int>.from(kingsUpdate);
    final tilesUpdate = updateData['tiles'];
    List<ChessPiece?>? board;
    if(tilesUpdate != null){
      board = state.board;
      Map<int, ChessPiece?> tiles =  (tilesUpdate as Map).map((k, v) =>
          MapEntry(int.parse(k), (v==null || (v as Map<String, dynamic>).isEmpty) ? null : ChessPiece.fromMap(v)));
      for(int key in tiles.keys) {
        board[key] = tiles[key];
      }
    }
    state = state.copyWith(
      newConfig: config,
      currentPlayer: currentPlayerUpdate as int?,
      promotionPawn: promotionPawnUpdate as int?,
      status: status,
      enPassant: enPassant,
      aliveList: alive,
      kings: kings,
      board: board,
      turn: data['turn'],
      selectedIndex: -1,
      availableMoves: []
    );
  }
}