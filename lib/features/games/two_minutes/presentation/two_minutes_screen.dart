import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TwoMinutesScreen extends StatefulWidget {
  const TwoMinutesScreen({super.key});

  @override
  State<TwoMinutesScreen> createState() => _TwoMinutesScreenState();
}

class _TwoMinutesScreenState extends State<TwoMinutesScreen>
    with TickerProviderStateMixin {
  bool _gameStarted = false;
  bool _challengeActive = false;
  bool _isPaused = false;
  int _currentChallengeIndex = 0;
  String _selectedIntensity = 'spicy';
  int _selectedDuration = 120; // 2 minutes default

  Timer? _timer;
  int _remainingSeconds = 120;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _countdownController;

  Map<String, List<Map<String, dynamic>>> get _challenges => {
    'soft': [
      {
        'title': 'games.two_minutes.soft.deep_gaze_title'.tr(),
        'description': 'games.two_minutes.soft.deep_gaze_desc'.tr(),
        'icon': Icons.visibility,
      },
      {
        'title': 'games.two_minutes.soft.hand_massage_title'.tr(),
        'description': 'games.two_minutes.soft.hand_massage_desc'.tr(),
        'icon': Icons.pan_tool,
      },
      {
        'title': 'games.two_minutes.soft.whispers_title'.tr(),
        'description': 'games.two_minutes.soft.whispers_desc'.tr(),
        'icon': Icons.hearing,
      },
      {
        'title': 'games.two_minutes.soft.sync_breathing_title'.tr(),
        'description': 'games.two_minutes.soft.sync_breathing_desc'.tr(),
        'icon': Icons.air,
      },
      {
        'title': 'games.two_minutes.soft.light_caresses_title'.tr(),
        'description': 'games.two_minutes.soft.light_caresses_desc'.tr(),
        'icon': Icons.face,
      },
    ],
    'spicy': [
      {
        'title': 'games.two_minutes.spicy.exploring_kisses_title'.tr(),
        'description': 'games.two_minutes.spicy.exploring_kisses_desc'.tr(),
        'icon': Icons.favorite,
      },
      {
        'title': 'games.two_minutes.spicy.neck_massage_title'.tr(),
        'description': 'games.two_minutes.spicy.neck_massage_desc'.tr(),
        'icon': Icons.spa,
      },
      {
        'title': 'games.two_minutes.spicy.total_hug_title'.tr(),
        'description': 'games.two_minutes.spicy.total_hug_desc'.tr(),
        'icon': Icons.people,
      },
      {
        'title': 'games.two_minutes.spicy.slow_dance_title'.tr(),
        'description': 'games.two_minutes.spicy.slow_dance_desc'.tr(),
        'icon': Icons.music_note,
      },
      {
        'title': 'games.two_minutes.spicy.blind_touch_title'.tr(),
        'description': 'games.two_minutes.spicy.blind_touch_desc'.tr(),
        'icon': Icons.touch_app,
      },
    ],
    'extra_spicy': [
      {
        'title': 'games.two_minutes.extra_spicy.sensitive_spots_title'.tr(),
        'description': 'games.two_minutes.extra_spicy.sensitive_spots_desc'.tr(),
        'icon': Icons.whatshot,
      },
      {
        'title': 'games.two_minutes.extra_spicy.back_massage_title'.tr(),
        'description': 'games.two_minutes.extra_spicy.back_massage_desc'.tr(),
        'icon': Icons.self_improvement,
      },
      {
        'title': 'games.two_minutes.extra_spicy.kisses_everywhere_title'.tr(),
        'description': 'games.two_minutes.extra_spicy.kisses_everywhere_desc'.tr(),
        'icon': Icons.local_fire_department,
      },
      {
        'title': 'games.two_minutes.extra_spicy.tactile_exploration_title'.tr(),
        'description': 'games.two_minutes.extra_spicy.tactile_exploration_desc'.tr(),
        'icon': Icons.explore,
      },
      {
        'title': 'games.two_minutes.extra_spicy.total_connection_title'.tr(),
        'description': 'games.two_minutes.extra_spicy.total_connection_desc'.tr(),
        'icon': Icons.bolt,
      },
    ],
  };

  List<Map<String, dynamic>> _currentChallenges = [];
  int _completedChallenges = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdownController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _startGame() {
    _currentChallenges = List.from(_challenges[_selectedIntensity]!);
    _currentChallenges.shuffle();

    setState(() {
      _gameStarted = true;
      _currentChallengeIndex = 0;
      _completedChallenges = 0;
      _challengeActive = false;
    });
  }

  void _startChallenge() {
    setState(() {
      _challengeActive = true;
      _remainingSeconds = _selectedDuration;
      _isPaused = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            _onChallengeComplete();
          }
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _onChallengeComplete() {
    setState(() {
      _completedChallenges++;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, color: Color(0xFFEC4899)),
            const SizedBox(width: 8),
            Text(
              'games.two_minutes.time_up'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'games.two_minutes.how_was_it'.tr(),
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endSession();
            },
            child: Text('games.two_minutes.end'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nextChallenge();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
            ),
            child: Text('games.two_minutes.next_challenge'.tr()),
          ),
        ],
      ),
    );
  }

  void _nextChallenge() {
    if (_currentChallengeIndex < _currentChallenges.length - 1) {
      setState(() {
        _currentChallengeIndex++;
        _challengeActive = false;
      });
    } else {
      _endSession();
    }
  }

  void _skipChallenge() {
    _timer?.cancel();
    _nextChallenge();
  }

  void _endSession() {
    _timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'games.two_minutes.session_complete'.tr(),
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'games.two_minutes.special_moment'.tr(),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.2),
                    const Color(0xFFF97316).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'games.two_minutes.challenges_completed'.tr(),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_completedChallenges',
                    style: const TextStyle(
                      color: Color(0xFFEC4899),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'games.two_minutes.of_total'.tr(args: [_currentChallenges.length.toString()]),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('games.two_minutes.exit'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
            ),
            child: Text('games.two_minutes.play_again'.tr()),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'games.two_minutes.title'.tr(),
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
      body: _gameStarted
          ? (_challengeActive ? _buildChallengeView() : _buildPreChallengeView())
          : _buildSetupView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.timer,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'games.two_minutes.subtitle'.tr(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Duration Selection
          Text(
            'games.two_minutes.challenge_duration'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDurationOption(60, 'games.two_minutes.dur_1min'.tr()),
              const SizedBox(width: 12),
              _buildDurationOption(120, 'games.two_minutes.dur_2min'.tr()),
              const SizedBox(width: 12),
              _buildDurationOption(180, 'games.two_minutes.dur_3min'.tr()),
              const SizedBox(width: 12),
              _buildDurationOption(300, 'games.two_minutes.dur_5min'.tr()),
            ],
          ),
          const SizedBox(height: 32),

          // Intensity Selection
          Text(
            'games.two_minutes.intensity'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildIntensityOption('soft', 'games.two_minutes.intensity_soft'.tr(), '🌸', 'games.two_minutes.intensity_soft_desc'.tr()),
          const SizedBox(height: 12),
          _buildIntensityOption('spicy', 'games.two_minutes.intensity_spicy'.tr(), '🌶️', 'games.two_minutes.intensity_spicy_desc'.tr()),
          const SizedBox(height: 12),
          _buildIntensityOption('extra_spicy', 'games.two_minutes.intensity_extra_spicy'.tr(), '🔥', 'games.two_minutes.intensity_extra_spicy_desc'.tr()),
          const SizedBox(height: 32),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'games.two_minutes.start_session'.tr(),
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

  Widget _buildDurationOption(int seconds, String label) {
    final isSelected = _selectedDuration == seconds;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = seconds),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEC4899)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFEC4899)
                  : Colors.white.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityOption(String id, String name, String emoji, String desc) {
    final isSelected = _selectedIntensity == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedIntensity = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEC4899).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEC4899)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFEC4899)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreChallengeView() {
    final challenge = _currentChallenges[_currentChallengeIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress
          Text(
            'games.two_minutes.challenge_of'.tr(args: [(_currentChallengeIndex + 1).toString(), _currentChallenges.length.toString()]),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentChallengeIndex + 1) / _currentChallenges.length,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
          ),

          const Spacer(),

          // Challenge Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFEC4899).withOpacity(0.2),
                  const Color(0xFFF97316).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFEC4899).withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    challenge['icon'] as IconData,
                    size: 40,
                    color: const Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  challenge['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  challenge['description'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_selectedDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _skipChallenge,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('games.two_minutes.skip'.tr()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _startChallenge,
                  icon: const Icon(Icons.play_arrow),
                  label: Text('games.two_minutes.start_timer'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeView() {
    final challenge = _currentChallenges[_currentChallengeIndex];
    final progress = 1 - (_remainingSeconds / _selectedDuration);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Challenge title
          Text(
            challenge['title'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Timer Circle
          ScaleTransition(
            scale: _pulseAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remainingSeconds <= 10
                          ? Colors.red
                          : const Color(0xFFEC4899),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        color: _remainingSeconds <= 10 ? Colors.red : Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      _isPaused ? 'games.two_minutes.paused'.tr() : 'games.two_minutes.remaining'.tr(),
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

          // Challenge description reminder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              challenge['description'] as String,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _skipChallenge,
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
                color: Colors.white54,
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: _togglePause,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _onChallengeComplete,
                icon: const Icon(Icons.check),
                iconSize: 32,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
