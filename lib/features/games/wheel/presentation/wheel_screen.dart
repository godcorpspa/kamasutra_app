import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  double _currentRotation = 0;
  bool _isSpinning = false;
  String _intensity = 'spicy';
  
  final List<WheelSegment> _segments = [
    WheelSegment('Bacio', '💋', AppColors.romantic),
    WheelSegment('Massaggio', '💆', AppColors.soft),
    WheelSegment('Complimento', '💬', AppColors.gold),
    WheelSegment('Sfida', '🎯', AppColors.spicy),
    WheelSegment('Posizione', '🔥', AppColors.burgundy),
    WheelSegment('Fantasia', '✨', AppColors.extraSpicy),
    WheelSegment('Carezza', '🤚', AppColors.blush),
    WheelSegment('Sorpresa', '🎁', AppColors.accent),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;
    
    setState(() {
      _isSpinning = true;
    });
    
    final random = Random();
    final extraSpins = 5 + random.nextInt(3); // 5-7 full rotations
    final targetSegment = random.nextInt(_segments.length);
    final segmentAngle = (2 * pi) / _segments.length;
    final targetAngle = extraSpins * 2 * pi + (targetSegment * segmentAngle) + (segmentAngle / 2);
    
    _animation = Tween<double>(
      begin: _currentRotation,
      end: _currentRotation + targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _animation.addListener(() {
      setState(() {
        _currentRotation = _animation.value;
      });
    });
    
    _controller.forward(from: 0).then((_) {
      setState(() {
        _isSpinning = false;
      });
      _showResultDialog(targetSegment);
    });
  }

  void _showResultDialog(int segmentIndex) {
    final segment = _segments[segmentIndex];
    final action = _getActionForSegment(segment, _intensity);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: segment.color.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: segment.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    segment.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                segment.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: segment.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  action,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _spin();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Gira ancora'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: segment.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Fatto! ✓'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionForSegment(WheelSegment segment, String intensity) {
    final actions = {
      'Bacio': {
        'soft': 'Datevi un bacio dolce sulla fronte',
        'spicy': 'Un bacio appassionato di almeno 30 secondi',
        'extra_spicy': 'Bacio sensuale sul collo per 1 minuto',
      },
      'Massaggio': {
        'soft': 'Massaggio rilassante alle spalle per 2 minuti',
        'spicy': 'Massaggio sensuale alla schiena con olio',
        'extra_spicy': 'Massaggio completo con esplorazione libera',
      },
      'Complimento': {
        'soft': 'Di\' 3 cose che ami del partner',
        'spicy': 'Sussurra all\'orecchio cosa ti attrae di più',
        'extra_spicy': 'Descrivi la tua fantasia preferita con il partner',
      },
      'Sfida': {
        'soft': 'Guardatevi negli occhi per 60 secondi',
        'spicy': 'Spogliati di un indumento a scelta del partner',
        'extra_spicy': 'Il partner sceglie la prossima posizione',
      },
      'Posizione': {
        'soft': 'Abbraccio intimo per 3 minuti',
        'spicy': 'Prova una nuova posizione romantica',
        'extra_spicy': 'Posizione a sorpresa dal catalogo',
      },
      'Fantasia': {
        'soft': 'Racconta un sogno romantico',
        'spicy': 'Condividi una fantasia segreta',
        'extra_spicy': 'Realizza una mini-fantasia del partner',
      },
      'Carezza': {
        'soft': 'Accarezza dolcemente il viso del partner',
        'spicy': 'Carezze sensuali dove sceglie il partner',
        'extra_spicy': 'Esplorazione tattile bendati',
      },
      'Sorpresa': {
        'soft': 'Fai qualcosa di carino per il partner',
        'spicy': 'Il partner sceglie l\'azione',
        'extra_spicy': 'Carta jolly: qualsiasi cosa concordata',
      },
    };
    
    return actions[segment.name]?[intensity] ?? 'Azione speciale!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ruota della Fortuna'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRules,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Intensity selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIntensityChip('soft', '🌸 Soft'),
                  const SizedBox(width: 8),
                  _buildIntensityChip('spicy', '🌶️ Spicy'),
                  const SizedBox(width: 8),
                  _buildIntensityChip('extra_spicy', '🔥 Extra'),
                ],
              ),
            ),
            
            // Wheel
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Wheel
                    Transform.rotate(
                      angle: _currentRotation,
                      child: CustomPaint(
                        size: const Size(300, 300),
                        painter: WheelPainter(segments: _segments),
                      ),
                    ),
                    
                    // Center button
                    GestureDetector(
                      onTap: _isSpinning ? null : _spin,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isSpinning ? AppColors.surface : AppColors.burgundy,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.burgundy.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSpinning
                              ? const CircularProgressIndicator(
                                  color: AppColors.gold,
                                  strokeWidth: 3,
                                )
                              : const Text(
                                  'GIRA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    
                    // Pointer
                    Positioned(
                      top: 0,
                      child: CustomPaint(
                        size: const Size(30, 40),
                        painter: PointerPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Instructions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _isSpinning 
                    ? 'La ruota sta girando...' 
                    : 'Tocca il centro per girare la ruota!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityChip(String value, String label) {
    final isSelected = _intensity == value;
    return GestureDetector(
      onTap: () => setState(() => _intensity = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.burgundy : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showRules() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Come si gioca 🎡',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRuleItem('1', 'Scegli l\'intensità desiderata'),
            _buildRuleItem('2', 'Tocca il centro per girare la ruota'),
            _buildRuleItem('3', 'Segui l\'azione indicata'),
            _buildRuleItem('4', 'Potete sempre saltare e rigirare'),
            const SizedBox(height: 16),
            Text(
              'Ricorda: il consenso viene prima di tutto. Divertitevi! 💕',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.burgundy.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class WheelSegment {
  final String name;
  final String emoji;
  final Color color;
  
  WheelSegment(this.name, this.emoji, this.color);
}

class WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;
  
  WheelPainter({required this.segments});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / segments.length;
    
    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;
      
      // Draw segment
      final paint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );
      
      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );
      
      // Draw emoji
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: segments[i].emoji,
          style: const TextStyle(fontSize: 28),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    
    canvas.drawPath(path, paint);
    
    // Add shadow effect
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(path, shadowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
