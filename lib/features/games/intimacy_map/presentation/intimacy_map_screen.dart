import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user_data.dart';
import '../../../../data/services/firebase_user_service.dart';
import '../../../../data/providers/user_data_provider.dart';

class IntimacyMapScreen extends ConsumerStatefulWidget {
  const IntimacyMapScreen({super.key});

  @override
  ConsumerState<IntimacyMapScreen> createState() => _IntimacyMapScreenState();
}

class _IntimacyMapScreenState extends ConsumerState<IntimacyMapScreen> {
  bool _gameStarted = false;
  bool _isLoading = false;
  int _currentPlayer = 1;
  String _currentBodyPart = '';
  String _selectedView = 'front';
  
  // Zones marked by each player
  Map<String, Map<String, int>> _player1Map = {};
  Map<String, Map<String, int>> _player2Map = {};

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
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await FirebaseUserService().getIntimacyMap();
      setState(() {
        _player1Map = Map<String, Map<String, int>>.from(
          data.player1Map.map((k, v) => MapEntry(k, Map<String, int>.from(v)))
        );
        _player2Map = Map<String, Map<String, int>>.from(
          data.player2Map.map((k, v) => MapEntry(k, Map<String, int>.from(v)))
        );
      });
    } catch (e) {
      debugPrint('Error loading intimacy map: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    
    try {
      await FirebaseUserService().saveIntimacyMap(IntimacyMapData(
        player1Map: _player1Map,
        player2Map: _player2Map,
      ));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mappa salvata! 🗺️'),
          backgroundColor: Color(0xFF14B8A6),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startGame() {
    setState(() => _gameStarted = true);
    
    // Record game played
    ref.read(progressNotifierProvider.notifier).incrementGamesPlayed();
  }

  Map<String, Map<String, int>> get _currentPlayerMap => 
      _currentPlayer == 1 ? _player1Map : _player2Map;

  void _setCurrentPlayerMap(Map<String, Map<String, int>> map) {
    setState(() {
      if (_currentPlayer == 1) {
        _player1Map = map;
      } else {
        _player2Map = map;
      }
    });
  }

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
          if (_gameStarted) ...[
            IconButton(
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveData,
              tooltip: 'Salva mappa',
            ),
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              onPressed: _showComparison,
              tooltip: 'Confronta',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: _isLoading && !_gameStarted
          ? const Center(child: CircularProgressIndicator())
          : _gameStarted 
              ? _buildGameView() 
              : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    final hasExistingData = _player1Map.isNotEmpty || _player2Map.isNotEmpty;
    
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
            child: const Icon(Icons.map, size: 50, color: Colors.white),
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
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          ),
          
          if (hasExistingData) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF14B8A6).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done, color: Color(0xFF14B8A6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mappa salvata trovata!',
                          style: TextStyle(
                            color: Color(0xFF14B8A6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Partner 1: ${_player1Map.length} zone • Partner 2: ${_player2Map.length} zone',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
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

          // Start/Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                hasExistingData ? 'Continua a mappare 🗺️' : 'Inizia a mappare 🗺️',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameView() {
    final bodyParts = _selectedView == 'front' ? _bodyPartsFront : _bodyPartsBack;
    
    return Column(
      children: [
        // Player selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentPlayer = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentPlayer == 1 
                          ? const Color(0xFFEC4899).withOpacity(0.3) 
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentPlayer == 1 
                            ? const Color(0xFFEC4899) 
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Partner 1',
                          style: TextStyle(
                            color: _currentPlayer == 1 
                                ? const Color(0xFFEC4899) 
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_player1Map.length} zone',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentPlayer = 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentPlayer == 2 
                          ? const Color(0xFF8B5CF6).withOpacity(0.3) 
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentPlayer == 2 
                            ? const Color(0xFF8B5CF6) 
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Partner 2',
                          style: TextStyle(
                            color: _currentPlayer == 2 
                                ? const Color(0xFF8B5CF6) 
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_player2Map.length} zone',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // View toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildViewToggle('front', 'Davanti'),
              const SizedBox(width: 12),
              _buildViewToggle('back', 'Dietro'),
            ],
          ),
        ),
        
        // Body map
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Body silhouette
                  Center(
                    child: CustomPaint(
                      size: Size(constraints.maxWidth * 0.6, constraints.maxHeight * 0.85),
                      painter: BodySilhouettePainter(isFront: _selectedView == 'front'),
                    ),
                  ),
                  
                  // Body part buttons
                  ...bodyParts.map((part) {
                    final currentMap = _currentPlayerMap;
                    final marking = currentMap[part['id']]?['touchType'];
                    final touchType = marking != null 
                        ? _touchTypes.firstWhere((t) => t['id'] == marking, orElse: () => _touchTypes[0])
                        : null;
                    
                    return Positioned(
                      left: constraints.maxWidth * (part['x'] as double) - 20,
                      top: constraints.maxHeight * (part['y'] as double) - 20,
                      child: GestureDetector(
                        onTap: () => _selectBodyPart(part['id'] as String, part['name'] as String),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: touchType != null 
                                ? (touchType['color'] as Color).withOpacity(0.8)
                                : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _currentBodyPart == part['id']
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              touchType != null 
                                  ? touchType['emoji'] as String
                                  : '•',
                              style: const TextStyle(fontSize: 16),
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
        ),
        
        // Touch type selector
        if (_currentBodyPart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Text(
                  'Come ti piace essere toccato qui?',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _touchTypes.map((type) {
                    return GestureDetector(
                      onTap: () => _markZone(type['id'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: (type['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (type['color'] as Color).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(type['emoji'] as String),
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
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildViewToggle(String view, String label) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () => setState(() => _selectedView = view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF14B8A6) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF14B8A6) : Colors.white30,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _selectBodyPart(String id, String name) {
    setState(() {
      _currentBodyPart = id;
    });
  }

  void _markZone(String touchType) {
    if (_currentBodyPart.isEmpty) return;
    
    final newMap = Map<String, Map<String, int>>.from(_currentPlayerMap);
    newMap[_currentBodyPart] = {'touchType': _touchTypes.indexWhere((t) => t['id'] == touchType)};
    
    // Store by touch type id instead of index for clarity
    final touchTypeMap = <String, int>{};
    touchTypeMap['touchType'] = _touchTypes.indexWhere((t) => t['id'] == touchType);
    newMap[_currentBodyPart] = touchTypeMap;
    
    _setCurrentPlayerMap(newMap);
    
    setState(() {
      _currentBodyPart = '';
    });
  }

  void _showComparison() {
    // Find matches and differences
    final allParts = {..._player1Map.keys, ..._player2Map.keys};
    final matches = <String>[];
    final differences = <String>[];
    
    for (final part in allParts) {
      final p1Touch = _player1Map[part]?['touchType'];
      final p2Touch = _player2Map[part]?['touchType'];
      
      if (p1Touch != null && p2Touch != null) {
        if (p1Touch == p2Touch) {
          final partName = [..._bodyPartsFront, ..._bodyPartsBack]
              .firstWhere((p) => p['id'] == part, orElse: () => {'name': part})['name'];
          matches.add(partName as String);
        } else {
          final partName = [..._bodyPartsFront, ..._bodyPartsBack]
              .firstWhere((p) => p['id'] == part, orElse: () => {'name': part})['name'];
          differences.add(partName as String);
        }
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('📊 Confronto', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      matches.isEmpty ? 'Nessuna zona con stessa preferenza' : matches.join(', '),
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
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      differences.isEmpty ? 'Tutte le zone marcate sono compatibili!' : differences.join(', '),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Partner 1: ${_player1Map.length} zone marcate\nPartner 2: ${_player2Map.length} zone marcate',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6)),
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
        title: const Text('📖 Istruzioni', style: TextStyle(color: Colors.white)),
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
            _buildInstructionItem('4', 'Salva e confrontate le mappe!'),
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
          child: Text(text, style: const TextStyle(color: Colors.white70)),
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
    
    // Arms
    path.moveTo(centerX - size.width * 0.25, size.height * 0.18);
    path.lineTo(centerX - size.width * 0.45, size.height * 0.5);
    path.lineTo(centerX - size.width * 0.4, size.height * 0.52);
    path.lineTo(centerX - size.width * 0.22, size.height * 0.22);
    
    path.moveTo(centerX + size.width * 0.25, size.height * 0.18);
    path.lineTo(centerX + size.width * 0.45, size.height * 0.5);
    path.lineTo(centerX + size.width * 0.4, size.height * 0.52);
    path.lineTo(centerX + size.width * 0.22, size.height * 0.22);
    
    // Legs
    path.moveTo(centerX - size.width * 0.15, size.height * 0.55);
    path.lineTo(centerX - size.width * 0.18, size.height * 0.95);
    path.lineTo(centerX - size.width * 0.05, size.height * 0.95);
    path.lineTo(centerX - size.width * 0.02, size.height * 0.55);
    
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
