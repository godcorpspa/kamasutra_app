import 'package:flutter/material.dart';
import 'dart:math' as math;

class IntimacyMapScreen extends StatefulWidget {
  const IntimacyMapScreen({super.key});

  @override
  State<IntimacyMapScreen> createState() => _IntimacyMapScreenState();
}

class _IntimacyMapScreenState extends State<IntimacyMapScreen> {
  bool _gameStarted = false;
  int _currentPlayer = 1; // 1 = partner 1 marks, 2 = partner 2 marks
  String _currentBodyPart = '';
  String _selectedView = 'front'; // front or back
  
  // Zones marked by each player
  // Key: body part, Value: map of touch types
  final Map<String, Map<String, int>> _player1Map = {};
  final Map<String, Map<String, int>> _player2Map = {};

  final List<Map<String, dynamic>> _touchTypes = [
    {'id': 'love', 'name': 'Adoro', 'emoji': '💕', 'color': const Color(0xFFEC4899)},
    {'id': 'like', 'name': 'Mi piace', 'emoji': '💜', 'color': const Color(0xFF8B5CF6)},
    {'id': 'neutral', 'name': 'Neutrale', 'emoji': '😐', 'color': const Color(0xFF6B7280)},
    {'id': 'sensitive', 'name': 'Sensibile', 'emoji': '✨', 'color': const Color(0xFFF59E0B)},
    {'id': 'ticklish', 'name': 'Solletico', 'emoji': '🤭', 'color': const Color(0xFF10B981)},
    {'id': 'avoid', 'name': 'Evita', 'emoji': '🚫', 'color': const Color(0xFFEF4444)},
  ];

  final List<Map<String, dynamic>> _bodyPartsFront = [
    {'id': 'forehead', 'name': 'Fronte', 'x': 0.5, 'y': 0.08},
    {'id': 'eyes', 'name': 'Occhi', 'x': 0.5, 'y': 0.12},
    {'id': 'cheeks', 'name': 'Guance', 'x': 0.5, 'y': 0.15},
    {'id': 'lips', 'name': 'Labbra', 'x': 0.5, 'y': 0.18},
    {'id': 'neck_front', 'name': 'Collo', 'x': 0.5, 'y': 0.24},
    {'id': 'shoulders', 'name': 'Spalle', 'x': 0.5, 'y': 0.30},
    {'id': 'chest', 'name': 'Petto', 'x': 0.5, 'y': 0.38},
    {'id': 'arms', 'name': 'Braccia', 'x': 0.25, 'y': 0.45},
    {'id': 'hands', 'name': 'Mani', 'x': 0.2, 'y': 0.58},
    {'id': 'stomach', 'name': 'Pancia', 'x': 0.5, 'y': 0.50},
    {'id': 'hips', 'name': 'Fianchi', 'x': 0.5, 'y': 0.58},
    {'id': 'thighs_front', 'name': 'Cosce', 'x': 0.5, 'y': 0.70},
    {'id': 'knees', 'name': 'Ginocchia', 'x': 0.5, 'y': 0.78},
    {'id': 'calves_front', 'name': 'Polpacci', 'x': 0.5, 'y': 0.86},
    {'id': 'feet', 'name': 'Piedi', 'x': 0.5, 'y': 0.95},
  ];

