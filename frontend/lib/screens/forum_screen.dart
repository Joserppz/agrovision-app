import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';

class ForumScreen extends StatelessWidget {
  const ForumScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AgroColors.cream,
    appBar: AppBar(
      title: const Text('Foro de la comunidad'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded), 
        onPressed: () => context.pop(),
      ),
    ),
    body: const Center(
      child: Text('Foro — próximamente', 
      style: TextStyle(color: AgroColors.textHint, fontFamily: AgroText.fontBody)),
    ),
  );
}