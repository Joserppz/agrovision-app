import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: AgroColors.cream,
    appBar: AppBar(
      title: const Text('Mi perfil'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded), 
        onPressed: () => context.pop(),
      ),
    ),
    body: const Center(
      child: Text('Perfil — próximamente', 
      style: TextStyle(color: AgroColors.textHint, fontFamily: AgroText.fontBody)),
    ),
  );
}