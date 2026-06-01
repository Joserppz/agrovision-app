import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AgroColors.cream,
    appBar: AppBar(
      title: const Text('Mi perfil'),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Get.back()),
    ),
    body: const Center(child: Text('Perfil — próximamente', style: TextStyle(color: AgroColors.textHint, fontFamily: AgroText.fontBody))),
  );
}