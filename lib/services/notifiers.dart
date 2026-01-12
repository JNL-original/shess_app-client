// Оффлайн логика
import 'dart:math';

import 'package:chess_app/configs/config.dart';
import 'package:chess_app/models/bishop.dart';
import 'package:chess_app/models/chess_piece.dart';
import 'package:chess_app/models/knight.dart';
import 'package:chess_app/models/queen.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/board.dart';
import '../models/game.dart';
import '../models/king.dart';
import '../models/pawn.dart';
import '../models/rook.dart';

abstract class GameBaseNotifier extends StateNotifier<GameState> {
  GameBaseNotifier(super.initialBoard);

  bool makeMove(int fromIndex, int toIndex);
  Stalemate? checkmate(); //проверить на мат или невозможность ходить текущего игрока



  void onTileTapped(int index){
    if(state.selectedIndex != -1
        && state.availableMoves.contains(index) && state.status == GameStatus.active){
      if(makeMove(state.selectedIndex, index)){
        if(state.status == GameStatus.waitingForPromotion) return;
        state = state.copyWith(selectedIndex: -1, availableMoves: [], currentPlayer: (state.currentPlayer + 1) % 4);
        _checkNextTurn();
      }
      else{
        print("Ошибка хода");
      }

    }
    else if(state.selectedIndex == index || BoardData.corners.contains(index)){
      state = state.copyWith(selectedIndex: -1, availableMoves: []);
    }
    else if (state.board[index] != null && state.currentPlayer == state.board[index]!.owner){
      state = state.copyWith(
          selectedIndex: index,
          availableMoves: _truePossibleMoves(index)
      );
    } else {
      state = state.copyWith(selectedIndex: -1, availableMoves: []);
    }
  }

  void continueGameAfterPromotion(ChessPiece piece){
    //сменить статус, закончить хход, убрать индекс превращаемой пешки
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    switch(piece.type){
      case 'pawn':
        board[state.promotionPawn] = Pawn(owner: state.currentPlayer, hasMoved: true);
      case 'rook':
        board[state.promotionPawn] = Rook(owner: state.currentPlayer, hasMoved: true);
      default:
        board[state.promotionPawn] = piece;
    }
    state = state.copyWith(board: board, selectedIndex: -1, availableMoves: [], currentPlayer: (state.currentPlayer + 1) % 4, status: GameStatus.active, promotionPawn: -1);
    _checkNextTurn();
  }

  void _checkNextTurn(){
    bool wasChange = false; //было ли доп изменение текущего игрока
    //удаление enPassant если игрок жив
    if(state.alive[state.currentPlayer]){
      state = state.copyWith(enPassant: {state.currentPlayer : [-1, -1]});
      //проверка на мат если игрок жив
      switch(checkmate()){
        case null:
          break;
        case Stalemate.checkmate:
          List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
          for(int i = 0; i < board.length; i++){
            if(board[i] != null && board[i]!.owner == state.currentPlayer){
              board[i] = board[i]!.kill();
            }
          }
          state = state.copyWith(board: board, currentPlayerAlive: false, currentPlayer: (state.currentPlayer + 1) % 4);
          wasChange = true;
          break;
        case Stalemate.draw:
          state = state.copyWith(status: GameStatus.draw);
        case Stalemate.skipMove:
          state = state.copyWith(currentPlayer: (state.currentPlayer + 1) % 4);
          wasChange = true;
      }
    }

    //проверка что игра продолжается
    if(state.status == GameStatus.active && _gameIsActive()){
      //меняем активных пока не будет жив
      while(!state.alive[state.currentPlayer]){
        state = state.copyWith(currentPlayer: (state.currentPlayer + 1) % 4);
        wasChange = true;
      }
      if(wasChange) _checkNextTurn();// рекурсивно вызываем проверку следующего активного игрока
    }
    else{
      state = state.copyWith(status: GameStatus.over);
    }

  }
  bool _gameIsActive(){
    int activePlayer = state.alive.indexOf(true);
    if(activePlayer == 3 || activePlayer == -1) return false;
    switch(state.commands){
      case Command.none:
        return state.alive[(activePlayer + 1) % 4] || state.alive[(activePlayer + 2) % 4] || state.alive[(activePlayer + 3) % 4];
      case Command.oppositeSides:
        return state.alive[(activePlayer + 1) % 4] || state.alive[(activePlayer + 3) % 4];
      case Command.adjacentSides:
        if(activePlayer > 1) return false;
        return state.alive[2] || state.alive[3];
      default:
        return false;
    }
  }


