import 'package:flutter/material.dart';
import '../core/constants.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AgroColors.brown.withOpacity(0.9),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
          SizedBox(width: 8),
          Text(
            'Sin conexión — modo offline activo',
            style: TextStyle(
              fontFamily: AgroText.fontBody,
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}