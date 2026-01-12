import 'package:flutter/material.dart';

import '../models/chess_piece.dart';

abstract class GameConfig {
  //for user interface
  final Map<int, MaterialColor> playerColors;
  final Map<int, String> playerNames;

  //for program logic
  final Command commands;
  final Promotion pawnPromotion;
  final int promotionCondition; //[3, 14], если 0 - edge with corners

  final bool onlyRegicide; //снимает все ограничения на маты, паты, проиграть можно лишь потеряв короля
  //эти настройки лишь при false
  final Stalemate oneOnOneStalemate; //когда остаётесь 1 на 1                                 --абсолютный приоритет
  final Stalemate aloneAmongAloneStalemate; // когда не 1 на 1 в бескомандном режиме          --одиночный режим
  final Stalemate commandOnOneStalemate; // когда пат у 1 без напарника из-за команды         --командный режим
  final Stalemate commandOnCommandStalemate; // когда пат у 1 с напарником                    --командный режим

  //wait
  final Timer timerType;
  final double timerTime;
  final TimeOut timeOut;//при цареубийстве всегда random

  GameConfig({
    this.playerColors = const {-1 : Colors.grey, 0 : Colors.yellow, 1 : Colors.blue, 2 : Colors.red, 3 : Colors.green},
    this.playerNames = const {0:'игрок 1', 1:'игрок 2', 2:'игрок 3', 3:'игрок 4'},
    this.commands = Command.none,
    this.oneOnOneStalemate = Stalemate.draw,
    this.aloneAmongAloneStalemate = Stalemate.checkmate,
    this.commandOnOneStalemate = Stalemate.draw,
    this.commandOnCommandStalemate = Stalemate.checkmate,
    this.pawnPromotion = Promotion.queen,
    this.promotionCondition = 9,
    this.timerType = Timer.none,
    this.timerTime = double.infinity,
    this.timeOut = TimeOut.randomMoves,
    this.onlyRegicide = false
  });

}

class OfflineConfig extends GameConfig{
  final bool turnPieces; //только для оффлайн
  OfflineConfig({
    super.playerColors,
    super.playerNames,
    super.commands,
    super.onlyRegicide,
    super.oneOnOneStalemate,
    super.aloneAmongAloneStalemate,
    super.commandOnOneStalemate,
    super.commandOnCommandStalemate,
    super.pawnPromotion,
    super.promotionCondition,
    super.timerType,
    super.timerTime,
    super.timeOut,
    this.turnPieces = false
  });
}
class OnlineConfig extends GameConfig{
  final bool publicAccess;
  final LoseConnection ifConnectionIsLost;    //только для онлайн

  OnlineConfig({
    super.playerColors,
    super.playerNames,
    super.commands,
    super.onlyRegicide,
    super.oneOnOneStalemate,
    super.aloneAmongAloneStalemate ,
    super.commandOnOneStalemate,
    super.commandOnCommandStalemate,
    super.pawnPromotion,
    super.promotionCondition,
    super.timerType,
    super.timerTime,
    super.timeOut,
    this.publicAccess = true,
    this.ifConnectionIsLost = LoseConnection.wait
  });
}

enum Timer{none, perPlayer, perMove}
enum Stalemate{checkmate, draw, skipMove}
enum Promotion{queen, choice, random, randomWithPawn, none}
enum LoseConnection{checkmate, wait, randomMoves}
enum Command{none, oppositeSides, adjacentSides, random} // смежные стороны строго 0-1 и 2-3
enum TimeOut{checkmate, randomMoves}