  bool _onFire(int index, List<ChessPiece?> board){//не учитываем en passant и рокировки
    ChessPiece? piece = board[index];

    List<int> kings = List<int>.of(state.kings);
    if(piece == null) return false;

    for(int i = 0; i < board.length; i++){
      ChessPiece? enemyPiece = board[i];
      if(
      enemyPiece != null &&
          state.isEnemies(enemyPiece.owner, piece.owner) &&
          enemyPiece.getPossibleMoves(i, state.copyWith(board: board)).contains(index)
      ) {
        return true;
      }
    }
    return false;
  }

  List<int> _truePossibleMoves(int index){
    ChessPiece? piece = state.board[index];
    if(piece == null) return [];
    List<int> moves = piece.getPossibleMoves(index, state);

    if(state.config.onlyRegicide){
      if(piece.type == 'king') moves.addAll(_possibleCastling());
      return moves;
    }

    List<ChessPiece?> draw = List<ChessPiece?>.of(state.board);
    List<int> kings = List<int>.of(state.kings);


    for(int move in List<int>.of(moves)){ //перебираю каждый возможный ход    без учета enPassant и рокировки
      ChessPiece? temp = draw[move];
      draw[index] = null;
      draw[move] = piece;
      if(piece.type == 'king') kings[state.currentPlayer] = move;
      if(_onFire(kings[state.currentPlayer], draw)){
        moves.remove(move);
      }
      draw[move] = temp;
      draw[index] = piece;
      kings[state.currentPlayer] = state.kings[state.currentPlayer];
    }

    if(piece.type == 'king') moves.addAll(_possibleCastling());

    return moves;
  }


  List<int> _possibleCastling(){
    List<int> possible = [];
    List<ChessPiece?> board = state.board;
    if((board[state.kings[state.currentPlayer]] as King).hasMoved) return [];
    List<int> rooks = [];
    for(int i = 0; i < board.length; i++){
      if(board[i] != null && board[i]!.type == 'rook' && board[i]!.owner == state.currentPlayer && !(board[i] as Rook).hasMoved){
        rooks.add(i);
      }
    }
    if(rooks.isEmpty) return [];
    for(int rookIndex in rooks){
      if(_cleanWayForCastling(rookIndex)){
        possible.add(rookIndex);
      }
    }
    return possible;
  }

