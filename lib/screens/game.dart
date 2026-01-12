
import 'package:chess_app/models/board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/chess_piece.dart';
import '../services/providers.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key, required this.onlineMode, this.id});
  final bool onlineMode;
  final String? id;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
        title: Text("Шахматы на 4-х", style: Theme.of(context).textTheme.displayLarge,),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(""),//заглушка//Text("Время: 00:00", style: Theme.of(context).textTheme.bodyMedium,),
                  Text("Offline режим", style: Theme.of(context).textTheme.bodyMedium,),
                ],
              ),
            ),
            const CurrentTurn(),
            SizedBox(height: 10,),
            _boardView()       // критерий что жив  state.alive.fold(0, (prev, alive) => prev + (alive ? 1 : 0)) > 1
          ],
        ),
      )
    );
  }

  Widget _boardView(){
    return Expanded(
      child: Center(
        child: InteractiveViewer(
          //boundaryMargin: const EdgeInsets.all(5.0), // Отступ, чтобы не упираться в края
          minScale: 1, // Минимальный зум
          maxScale: 4.0, // Максимальный зум (в 4 раза)
          child: FittedBox(
            fit: BoxFit.contain, // Вписывает доску в экран, сохраняя пропорции
            child: Padding(
              padding: const EdgeInsets.all(10), // Небольшой отступ «внутри» масштабирования
              child: SizedBox(
                // Задаем жесткий базовый размер.
                // FittedBox растянет или сожмет этот квадрат под экран устройства.
                width: 800,
                height: 800,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: BoardData.boardSize,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: BoardData.totalTiles,
                  itemBuilder: (context, index) {
                    return ChessTile(index: index,);
                  },
                ),
              ),
            ),
          ),
        ),
      )
    );
  }


}

class CurrentTurn extends ConsumerWidget{
  const CurrentTurn({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myConfig = ref.watch(offlineConfigProvider);
    final currentPlayer = ref.watch(boardOfflineProvider(myConfig).select(
        (state) => state.currentPlayer
    ));
    return RichText(
      text: TextSpan(
        text: 'Ходит: ',
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          TextSpan(
            text: 'игрок ${currentPlayer + 1}',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: myConfig.playerColors[currentPlayer],
              shadows: [
                Shadow(offset: Offset(-1, -1), color: Colors.black),
                Shadow(offset: Offset(1, -1), color: Colors.black),
                Shadow(offset: Offset(1, 1), color: Colors.black),
                Shadow(offset: Offset(-1, 1), color: Colors.black),
              ],
            )
          )
        ],
      ),
    );
  }

}


class ChessTile extends ConsumerWidget {
  const ChessTile({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final myConfig = ref.watch(offlineConfigProvider);


    final piece = ref.watch(boardOfflineProvider(myConfig).select(
      (state) => state.board[index],
    ));
    final isSelected = ref.watch(boardOfflineProvider(myConfig).select(
      (state) => state.selectedIndex == index
    ));
    final isAvailable = ref.watch(boardOfflineProvider(myConfig).select(
      (state) => state.availableMoves.contains(index)
    ));

    return GestureDetector(
      onTap: () => {ref.read(boardOfflineProvider(myConfig).notifier).onTileTapped(index)},
      child: Container(
        color: _getTileColor(index: index, isSelected: isSelected, isAvailable: isAvailable, piece: piece),
        child: Center(
          child: piece == null ? null : Stack(
            children: [
              SvgPicture.asset(
                'assets/pieces/${piece.type}.svg',
                colorFilter: ColorFilter.mode(myConfig.playerColors[piece.owner]!, BlendMode.srcIn),
                width: 60,
              ),
              SvgPicture.asset(
                'assets/pieces/${piece.type}_details.svg',
                placeholderBuilder: (context) => CircularProgressIndicator(),
                width: 60,
              ),
            ],
          )
        ),
      ),
    );
  }

  Color _getTileColor({required int index, required bool isSelected, required bool isAvailable, required ChessPiece? piece}){
    final int row = index ~/ BoardData.boardSize;
    final int col = index % BoardData.boardSize;

    if (isSelected) {
      return Colors.blue.shade400;
    }

    if (isAvailable){
      if(piece == null){
        return Colors.green.shade200;
      }
      else{
        return Colors.red.shade600;
      }
    }

    if(BoardData.corners.contains(index)){
      return Colors.transparent;
    }

    return (row + col)%2==0 ? Colors.brown.shade200 : Colors.brown.shade800;
  }

}