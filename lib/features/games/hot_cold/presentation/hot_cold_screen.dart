import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../app/theme.dart';

class HotColdScreen extends StatefulWidget {
  const HotColdScreen({super.key});

  @override
  State<HotColdScreen> createState() => _HotColdScreenState();
}

class _HotColdScreenState extends State<HotColdScreen> {
  bool _gameStarted = false;
  bool _isSeeker = true; // Player 1 starts as seeker
  String _intensity = 'spicy';
  String? _currentZone;
  int _roundNumber = 1;
  int _totalRounds = 5;
  int _player1Score = 0;
  int _player2Score = 0;
  Timer? _timer;
  int _timeRemaining = 60;
  double _temperature = 0.5; // 0 = freezing, 1 = burning

  final List<Map<String, dynamic>> _zones = [
    {'name': 'Collo', 'emoji': '👔', 'hint': 'Zona alta, molto sensibile'},
    {'name': 'Spalle', 'emoji': '💪', 'hint': 'Supportano tutto'},
    {'name': 'Schiena', 'emoji': '🔙', 'hint': 'Ampia e da esplorare'},
    {'name': 'Fianchi', 'emoji': '〰️', 'hint': 'Curve morbide'},
    {'name': 'Interno coscia', 'emoji': '🦵', 'hint': 'Zona delicata'},
    {'name': 'Piedi', 'emoji': '🦶', 'hint': 'Base solida'},
    {'name': 'Mani', 'emoji': '🤲', 'hint': 'Strumenti d\'amore'},
    {'name': 'Orecchio', 'emoji': '👂', 'hint': 'Ascolta i sussurri'},
    {'name': 'Polso', 'emoji': '⌚', 'hint': 'Senti il battito'},
    {'name': 'Nuca', 'emoji': '🔝', 'hint': 'Retro della testa'},
  ];