  bool _cleanWayForCastling(int rookIndex){
    int kingIndex = state.kings[state.currentPlayer];
    if(rookIndex < kingIndex){
      switch(state.currentPlayer){
        case 0:
          for(int x = rookIndex+1; x < kingIndex; x++) {
            if (state.board[x] != null) return false;
          }
        case 1:
          for(int x = rookIndex + BoardData.boardSize; x < kingIndex; x += BoardData.boardSize){
            if (state.board[x] != null) return false;
          }
        case 2:
          for(int x = rookIndex+1; x < kingIndex; x++){
            if (state.board[x] != null) return false;
          }
        case 3:
          for(int x = rookIndex + BoardData.boardSize; x < kingIndex; x += BoardData.boardSize){
            if (state.board[x] != null) return false;
          }
        default:
          return false;
      }
    }
    else{
      switch(state.currentPlayer){
        case 0:
          for (int x = rookIndex-1; x > kingIndex; x--){
            if (state.board[x] != null) return false;
          }
        case 1:
          for (int x = rookIndex - BoardData.boardSize; x > kingIndex; x -= BoardData.boardSize){
            if (state.board[x] != null) return false;
          }
        case 2:
          for (int x = rookIndex-1; x > kingIndex; x--){
            if (state.board[x] != null) return false;
          }
        case 3:
          for (int x = rookIndex - BoardData.boardSize; x > kingIndex; x -= BoardData.boardSize){
            if (state.board[x] != null) return false;
          }
        default:
          return false;
      }
    }

    if(rookIndex < kingIndex){
      switch(state.currentPlayer){
        case 0:
          for(int index = kingIndex; index + 3 > kingIndex; index--){
            if(_onFire(index, state.board)) return false;
          }
        case 1:
          for(int index = kingIndex; index + 3 * BoardData.boardSize > kingIndex; index-=BoardData.boardSize){
            if(_onFire(index, state.board)) return false;
          }
        case 2:
          for(int index = kingIndex; index + 3 > kingIndex; index--){
            if(_onFire(index, state.board)) return false;
          }
        case 3:
          for(int index = kingIndex; index + 3 * BoardData.boardSize > kingIndex; index-=BoardData.boardSize){
            if(_onFire(index, state.board)) return false;
          }
        default:
          return false;
      }
    } else{
      switch(state.currentPlayer){
        case 0:
          for(int index = kingIndex; index - 3 < kingIndex; index++){
            if(_onFire(index, state.board)) return false;
          }
        case 1:
          for(int index = kingIndex; index - 3 * BoardData.boardSize < kingIndex; index+=BoardData.boardSize){
            if(_onFire(index, state.board)) return false;
          }
        case 2:
          for(int index = kingIndex; index - 3 < kingIndex; index++){
            if(_onFire(index, state.board)) return false;
          }
        case 3:
          for(int index = kingIndex; index - 3 * BoardData.boardSize < kingIndex; index+=BoardData.boardSize){
            if(_onFire(index, state.board)) return false;
          }
        default:
          return false;
      }
    }
    return true;
  }


}



class OfflineGameNotifier extends GameBaseNotifier {
  OfflineGameNotifier(GameConfig config) : super(GameState.initial(config));

  @override
  bool makeMove(int fromIndex, int toIndex) {
    List<ChessPiece?> board = List<ChessPiece?>.from(state.board);
    final piece = board[fromIndex];
    if (piece == null) return false;

    if(board[toIndex] != null && board[toIndex]!.owner == state.currentPlayer && board[toIndex]!.type == 'rook') {
      _makeCastling(toIndex);
      return true;
    }
    if(board[toIndex] != null && board[toIndex]!.type == 'king'){
      int killPlayer = board[toIndex]!.owner;
      for(int i = 0; i < board.length; i++){
        if(board[i] != null && board[i]!.owner == killPlayer){
          board[i] = board[i]!.kill();
        }
      }
      state = state.copyWith(board: board, killPlayer: killPlayer);
    }

    board[fromIndex] = null;
    switch (piece.type) {
      case 'pawn':
        final pawn = piece as Pawn;
        board[toIndex] = pawn.copyWith(hasMoved: true);
        Map<int, List<int>> newEnPassant = Map<int, List<int>>.of(state.enPassant);
        int mayEnPassant = pawn.checkEnPassant(fromIndex, toIndex);
        newEnPassant[state.currentPlayer] = [mayEnPassant, (mayEnPassant == -1) ? -1 : toIndex];
        for(int key in state.enPassant.keys){
          if(state.enPassant[key]![0] == toIndex && board[state.enPassant[key]![1]]!.owner == key){ //en passant
            board[newEnPassant[key]![1]] = null; // убираем перехваченную пешку
            newEnPassant[key] = [-1, -1];
          }
        }
        if(state.config.pawnPromotion != Promotion.none && pawn.isFinished(toIndex, state.config.promotionCondition)){//если пешка финишировала
          switch(state.config.pawnPromotion){
            case Promotion.queen:
              board[toIndex] = Queen(owner: state.currentPlayer);
            case Promotion.choice:
              board[toIndex] = Pawn(owner: state.currentPlayer, hasMoved: true);
              state = state = state.copyWith(board: board, enPassant: newEnPassant, status: GameStatus.waitingForPromotion, promotionPawn: toIndex);
              return true;
            case Promotion.random:
              int intValue = Random().nextInt(4);
              switch(intValue){
                case 0:
                  board[toIndex] = Queen(owner: state.currentPlayer);
                case 1:
                  board[toIndex] = Rook(owner: state.currentPlayer, hasMoved: true);
                case 2:
                  board[toIndex] = Knight(owner: state.currentPlayer);
                case 3:
                  board[toIndex] = Bishop(owner: state.currentPlayer);
              }
            case Promotion.randomWithPawn:
              int intValue = Random().nextInt(5);
              switch(intValue){
                case 0:
                  board[toIndex] = Queen(owner: state.currentPlayer);
                case 1:
                  board[toIndex] = Rook(owner: state.currentPlayer, hasMoved: true);
                case 2:
                  board[toIndex] = Knight(owner: state.currentPlayer);
                case 3:
                  board[toIndex] = Bishop(owner: state.currentPlayer);
                case 4:
                  board[toIndex] = Pawn(owner: state.currentPlayer, hasMoved: true);
              }
            case Promotion.none:
              board[toIndex] = Pawn(owner: state.currentPlayer, hasMoved: true);
          }
          board[toIndex] = Queen(owner: state.currentPlayer);
        }
        state = state.copyWith(board: board, enPassant: newEnPassant);
        break;
      case 'king':
        final king = piece as King;
        board[toIndex] = king.copyWith(hasMoved: true);
        int newIndexOfKing = toIndex;
        state = state.copyWith(board: board, newPlacementOfKing: newIndexOfKing);
        break;
      case 'rook':
        final rook = piece as Rook;
        board[toIndex] = rook.copyWith(hasMoved: true);
        state = state.copyWith(board: board);
        break;
      default:
        board[toIndex] = piece;
        state = state.copyWith(board: board);
    }
    return true;
  }

