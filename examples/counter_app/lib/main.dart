import 'package:fcb_code_push/fcb_code_push.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FCB Counter')),
        body: Center(
          child: FutureBuilder<int?>(
            future: FcbCodePush.instance.currentPatchNumber(),
            builder: (context, snapshot) {
              final patch = snapshot.data;
              return Text('Counter: 1\nPatch: ${patch ?? 0}');
            },
          ),
        ),
      ),
    );
  }
}