  final List<Map<String, dynamic>> _spicyZones = [
    {'name': 'Interno braccia', 'emoji': '💫', 'hint': 'Zona spesso dimenticata'},
    {'name': 'Dietro ginocchio', 'emoji': '🦿', 'hint': 'Punto nascosto'},
    {'name': 'Basso ventre', 'emoji': '✨', 'hint': 'Sotto l\'ombelico'},
    {'name': 'Scollatura', 'emoji': '💝', 'hint': 'Zona del cuore'},
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    final allZones = _intensity == 'soft'
        ? _zones
        : [..._zones, ..._spicyZones];
    allZones.shuffle();

    setState(() {
      _gameStarted = true;
      _currentZone = allZones.first['name'];
      _temperature = 0.5;
      _timeRemaining = 60;
    });

    _startTimer();
    _showZoneToGuider();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        _timer?.cancel();
        _handleTimeout();
      }
    });
  }

  void _showZoneToGuider() {
    final zone = _getZoneData(_currentZone!);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'game_ui.player_guides'.tr(args: [_isSeeker ? 'game_ui.player_2'.tr() : 'game_ui.player_1'.tr()]),
          style: const TextStyle(color: AppColors.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.burgundy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    zone['emoji'],
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    zone['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'game_ui.guide_instructions'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '${'games.hot_cold.hint_label'.tr()}: ${zone['hint']}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burgundy,
              foregroundColor: Colors.white,
            ),
            child: Text('game_ui.understood'.tr()),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getZoneData(String zoneName) {
    final allZones = [..._zones, ..._spicyZones];
    return allZones.firstWhere(
      (z) => z['name'] == zoneName,
      orElse: () => {'name': zoneName, 'emoji': '❓', 'hint': ''},
    );
  }

  void _updateTemperature(double delta) {
    setState(() {
      _temperature = (_temperature + delta).clamp(0.0, 1.0);
    });
  }

  void _handleFound() {
    _timer?.cancel();

    // Score based on time remaining
    final score = (_timeRemaining / 10).ceil() + 5;

    setState(() {
      if (_isSeeker) {
        _player1Score += score;
      } else {
        _player2Score += score;
      }
    });

    _showRoundResult(true, score);
  }

  void _handleTimeout() {
    _showRoundResult(false, 0);
  }

  void _showRoundResult(bool found, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          found ? 'games.hot_cold.found_title'.tr() : 'game_ui.time_expired'.tr(),
          style: TextStyle(
            color: found ? AppColors.gold : AppColors.spicy,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (found) ...[
              Text(
                'game_ui.points'.tr(args: [score.toString()]),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'game_ui.zone_was'.tr(namedArgs: {'zone': _currentZone!}),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ] else ...[
              Text(
                'game_ui.zone_was'.tr(namedArgs: {'zone': _currentZone!}),
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('game_ui.player_1'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                      Text(
                        '$_player1Score',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ],
                  ),
                  Text('game_ui.vs'.tr(), style: const TextStyle(color: AppColors.gold)),
                  Column(
                    children: [
                      Text('game_ui.player_2'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                      Text(
                        '$_player2Score',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.spicy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_roundNumber < _totalRounds)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _nextRound();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                foregroundColor: Colors.white,
              ),
              child: Text('game_ui.next_round'.tr()),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showFinalResults();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
              ),
              child: Text('game_ui.see_results'.tr()),
            ),
        ],
      ),
    );
  }

  void _nextRound() {
    final allZones = _intensity == 'soft'
        ? _zones
        : [..._zones, ..._spicyZones];
    allZones.shuffle();

    setState(() {
      _roundNumber++;
      _isSeeker = !_isSeeker;
      _currentZone = allZones.first['name'];
      _temperature = 0.5;
      _timeRemaining = 60;
    });

    _startTimer();
    _showZoneToGuider();
  }

  void _showFinalResults() {
    final winner = _player1Score > _player2Score
        ? 'game_ui.player_1'.tr()
        : _player1Score < _player2Score
            ? 'game_ui.player_2'.tr()
            : 'game_ui.draw'.tr();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'game_ui.game_over'.tr(),
          style: const TextStyle(color: AppColors.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              winner == 'game_ui.draw'.tr() ? '${'game_ui.draw'.tr()}!' : 'game_ui.wins'.tr(namedArgs: {'player': winner}),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('game_ui.player_1'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                    Text(
                      '$_player1Score',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.burgundy,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('game_ui.player_2'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
                    Text(
                      '$_player2Score',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.spicy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              winner != 'game_ui.draw'.tr()
                  ? 'game_ui.winner_prize'.tr()
                  : 'game_ui.celebrate_together'.tr(),
              style: const TextStyle(
                color: AppColors.gold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _gameStarted = false;
                _roundNumber = 1;
                _player1Score = 0;
                _player2Score = 0;
              });
            },
            child: Text('game_ui.new_game'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burgundy,
              foregroundColor: Colors.white,
            ),
            child: Text('game_ui.end'.tr()),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor() {
    if (_temperature < 0.2) return Colors.blue.shade900;
    if (_temperature < 0.4) return Colors.blue.shade400;
    if (_temperature < 0.6) return Colors.yellow.shade600;
    if (_temperature < 0.8) return Colors.orange;
    return Colors.red.shade700;
  }

  String _getTemperatureText() {
    if (_temperature < 0.2) return 'games.hot_cold.freezing'.tr();
    if (_temperature < 0.4) return 'games.hot_cold.cold'.tr();
    if (_temperature < 0.6) return 'games.hot_cold.warm'.tr();
    if (_temperature < 0.8) return 'games.hot_cold.hot'.tr();
    return 'games.hot_cold.boiling'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('games.hot_cold.title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRules,
          ),
        ],
      ),
      body: _gameStarted ? _buildGameScreen() : _buildSetupScreen(),
    );
  }

  Widget _buildSetupScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Text(
                    '🌡️',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'games.hot_cold.title'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'game_ui.find_secret_zone'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Intensity
            Text(
              'game_ui.intensity'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildIntensityOption('soft', 'game_ui.soft_label'.tr(), 'game_ui.soft_zones'.tr()),
                const SizedBox(width: 12),
                _buildIntensityOption('spicy', 'game_ui.spicy_label'.tr(), 'game_ui.spicy_zones'.tr()),
              ],
            ),

            const SizedBox(height: 24),

            // Rounds
            Text(
              'game_ui.number_of_rounds'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [3, 5, 7].map((rounds) {
                final isSelected = _totalRounds == rounds;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _totalRounds = rounds),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.burgundy : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$rounds',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.burgundy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'game_ui.start_playing'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityOption(String value, String label, String description) {
    final isSelected = _intensity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _intensity = value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.burgundy.withOpacity(0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.burgundy : AppColors.textSecondary.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(
                color: isSelected ? AppColors.burgundy : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Round and timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'game_ui.round_of'.tr(namedArgs: {'current': '$_roundNumber', 'total': '$_totalRounds'}),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _timeRemaining <= 10 ? AppColors.spicy.withOpacity(0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 20,
                        color: _timeRemaining <= 10 ? AppColors.spicy : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_timeRemaining s',
                        style: TextStyle(
                          color: _timeRemaining <= 10 ? AppColors.spicy : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current seeker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    'game_ui.player_searches'.tr(namedArgs: {'player': _isSeeker ? '1' : '2'}),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Temperature indicator
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _getTemperatureColor().withOpacity(0.8),
                    _getTemperatureColor().withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTemperatureText(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Temperature controls (for guider)
            Text(
              'game_ui.guider_buttons'.tr(),
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTempButton('🥶', -0.3, Colors.blue),
                _buildTempButton('❄️', -0.15, Colors.lightBlue),
                _buildTempButton('🔥', 0.15, Colors.orange),
                _buildTempButton('🌋', 0.3, Colors.red),
              ],
            ),

            const SizedBox(height: 24),

            // Found button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleFound,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'game_ui.found'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempButton(String emoji, double delta, Color color) {
    return GestureDetector(
      onTap: () => _updateTemperature(delta),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
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
              'games.hot_cold.how_to_play'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRuleItem('1', 'games.hot_cold.rule_1'.tr()),
            _buildRuleItem('2', 'games.hot_cold.rule_2'.tr()),
            _buildRuleItem('3', 'games.hot_cold.rule_3'.tr()),
            _buildRuleItem('4', 'games.hot_cold.rule_4'.tr()),
            const SizedBox(height: 16),
            Text(
              'game_ui.explore_with_fun'.tr(),
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
