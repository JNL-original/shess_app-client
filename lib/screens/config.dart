import 'dart:math';

import 'package:chess_app/configs/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/providers.dart';

class ConfigScreen extends ConsumerWidget{
  const ConfigScreen({super.key, required this.onlineMode});
  final bool onlineMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
          title: Text("Шахматы на 4-х", style: Theme.of(context).textTheme.displayLarge,),
        ),
        body: LayoutBuilder(builder: (context, constraints){
          return Center(
            child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 300, minHeight: 100, maxWidth: max(300, constraints.maxWidth/3), maxHeight: max(100, constraints.maxHeight/6)),
                child: SizedBox.expand(
                  child: Column(
                    spacing: max(30, constraints.maxHeight/15),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                            onPressed: (){
                              if(!onlineMode){
                                ref.read(offlineConfigProvider.notifier).update((state) => OfflineConfig());
                                context.go("/offline");
                              }
                              else{
                                context.go('/online/12345');
                              }
                            },
                            child: Text("Создать игру")
                        ),
                      ),
                    ],
                  ),
                )
            ),
          );
        })
    );
  }

}