  @override
  Stalemate? checkmate() {
    //проверка для режима цареубийство
    if(state.config.onlyRegicide){
      for(int index = 0; index < state.board.length; index++){
        if(state.board[index]!=null && state.board[index]!.owner == state.currentPlayer && state.board[index]!.getPossibleMoves(index, state).isNotEmpty){
          return null;
        }
      }
      return Stalemate.skipMove;
    }
    //проверка для остального режима
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    List<int> kings = List<int>.of(state.kings);
    //перебираем каждый возможный ход
    //если привел к шаху, откатываем назад и переходим к следующему
    //если не привел к шаху, возвращаем лож (выходим из перебора)
    for(int index = 0; index < board.length; index++){
      ChessPiece? piece = board[index];
      if(piece != null && piece.owner == state.currentPlayer){ //если это наша фигура
        for(int move in piece.getPossibleMoves(index, state)){ //перебираем каждый возможный ход
          ChessPiece? temp = board[move];
          board[index] = null;
          board[move] = piece;
          if(piece.type == 'king') kings[state.currentPlayer] = move;
          if(!_onFire(kings[state.currentPlayer], board)){
            return null;
          } else{
            board[move] = temp;
            board[index] = piece;
            kings[state.currentPlayer] = state.kings[state.currentPlayer];
          }
        }
      }
    }
    //проверка на пат
    if(_onFire(kings[state.currentPlayer], board)){//проверка на мат
      return Stalemate.checkmate;
    }
    else{
     return state.ifStalemate();
    }
  }
  /*
    final Stalemate oneOnOneStalemate; //когда остаётесь 1 на 1                                 --абсолютный приоритет
  final Stalemate aloneAmongAloneStalemate; // когда не 1 на 1 в бескомандном режиме          --одиночный режим
  final Stalemate commandOnOneStalemate; // когда пат у 1 без напарника из-за команды         --командный режим
  final Stalemate commandOnCommandStalemate; // когда пат у 1 с напарником                    --командный режим
   */