  final List<Map<String, dynamic>> _bodyPartsBack = [
    {'id': 'head_back', 'name': 'Nuca', 'x': 0.5, 'y': 0.10},
    {'id': 'neck_back', 'name': 'Collo (dietro)', 'x': 0.5, 'y': 0.18},
    {'id': 'upper_back', 'name': 'Schiena alta', 'x': 0.5, 'y': 0.32},
    {'id': 'lower_back', 'name': 'Schiena bassa', 'x': 0.5, 'y': 0.48},
    {'id': 'buttocks', 'name': 'Glutei', 'x': 0.5, 'y': 0.58},
    {'id': 'thighs_back', 'name': 'Cosce (dietro)', 'x': 0.5, 'y': 0.70},
    {'id': 'calves_back', 'name': 'Polpacci (dietro)', 'x': 0.5, 'y': 0.85},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mappa dell\'Intimità',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_gameStarted)
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showInstructions,
            ),
        ],
      ),
      body: _gameStarted ? _buildGameView() : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.map,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mappa dell\'Intimità',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scoprite le zone di piacere reciproche',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),

          // How it works
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Come Funziona',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStep('1', 'A turno, toccate una zona del corpo sulla mappa'),
                const SizedBox(height: 12),
                _buildStep('2', 'Indicate come vi piace essere toccati in quella zona'),
                const SizedBox(height: 12),
                _buildStep('3', 'Scoprite le preferenze del vostro partner'),
                const SizedBox(height: 12),
                _buildStep('4', 'Create una mappa completa dell\'intimità'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Touch types legend
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipi di Sensazione',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _touchTypes.map((type) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (type['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(type['emoji'] as String, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            type['name'] as String,
                            style: TextStyle(
                              color: type['color'] as Color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _gameStarted = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Inizia Esplorazione',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6).withOpacity(0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF14B8A6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameView() {
    return Column(
      children: [
        // Player indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPlayerTab(1, 'Partner 1', const Color(0xFF8B5CF6)),
              const SizedBox(width: 16),
              _buildPlayerTab(2, 'Partner 2', const Color(0xFFEC4899)),
            ],
          ),
        ),

        // View toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildViewToggle('front', 'Fronte'),
              const SizedBox(width: 12),
              _buildViewToggle('back', 'Schiena'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Body map
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildBodyMap(),
          ),
        ),

        // Compare button
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetMaps,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _compareMaps,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Confronta Mappe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerTab(int player, String label, Color color) {
    final isSelected = _currentPlayer == player;
    return GestureDetector(
      onTap: () => setState(() => _currentPlayer = player),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(String view, String label) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () => setState(() => _selectedView = view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBodyMap() {
    final parts = _selectedView == 'front' ? _bodyPartsFront : _bodyPartsBack;
    final currentMap = _currentPlayer == 1 ? _player1Map : _player2Map;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Body silhouette (simplified)
              Center(
                child: CustomPaint(
                  size: Size(constraints.maxWidth * 0.6, constraints.maxHeight * 0.9),
                  painter: BodySilhouettePainter(isFront: _selectedView == 'front'),
                ),
              ),
              // Touch points
              ...parts.map((part) {
                final x = part['x'] as double;
                final y = part['y'] as double;
                final id = part['id'] as String;
                final marking = currentMap[id];
                
                Color? dotColor;
                String? emoji;
                if (marking != null && marking.isNotEmpty) {
                  final touchType = marking.keys.first;
                  final typeData = _touchTypes.firstWhere((t) => t['id'] == touchType);
                  dotColor = typeData['color'] as Color;
                  emoji = typeData['emoji'] as String;
                }
                
                return Positioned(
                  left: constraints.maxWidth * x - 20,
                  top: constraints.maxHeight * y - 20,
                  child: GestureDetector(
                    onTap: () => _selectBodyPart(part),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: dotColor?.withOpacity(0.8) ?? 
                            const Color(0xFF14B8A6).withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dotColor ?? const Color(0xFF14B8A6),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: emoji != null 
                            ? Text(emoji, style: const TextStyle(fontSize: 16))
                            : const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _selectBodyPart(Map<String, dynamic> part) {
    setState(() {
      _currentBodyPart = part['id'] as String;
    });
    _showTouchSelector(part);
  }

  void _showTouchSelector(Map<String, dynamic> part) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                part['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Come ti piace essere toccato/a qui?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _touchTypes.map((type) {
                  return GestureDetector(
                    onTap: () {
                      _markBodyPart(part['id'] as String, type['id'] as String);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: (type['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (type['color'] as Color).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            type['emoji'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type['name'] as String,
                            style: TextStyle(
                              color: type['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _markBodyPart(String partId, String touchType) {
    setState(() {
      if (_currentPlayer == 1) {
        _player1Map[partId] = {touchType: 1};
      } else {
        _player2Map[partId] = {touchType: 1};
      }
    });
  }

  void _resetMaps() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Reset Mappe',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Vuoi cancellare tutte le marcature?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _player1Map.clear();
                _player2Map.clear();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _compareMaps() {
    // Find matching and different zones
    final allParts = {..._player1Map.keys, ..._player2Map.keys};
    
    List<String> matches = [];
    List<String> differences = [];
    
    for (var partId in allParts) {
      final p1Type = _player1Map[partId]?.keys.firstOrNull;
      final p2Type = _player2Map[partId]?.keys.firstOrNull;
      
      // Find name
      String partName = '';
      for (var part in [..._bodyPartsFront, ..._bodyPartsBack]) {
        if (part['id'] == partId) {
          partName = part['name'] as String;
          break;
        }
      }
      
      if (p1Type != null && p2Type != null) {
        if (p1Type == p2Type) {
          matches.add(partName);
        } else {
          differences.add(partName);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🗺️ Confronto Mappe',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_player1Map.isEmpty || _player2Map.isEmpty)
                const Text(
                  'Entrambi i partner devono marcare alcune zone prima di confrontare!',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Zone Compatibili',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        matches.isEmpty 
                            ? 'Nessuna zona con stessa preferenza'
                            : matches.join(', '),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.explore, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Zone da Esplorare',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        differences.isEmpty 
                            ? 'Tutte le zone marcate sono compatibili!'
                            : differences.join(', '),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Partner 1: ${_player1Map.length} zone marcate\n'
                  'Partner 2: ${_player2Map.length} zone marcate',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
            ),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '📖 Istruzioni',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionItem('1', 'Seleziona il tuo profilo (Partner 1 o 2)'),
            const SizedBox(height: 12),
            _buildInstructionItem('2', 'Tocca una zona del corpo sulla mappa'),
            const SizedBox(height: 12),
            _buildInstructionItem('3', 'Indica come ti piace essere toccato lì'),
            const SizedBox(height: 12),
            _buildInstructionItem('4', 'Passa il turno al partner'),
            const SizedBox(height: 12),
            _buildInstructionItem('5', 'Confrontate le mappe alla fine!'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6).withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF14B8A6),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class BodySilhouettePainter extends CustomPainter {
  final bool isFront;
  
  BodySilhouettePainter({required this.isFront});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    
    // Simplified body silhouette
    final centerX = size.width / 2;
    
    // Head
    path.addOval(Rect.fromCenter(
      center: Offset(centerX, size.height * 0.08),
      width: size.width * 0.25,
      height: size.height * 0.1,
    ));
    
    // Neck
    path.addRect(Rect.fromLTWH(
      centerX - size.width * 0.08,
      size.height * 0.13,
      size.width * 0.16,
      size.height * 0.05,
    ));
    
    // Torso
    path.moveTo(centerX - size.width * 0.25, size.height * 0.18);
    path.lineTo(centerX - size.width * 0.2, size.height * 0.55);
    path.lineTo(centerX + size.width * 0.2, size.height * 0.55);
    path.lineTo(centerX + size.width * 0.25, size.height * 0.18);
    path.close();
    
    // Left arm
    path.moveTo(centerX - size.width * 0.25, size.height * 0.18);
    path.lineTo(centerX - size.width * 0.45, size.height * 0.5);
    path.lineTo(centerX - size.width * 0.4, size.height * 0.52);
    path.lineTo(centerX - size.width * 0.22, size.height * 0.22);
    
    // Right arm
    path.moveTo(centerX + size.width * 0.25, size.height * 0.18);
    path.lineTo(centerX + size.width * 0.45, size.height * 0.5);
    path.lineTo(centerX + size.width * 0.4, size.height * 0.52);
    path.lineTo(centerX + size.width * 0.22, size.height * 0.22);
    
    // Left leg
    path.moveTo(centerX - size.width * 0.15, size.height * 0.55);
    path.lineTo(centerX - size.width * 0.18, size.height * 0.95);
    path.lineTo(centerX - size.width * 0.05, size.height * 0.95);
    path.lineTo(centerX - size.width * 0.02, size.height * 0.55);
    
    // Right leg
    path.moveTo(centerX + size.width * 0.15, size.height * 0.55);
    path.lineTo(centerX + size.width * 0.18, size.height * 0.95);
    path.lineTo(centerX + size.width * 0.05, size.height * 0.95);
    path.lineTo(centerX + size.width * 0.02, size.height * 0.55);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
