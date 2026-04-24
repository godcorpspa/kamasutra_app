import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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

  List<Map<String, dynamic>> get _challenges => [
    {
      'title': 'games.mirror_challenge.ch1_title'.tr(),
      'description': 'games.mirror_challenge.ch1_desc'.tr(),
      'icon': Icons.pan_tool,
      'tip': 'games.mirror_challenge.ch1_tip'.tr(),
    },
    {
      'title': 'games.mirror_challenge.ch2_title'.tr(),
      'description': 'games.mirror_challenge.ch2_desc'.tr(),
      'icon': Icons.face,
      'tip': 'games.mirror_challenge.ch2_tip'.tr(),
    },
    {
      'title': 'games.mirror_challenge.ch3_title'.tr(),
      'description': 'games.mirror_challenge.ch3_desc'.tr(),
      'icon': Icons.accessibility_new,
      'tip': 'games.mirror_challenge.ch3_tip'.tr(),
    },
    {
      'title': 'games.mirror_challenge.ch4_title'.tr(),
      'description': 'games.mirror_challenge.ch4_desc'.tr(),
      'icon': Icons.air,
      'tip': 'games.mirror_challenge.ch4_tip'.tr(),
    },
    {
      'title': 'games.mirror_challenge.ch5_title'.tr(),
      'description': 'games.mirror_challenge.ch5_desc'.tr(),
      'icon': Icons.visibility_off,
      'tip': 'games.mirror_challenge.ch5_tip'.tr(),
    },
    {
      'title': 'games.mirror_challenge.ch6_title'.tr(),
      'description': 'games.mirror_challenge.ch6_desc'.tr(),
      'icon': Icons.slow_motion_video,
      'tip': 'games.mirror_challenge.ch6_tip'.tr(),
    },
    {
      'title': 'games.mirror_challenge.ch7_title'.tr(),
      'description': 'games.mirror_challenge.ch7_desc'.tr(),
      'icon': Icons.person,
      'tip': 'games.mirror_challenge.ch7_tip'.tr(),
    },
    {
      'title': 'games.mirror_challenge.ch8_title'.tr(),
      'description': 'games.mirror_challenge.ch8_desc'.tr(),
      'icon': Icons.people,
      'tip': 'games.mirror_challenge.ch8_tip'.tr(),
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
        title: Text(
          'games.mirror_challenge.round_complete_title'.tr(),
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'games.mirror_challenge.connection_how'.tr(),
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeedbackButton('😕', 'games.mirror_challenge.feedback_hard'.tr()),
                _buildFeedbackButton('😊', 'games.mirror_challenge.feedback_good'.tr()),
                _buildFeedbackButton('🤩', 'games.mirror_challenge.feedback_perfect'.tr()),
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
              child: Text('games.mirror_challenge.next_round'.tr()),
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
        title: Text(
          'games.mirror_challenge.session_complete_title'.tr(),
          style: const TextStyle(color: Colors.white),
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
                  Text(
                    'games.mirror_challenge.all_rounds_complete'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'games.mirror_challenge.connection_builds'.tr(),
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
            child: Text('games.mirror_challenge.exit'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD946EF),
            ),
            child: Text('games.mirror_challenge.play_again'.tr()),
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
        title: Text(
          'games.mirror_challenge.app_bar_title'.tr(),
          style: const TextStyle(
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
          Text(
            'games.mirror_challenge.app_bar_title'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'games.mirror_challenge.subtitle_desc'.tr(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Difficulty selector
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'games.mirror_challenge.difficulty'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDifficultyOption('easy', 'games.mirror_challenge.easy'.tr(), '30s', 30),
              const SizedBox(width: 12),
              _buildDifficultyOption('medium', 'games.mirror_challenge.medium'.tr(), '60s', 60),
              const SizedBox(width: 12),
              _buildDifficultyOption('hard', 'games.mirror_challenge.hard'.tr(), '90s', 90),
            ],
          ),
          const SizedBox(height: 24),

          // Rounds selector
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'games.mirror_challenge.number_of_rounds'.tr(),
              style: const TextStyle(
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
                Text(
                  'games.mirror_challenge.how_to_play'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructionRow(
                  Icons.person,
                  'games.mirror_challenge.instruction_1'.tr(),
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.people,
                  'games.mirror_challenge.instruction_2'.tr(),
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.swap_horiz,
                  'games.mirror_challenge.instruction_3'.tr(),
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.favorite,
                  'games.mirror_challenge.instruction_4'.tr(),
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
              child: Text(
                'games.mirror_challenge.start_challenge'.tr(),
                style: const TextStyle(
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
            'games.mirror_challenge.round_of'.tr(namedArgs: {'current': '${_currentRound + 1}', 'total': '$_totalRounds'}),
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
              'games.mirror_challenge.partner_leads'.tr(namedArgs: {'player': '$_currentLeader'}),
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
              label: Text('games.mirror_challenge.start_seconds'.tr(namedArgs: {'seconds': '$_roundDuration'})),
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
            'games.mirror_challenge.partner_guides'.tr(namedArgs: {'player': '$_currentLeader'}),
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
                      'games.mirror_challenge.seconds'.tr(),
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
              'games.mirror_challenge.end_early'.tr(),
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
