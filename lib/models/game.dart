import 'dart:math';

import '../configs/config.dart';
import 'board.dart';
import 'chess_piece.dart';

class GameState {
  final List<ChessPiece?> board;
  final int selectedIndex;
  final List<int> availableMoves;
  final int currentPlayer;
  final List<int> kings;
  final List<bool> alive;
  final Map<int, List<int>> enPassant; //player : [enPassant, pawn]
  final Command commands;
  final GameStatus? status;
  final int promotionPawn;


  final GameConfig config;

  const GameState({
    required this.board,
    required this.selectedIndex,
    required this.availableMoves,
    required this.currentPlayer,
    required this.kings,
    required this.alive,
    required this.enPassant,
    required this.commands,
    required this.status,
    required this.promotionPawn,
    required this.config
  });

  factory GameState.initial(GameConfig config){
    List<ChessPiece?> board =  BoardData.initializePieces(config);
    Command commands;
    if(config.commands == Command.random){
      int intValue = Random().nextInt(2);
      if(intValue == 0) {
        commands = Command.oppositeSides;
      }
      else {
        commands = Command.adjacentSides;
      }
    }
    else {
      commands = config.commands;
    }

    return GameState(
      board: board,
      selectedIndex: -1,
      availableMoves: [],
      currentPlayer: 0,
      kings: _initializedKings(board),
      alive: [true, true, true, true],
      enPassant: {0: [-1, -1], 1: [-1, -1], 2: [-1, -1], 3: [-1, -1],},
      commands: commands,
      status: GameStatus.active,
      promotionPawn: -1,
      config: config
    );
  }

  GameState copyWith({List<ChessPiece?>? board, int? selectedIndex, List<int>? availableMoves, int? killPlayer,
    int? currentPlayer, int? newPlacementOfKing, bool? currentPlayerAlive, Map<int, List<int>>? enPassant, GameStatus? status, int? promotionPawn}){
    return GameState(
      board: board ?? this.board,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      availableMoves: availableMoves ?? this.availableMoves,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      kings: _updateKing(newPlacementOfKing),
      alive: _updateAlive(currentPlayerAlive, killPlayer),
      enPassant: _updateEnPassant(enPassant),
      commands: commands,
      status: status ?? this.status,
      promotionPawn: promotionPawn ?? this.promotionPawn,
      config: config
    );
  }

  bool isEnemies(int firstPlayer, int secondPlayer){
    if(firstPlayer == secondPlayer) return false;
    switch(commands){
      case Command.none:
        return true;
      case Command.oppositeSides:
        return firstPlayer % 2 != secondPlayer % 2;
      case Command.adjacentSides:
        return firstPlayer % 2 == secondPlayer % 2;
      default:
        return false;
    }
  }

  Stalemate ifStalemate(){//мы уже учитываем, что на момент проверки игра еще продолжалась
    if(alive.fold(0, (prev, el) => prev + (el ? 1 : 0)) == 2) { //когда остаётесь 1 на 1
      return config.oneOnOneStalemate;
    }
    if(commands == Command.none) return config.aloneAmongAloneStalemate; //когда нет команд, и еще не 1 на 1
    //мы уже точно знаем что осталось 3+ игроков и у нас командный режим
    if(alive[(currentPlayer + 1) % 4] && !isEnemies(currentPlayer, (currentPlayer + 1) % 4) ||//если есть живой союзник у проверяемого игрока
        alive[(currentPlayer + 2) % 4] && !isEnemies(currentPlayer, (currentPlayer + 2) % 4) ||
        alive[(currentPlayer + 3) % 4] && !isEnemies(currentPlayer, (currentPlayer + 3) % 4)){
      return config.commandOnCommandStalemate;
    }
    return config.commandOnOneStalemate;
  }

  static List<int> _initializedKings(List<ChessPiece?> board){
    List<int> kings = List<int>.filled(4, -1);
    for(int index = 0; index < board.length; index++){
      if(board[index] != null && board[index]!.type == 'king' && board[index]!.owner >= 0){
        kings[board[index]!.owner] = index;
      }
    }
    return kings;
  }

  List<int> _updateKing(int? placementOfKing){
    if(placementOfKing == null){
      return kings;
    }
    List<int> newKings = List<int>.of(kings);
    newKings[currentPlayer] = placementOfKing;
    return newKings;
  }

  List<bool> _updateAlive(bool? currentPlayerAlive, int? killPlayer) {
    List<bool> newAlive = List<bool>.of(alive);
    if(currentPlayerAlive != null) newAlive[currentPlayer] = currentPlayerAlive;
    if(killPlayer != null) newAlive[killPlayer] = false;
    return newAlive;
  }

  Map<int, List<int>> _updateEnPassant(Map<int, List<int>>? enPassant) {
    if(enPassant == null){
      return this.enPassant;
    }
    Map<int, List<int>> newEnPassant = Map<int, List<int>>.of(this.enPassant);
    for(int key in enPassant.keys){
      newEnPassant[key] = enPassant[key]!;
    }
    return newEnPassant;
  }

}

enum GameStatus{active, over, waitingForPromotion, draw}