  void _makeCastling(int rookIndex){
    int kingIndex = state.kings[state.currentPlayer];
    int newKingIndex = kingIndex;
    int newRookIndex = rookIndex;
    if(rookIndex < kingIndex){
      switch(state.currentPlayer){
        case 0:
          newRookIndex = rookIndex + 3;
          newKingIndex = kingIndex - 2;
        case 1:
          newRookIndex = rookIndex + 3 * BoardData.boardSize;
          newKingIndex = kingIndex - 2 * BoardData.boardSize;
        case 2:
          newRookIndex = rookIndex + 2;
          newKingIndex = kingIndex - 2;
        case 3:
          newRookIndex = rookIndex + 2 * BoardData.boardSize;
          newKingIndex = kingIndex - 2 * BoardData.boardSize;
      }
    } else{
      switch(state.currentPlayer){
        case 0:
          newRookIndex = rookIndex - 2;
          newKingIndex = kingIndex + 2;
        case 1:
          newRookIndex = rookIndex - 2 * BoardData.boardSize;
          newKingIndex = kingIndex + 2 * BoardData.boardSize;
        case 2:
          newRookIndex = rookIndex - 3;
          newKingIndex = kingIndex + 2;
        case 3:
          newRookIndex = rookIndex - 3 * BoardData.boardSize;
          newKingIndex = kingIndex + 2 * BoardData.boardSize;
      }
    }
    List<ChessPiece?> board = List<ChessPiece?>.of(state.board);
    board[newRookIndex] = (board[rookIndex] as Rook).copyWith(hasMoved: true);
    board[newKingIndex] = (board[kingIndex] as King).copyWith(hasMoved: true);
    board[rookIndex] = null;
    board[kingIndex] = null;
    state = state.copyWith(board: board, newPlacementOfKing: newKingIndex);
  }
}

// Онлайн логика
class OnlineGameNotifier extends GameBaseNotifier {
  OnlineGameNotifier(GameConfig config) : super(GameState.initial(config));

  @override
  bool makeMove(int fromIndex, int toIndex) {
    // TODO: implement makeMove
    return false;
  }

  @override
  Stalemate? checkmate() {
    // TODO: implement checkmate
    throw UnimplementedError();
  }



// final SocketClient socket;
// @override
// void makeMove(Move move) {
//   socket.sendMove(move); // Отправляем на Spring Boot
//   // Состояние обновится, когда придет ответ от сервера
// }


//то что ббыло раньше



  // StreamSubscription<String>? _gameSubscription;
  //
  // final WebSocketService _wbService = WebSocketService();
  //
  //
  // GameController() : super(GameState.initial()) {
  //   _listenToWebSocket();
  // }
  //
  // void _listenToWebSocket(){
  //   _gameSubscription = _wbService.gameStream.listen(
  //           (message){
  //         _handleIncomingMessage(message);
  //       },
  //       onError: (error){
  //         print('WebSocket Error: $error');
  //       },
  //       onDone: (){
  //         print('WebSocket Connection closed.');
  //       }
  //   );
  // }
  //
  // void _handleIncomingMessage(String message){
  //
  // }
  //
  //
  // void onTileTapped(int index){
  //
  //   if(state._selectedIndex != -1
  //       && state._availableMoves.contains(index)){
  //     _makeMove(state._selectedIndex, index);
  //     state._selectedIndex = -1;
  //     state._availableMoves = [];
  //     state = sta
  //     return;
  //   }
  //
  //   if(_selectedIndex == index || BoardData.corners.contains(index)){
  //     _selectedIndex = -1;
  //     _availableMoves = [];
  //   }
  //   else if (_board[index] != null){
  //     _selectedIndex = index;
  //     _availableMoves = _board[index]!.getPossibleMoves(index, _board);
  //   } else {
  //     _selectedIndex = -1;
  //     _availableMoves = [];
  //   }
  //   notifyListeners();
  // }
  //
  // void _makeMove(int fromIndex, int toIndex){
  //   final piece = _board[fromIndex];
  //   if (piece==null) return;
  //
  //   _board[fromIndex] = null;
  //   switch(piece.type){
  //     case 'Pawn':
  //       final pawn = piece as Pawn;
  //       _board[toIndex] = pawn.copyWith(hasMoved: true);
  //       break;
  //     case 'King':
  //       final king = piece as King;
  //       _board[toIndex] = king.copyWith(hasMoved: true);
  //       break;
  //     case 'Rook':
  //       final rook = piece as Rook;
  //       _board[toIndex] = rook.copyWith(hasMoved: true);
  //     default:
  //       _board[toIndex] = piece;
  //   }
}