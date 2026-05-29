// lib/screens/map_screen.dart
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0E2),
      appBar: AppBar(
        title: const Text('Mapa de Enfermedades', style: TextStyle(color: Color(0xFF2D5A27), fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () {})],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            color: const Color(0xFFFDFBF7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _filterChip('Todos', true),
                _filterChip('Tizón', false),
                _filterChip('Septoria', false),
                _filterChip('Arañuela', false),
              ],
            ),
          ),
          // Mapa (Simulado con fondo cuadriculado e iconos)
          Expanded(
            child: Stack(
              children: [
                // Fondo cuadriculado simulando mapa
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://www.transparenttextures.com/patterns/grid-me.png'),
                      repeat: ImageRepeat.repeat,
                      colorFilter: ColorFilter.mode(Colors.green.withOpacity(0.1), BlendMode.srcATop)
                    )
                  ),
                ),
                // Puntos simulados
                Positioned(top: 80, left: 100, child: _mapPin(const Color(0xFFC0392B))), // Tizón
                Positioned(top: 150, left: 220, child: _mapPin(const Color(0xFFE67E22))), // Septoria
                Positioned(top: 250, left: 80, child: _mapPin(const Color(0xFF8E44AD))),  // Arañuela
                Positioned(top: 300, left: 200, child: _mapPin(const Color(0xFF27AE60))), // Sana
                
                // Leyenda
                Positioned(
                  bottom: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECE8DF))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LEYENDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2D5A27))),
                        const SizedBox(height: 6),
                        _legendItem(const Color(0xFFC0392B), 'Tizón Tardío'),
                        _legendItem(const Color(0xFFE67E22), 'Septoria'),
                        _legendItem(const Color(0xFF8E44AD), 'Arañuela Roja'),
                        _legendItem(const Color(0xFF27AE60), 'Planta Sana'),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2D5A27) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? const Color(0xFF2D5A27) : Colors.grey.shade300),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
    );
  }

  Widget _mapPin(Color color) {
    return Icon(Icons.location_on, color: color, size: 40);
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B4423))),
        ],
      ),
    );
  }
}