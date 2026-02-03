import 'dart:async';
import 'package:flutter/material.dart';

class MirrorChallengeScreen extends StatefulWidget {
  const MirrorChallengeScreen({super.key});

  @override
  State<MirrorChallengeScreen> createState() => _MirrorChallengeScreenState();
}

class _MirrorChallengeScreenState extends State<MirrorChallengeScreen>
    with TickerProviderStateMixin {
  bool _gameStarted = false;
  bool _roundActive = false;
  int _currentRound = 0;
  int _currentLeader = 1; // Who leads the movement
  String _selectedDifficulty = 'medium';
  int _roundDuration = 60; // seconds
  
  Timer? _timer;
  int _remainingTime = 60;
  int _totalRounds = 5;
  
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  final List<Map<String, dynamic>> _challenges = [
    {
      'title': 'Mani Danzanti',
      'description': 'Il leader muove le mani lentamente. Il partner rispecchia ogni movimento.',
      'icon': Icons.pan_tool,
      'tip': 'Iniziate con movimenti lenti e fluidi',
    },
    {
      'title': 'Espressioni Facciali',
      'description': 'Cambiate espressioni lentamente. Il partner deve imitare ogni sfumatura.',
      'icon': Icons.face,
      'tip': 'Passate da un\'emozione all\'altra gradualmente',
    },
    {
      'title': 'Danza del Corpo',
      'description': 'Movimenti dolci di tutto il corpo. Restate sincronizzati.',
      'icon': Icons.accessibility_new,
      'tip': 'Muovetevi come se foste sott\'acqua',
    },
    {
      'title': 'Respiro Sincronizzato',
      'description': 'Il leader guida il ritmo del respiro con gesti delle mani.',
      'icon': Icons.air,
      'tip': 'Inspirate quando le mani salgono, espirate quando scendono',
    },
    {
      'title': 'Occhi Chiusi',
      'description': 'Chiudete gli occhi. Toccatevi le mani e muovetevi insieme.',
      'icon': Icons.visibility_off,
      'tip': 'Fidatevi del tatto per restare sincronizzati',
    },
    {
      'title': 'Rallentatore',
      'description': 'Ogni movimento al rallentatore estremo. Massima concentrazione.',
      'icon': Icons.slow_motion_video,
      'tip': 'Più lento è meglio. Sentite ogni micro-movimento.',
    },
    {
      'title': 'Scultura Vivente',
      'description': 'Il leader crea pose. Il partner le replica esattamente.',
      'icon': Icons.person,
      'tip': 'Mantenete ogni posa per 5 secondi prima di passare alla successiva',
    },
    {
      'title': 'Avvicinamento',
      'description': 'Partite distanti. Avvicinatevi lentamente mantenendo il rispecchiamento.',
      'icon': Icons.people,
      'tip': 'L\'obiettivo finale è toccarvi le punte delle dita',
    },
  ];

  List<Map<String, dynamic>> _sessionChallenges = [];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _startGame() {
    _sessionChallenges = List.from(_challenges)..shuffle();
    _sessionChallenges = _sessionChallenges.take(_totalRounds).toList();
    
    setState(() {
      _gameStarted = true;
      _currentRound = 0;
      _currentLeader = 1;
      _roundActive = false;
    });
  }

  void _startRound() {
    setState(() {
      _roundActive = true;
      _remainingTime = _roundDuration;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
          _endRound();
        }
      });
    });
  }

  void _endRound() {
    _timer?.cancel();
    setState(() {
      _roundActive = false;
    });
    
    if (_currentRound < _sessionChallenges.length - 1) {
      _showRoundComplete();
    } else {
      _showGameComplete();
    }
  }

  void _showRoundComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '✨ Round Completato!',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Com\'è stata la connessione?',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeedbackButton('😕', 'Difficile'),
                _buildFeedbackButton('😊', 'Buono'),
                _buildFeedbackButton('🤩', 'Perfetto'),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _nextRound();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD946EF),
              ),
              child: const Text('Prossimo Round'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(String emoji, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _nextRound() {
    setState(() {
      _currentRound++;
      _currentLeader = _currentLeader == 1 ? 2 : 1;
    });
  }

  void _showGameComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🪞 Sessione Completata!',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD946EF).withOpacity(0.2),
                    const Color(0xFF8B5CF6).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Color(0xFFD946EF),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Avete completato tutti i round!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La connessione si costruisce un movimento alla volta.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Esci'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD946EF),
            ),
            child: const Text('Gioca Ancora'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sfida allo Specchio',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _gameStarted ? _buildGameView() : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header with animation
          ScaleTransition(
            scale: _breathAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD946EF), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.people,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sfida allo Specchio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Muovetevi come se foste una sola persona',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Difficulty selector
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Difficoltà',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDifficultyOption('easy', 'Facile', '30s', 30),
              const SizedBox(width: 12),
              _buildDifficultyOption('medium', 'Medio', '60s', 60),
              const SizedBox(width: 12),
              _buildDifficultyOption('hard', 'Difficile', '90s', 90),
            ],
          ),
          const SizedBox(height: 24),

          // Rounds selector
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Numero di Round',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRoundsOption(3),
              const SizedBox(width: 12),
              _buildRoundsOption(5),
              const SizedBox(width: 12),
              _buildRoundsOption(7),
            ],
          ),
          const SizedBox(height: 32),

          // How to play
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Come Giocare',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructionRow(
                  Icons.person,
                  'Un partner guida i movimenti',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.people,
                  'L\'altro li rispecchia come uno specchio',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.swap_horiz,
                  'A ogni round ci si scambia i ruoli',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.favorite,
                  'Restate connessi e sincronizzati',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD946EF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Inizia Sfida',
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

  Widget _buildDifficultyOption(String id, String name, String time, int seconds) {
    final isSelected = _selectedDifficulty == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedDifficulty = id;
          _roundDuration = seconds;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFD946EF) 
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFFD946EF) 
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundsOption(int rounds) {
    final isSelected = _totalRounds == rounds;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _totalRounds = rounds),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFD946EF) 
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFFD946EF) 
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          child: Text(
            '$rounds',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD946EF), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameView() {
    if (!_roundActive) {
      return _buildPreRoundView();
    }
    return _buildActiveRoundView();
  }

  Widget _buildPreRoundView() {
    final challenge = _sessionChallenges[_currentRound];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress
          Text(
            'Round ${_currentRound + 1} di $_totalRounds',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentRound + 1) / _totalRounds,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD946EF)),
          ),
          
          const Spacer(),
          
          // Leader indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _currentLeader == 1
                  ? const Color(0xFF8B5CF6).withOpacity(0.3)
                  : const Color(0xFFEC4899).withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Partner $_currentLeader guida',
              style: TextStyle(
                color: _currentLeader == 1
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFFEC4899),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Challenge card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFD946EF).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD946EF).withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD946EF).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    challenge['icon'] as IconData,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  challenge['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  challenge['description'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          challenge['tip'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Start round button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startRound,
              icon: const Icon(Icons.play_arrow),
              label: Text('Inizia ($_roundDuration secondi)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD946EF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRoundView() {
    final challenge = _sessionChallenges[_currentRound];
    final progress = 1 - (_remainingTime / _roundDuration);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Timer
          Text(
            challenge['title'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Partner $_currentLeader guida',
            style: TextStyle(
              color: _currentLeader == 1
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFFEC4899),
            ),
          ),
          
          const Spacer(),
          
          // Big timer
          ScaleTransition(
            scale: _breathAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remainingTime <= 10
                          ? Colors.red
                          : const Color(0xFFD946EF),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_remainingTime',
                      style: TextStyle(
                        color: _remainingTime <= 10 ? Colors.red : Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'secondi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Tip reminder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    challenge['tip'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // End early button
          TextButton(
            onPressed: _endRound,
            child: Text(
              'Termina Prima',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
