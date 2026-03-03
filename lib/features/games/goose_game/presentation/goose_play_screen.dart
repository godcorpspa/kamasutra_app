import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/goose_game.dart';

// ==================== PLAY SCREEN ====================

class GoosePlayScreen extends StatefulWidget {
  final GooseGameConfig config;

  const GoosePlayScreen({super.key, required this.config});

  @override
  State<GoosePlayScreen> createState() => _GoosePlayScreenState();
}

class _GoosePlayScreenState extends State<GoosePlayScreen>
    with TickerProviderStateMixin {
  // ── Board ──
  late final List<GooseSquare> _board;
  final Random _rng = Random();

  // ── Player positions ──
  int _p1Pos = 0;
  int _p2Pos = 0;

  // ── Clothing (0-4) ──
  int _p1Clothing = 4;
  int _p2Clothing = 4;

  // ── Exit mechanic ──
  bool _p1OnBoard = false; // has exited position 0
  bool _p2OnBoard = false;
  int _p1FailedExits = 0; // consecutive failed exit rolls
  int _p2FailedExits = 0;
  bool _waitingMovementRoll = false; // after successful exit roll

  // ── 20-square milestone ──
  int _p1LastMilestone = 0; // last milestone already processed (0,20,40,60,80)
  int _p2LastMilestone = 0;

  // ── Turn ──
  int _currentPlayer = 1; // 1 or 2
  int _consecutiveSixes = 0;

  // ── Dice ──
  int _lastRoll = 0;
  bool _isRolling = false;

  // ── Game end ──
  bool _gameOver = false;

  // ── Animations ──
  late AnimationController _diceAnim;
  late ConfettiController _confetti;

  // ── Dice faces (emoji) ──
  static const _diceFaces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

  @override
  void initState() {
    super.initState();
    _board = _buildBoard();
    _diceAnim = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _diceAnim.dispose();
    _confetti.dispose();
    super.dispose();
  }

  // ==================== BOARD GENERATION ====================

  List<GooseSquare> _buildBoard() {
    const total = 100;
    return List.generate(total + 1, (i) {
      if (i == 0) return const GooseSquare(position: 0, type: GooseSquareType.normal);
      if (i == total) return const GooseSquare(position: total, type: GooseSquareType.finish);
      if (kLadderMap.containsKey(i)) {
        return GooseSquare(position: i, type: GooseSquareType.ladder, destination: kLadderMap[i]);
      }
      if (kHoleMap.containsKey(i)) {
        return GooseSquare(position: i, type: GooseSquareType.hole, destination: kHoleMap[i]);
      }
      if (kPenanceSquares.contains(i)) {
        return GooseSquare(position: i, type: GooseSquareType.penance);
      }
      return GooseSquare(position: i, type: GooseSquareType.normal);
    });
  }

  // ==================== DICE ROLL ====================

  Future<void> _rollDice() async {
    if (_isRolling || _gameOver) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isRolling = true;
    });

    _diceAnim.repeat();
    await Future.delayed(const Duration(milliseconds: 700));
    _diceAnim.stop();

    final roll = _rng.nextInt(6) + 1;
    setState(() {
      _lastRoll = roll;
      _isRolling = false;
    });

    final onBoard = _currentPlayer == 1 ? _p1OnBoard : _p2OnBoard;

    if (!onBoard && !_waitingMovementRoll) {
      await _handleExitRoll(roll);
    } else {
      // Movement roll: either first move after exit, or normal turn
      final isFirstMove = _waitingMovementRoll;
      if (_waitingMovementRoll) _waitingMovementRoll = false;

      await _movePlayer(roll, firstMove: isFirstMove);

      if (roll == 6 && _consecutiveSixes < 2 && !_gameOver) {
        _consecutiveSixes++;
        _showSnack('🎲 Hai fatto 6! Tira ancora! (extra $_consecutiveSixes/2)');
      } else {
        _consecutiveSixes = 0;
        if (!_gameOver) _switchPlayer();
      }
    }
  }

  // ── Exit phase (position 0) ──
  Future<void> _handleExitRoll(int roll) async {
    final name = _playerName(_currentPlayer);

    if (roll >= 4) {
      // Success → roll again to move
      _waitingMovementRoll = true;
      if (_currentPlayer == 1) {
        _p1FailedExits = 0;
      } else {
        _p2FailedExits = 0;
      }
      _showSnack('$name esce dalla partenza! 🚀 Tira di nuovo per muoverti!');
    } else {
      // Failure
      if (_currentPlayer == 1) {
        _p1FailedExits++;
      } else {
        _p2FailedExits++;
      }
      final failures = _currentPlayer == 1 ? _p1FailedExits : _p2FailedExits;
      if (failures >= 2) {
        // 2 consecutive failures → opponent loses clothing
        if (_currentPlayer == 1) _p1FailedExits = 0;
        else _p2FailedExits = 0;
        await _removeClothingFromOpponent(
          reason: '$name non riesce ad uscire per 2 turni!',
        );
        _switchPlayer();
      } else {
        _showSnack('$name ha tirato $roll. Serve 4, 5 o 6! (${2 - failures} chance rimaste)');
        _switchPlayer();
      }
    }
  }


  // ── Move a player ──
  Future<void> _movePlayer(int spaces, {required bool firstMove}) async {
    const total = 100;
    final oldPos = _currentPlayer == 1 ? _p1Pos : _p2Pos;
    int newPos = oldPos + spaces;

    // Bounce back if overshoot
    if (newPos > total) {
      newPos = total - (newPos - total);
      _showSnack('Rimbalzo! Torna alla casella $newPos');
    }

    setState(() {
      if (_currentPlayer == 1) {
        _p1Pos = newPos;
        if (firstMove) _p1OnBoard = true;
      } else {
        _p2Pos = newPos;
        if (firstMove) _p2OnBoard = true;
      }
    });

    await Future.delayed(const Duration(milliseconds: 400));

    // Check 20-square milestone
    await _checkMilestone(newPos);

    // Handle square
    await _handleSquare(newPos);
  }

  // ── Milestone every 20 squares ──
  Future<void> _checkMilestone(int pos) async {
    final milestones = [20, 40, 60, 80];
    final lastMilestone = _currentPlayer == 1 ? _p1LastMilestone : _p2LastMilestone;

    for (final m in milestones) {
      if (pos >= m && lastMilestone < m) {
        // Update last milestone
        setState(() {
          if (_currentPlayer == 1) _p1LastMilestone = m;
          else _p2LastMilestone = m;
        });
        // Opponent loses clothing
        await _removeClothingFromOpponent(
          reason: '${_playerName(_currentPlayer)} ha superato la casella $m!',
        );
        return; // only one milestone per move
      }
    }
  }

  // ── Handle square effect ──
  Future<void> _handleSquare(int pos) async {
    if (pos >= _board.length) return;
    final square = _board[pos];

    switch (square.type) {
      case GooseSquareType.finish:
        await _handleVictory();
        break;

      case GooseSquareType.ladder:
        final dest = square.destination!;
        final reward = _randomContent(kRewards);
        await _showLadderDialog(pos, dest, reward);
        setState(() {
          if (_currentPlayer == 1) _p1Pos = dest;
          else _p2Pos = dest;
        });
        break;

      case GooseSquareType.hole:
        final dest = square.destination!;
        final penance = _randomContent(kPenances);
        await _showHoleDialog(pos, dest, penance);
        setState(() {
          if (_currentPlayer == 1) _p1Pos = dest;
          else _p2Pos = dest;
        });
        break;

      case GooseSquareType.penance:
        final penance = _randomContent(kPenances);
        await _showPenanceDialog(penance);
        break;

      default:
        break;
    }
  }

  // ── Remove clothing from opponent ──
  Future<void> _removeClothingFromOpponent({required String reason}) async {
    final opponent = _currentPlayer == 1 ? 2 : 1;
    final clothingCount = opponent == 1 ? _p1Clothing : _p2Clothing;

    if (clothingCount > 0) {
      setState(() {
        if (opponent == 1) _p1Clothing--;
        else _p2Clothing--;
      });
      await _showClothingRemovedDialog(opponent, reason: reason);
    } else {
      // No clothing left → penance instead
      final penance = _randomContent(kPenances);
      await _showNakedPenanceDialog(opponent, penance);
    }
  }

  // ── Switch player ──
  void _switchPlayer() {
    setState(() {
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
    });
  }

  // ── Victory ──
  Future<void> _handleVictory() async {
    HapticFeedback.heavyImpact();
    _confetti.play();
    setState(() => _gameOver = true);

    final reward = _randomContent(kRewards);
    await _showVictoryDialog(reward);
  }

  // ── Helpers ──
  String _playerName(int p) =>
      p == 1 ? widget.config.player1Name : widget.config.player2Name;

  Color _playerColor(int p) => p == 1 ? AppColors.burgundy : AppColors.gold;

  GooseContent _randomContent(List<GooseContent> list) =>
      list[_rng.nextInt(list.length)];

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== DIALOGS ====================

  Future<void> _showLadderDialog(int from, int to, GooseContent reward) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContentDialog(
        emoji: '🪜',
        title: 'SCALA!',
        subtitle: 'Dalla casella $from → $to',
        description: 'Ricevi una ricompensa dal partner:',
        content: reward,
        color: Colors.green.shade700,
      ),
    );
  }

  Future<void> _showHoleDialog(int from, int to, GooseContent penance) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContentDialog(
        emoji: '🕳️',
        title: 'BUCO!',
        subtitle: 'Dalla casella $from → $to',
        description: 'Fai una penitenza al partner:',
        content: penance,
        color: Colors.red.shade700,
      ),
    );
  }

  Future<void> _showPenanceDialog(GooseContent penance) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContentDialog(
        emoji: '🔥',
        title: 'PENITENZA!',
        subtitle: 'Casella piccante!',
        description: 'Esegui questa penitenza:',
        content: penance,
        color: AppColors.burgundy,
      ),
    );
  }

  Future<void> _showClothingRemovedDialog(int player, {required String reason}) async {
    final name = _playerName(player);
    final remaining = player == 1 ? _p1Clothing : _p2Clothing;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👗', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              'TOGLI UN CAPO!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _playerColor(player),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(reason, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Text(
              '$name toglie un capo\nRimasti: ${'👕' * remaining}${remaining == 0 ? 'nessuno!' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _playerColor(player),
                foregroundColor: Colors.white,
              ),
              child: const Text('Fatto! 😈'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNakedPenanceDialog(int player, GooseContent penance) async {
    final name = _playerName(player);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContentDialog(
        emoji: '🔥',
        title: 'NESSUN CAPO!',
        subtitle: '$name non ha più capi da togliere!',
        description: 'Invece: esegui questa penitenza 😈',
        content: penance,
        color: Colors.deepOrange,
      ),
    );
  }

  Future<void> _showVictoryDialog(GooseContent reward) async {
    final name = _playerName(_currentPlayer);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContentDialog(
        emoji: '🏆',
        title: '$name VINCE!',
        subtitle: 'Benvenuto alla casella 100!',
        description: 'Ricompensa finale dal partner:',
        content: reward,
        color: AppColors.gold,
        onDismiss: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎲 Gioco dell\'Oca'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showRules,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Player status bar
              _buildStatusBar(),

              // Board
              Expanded(child: _buildBoard()),

              // Control panel
              _buildControlPanel(),
            ],
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              maxBlastForce: 12,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.15,
              colors: const [AppColors.burgundy, AppColors.gold, Colors.pink, Colors.orange],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status bar (both players) ──
  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(child: _buildPlayerStatus(1)),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          Expanded(child: _buildPlayerStatus(2)),
        ],
      ),
    );
  }

  Widget _buildPlayerStatus(int player) {
    final isActive = _currentPlayer == player && !_gameOver;
    final name = _playerName(player);
    final pos = player == 1 ? _p1Pos : _p2Pos;
    final clothing = player == 1 ? _p1Clothing : _p2Clothing;
    final onBoard = player == 1 ? _p1OnBoard : _p2OnBoard;
    final color = _playerColor(player);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: isActive ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                    color: isActive ? color : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Text('← turno', style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                onBoard ? 'Casella $pos' : 'Partenza 🚀',
                style: const TextStyle(fontSize: 11),
              ),
              const Spacer(),
              // Clothing icons
              Text(
                clothing > 0 ? '👕' * clothing : '🔥',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Board grid ──
  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 1.5,
          crossAxisSpacing: 1.5,
        ),
        itemCount: _board.length,
        itemBuilder: (context, index) {
          final sq = _board[index];
          final hasP1 = _p1Pos == index;
          final hasP2 = _p2Pos == index;
          return _buildSquare(sq, hasP1, hasP2);
        },
      ),
    );
  }

  Widget _buildSquare(GooseSquare sq, bool hasP1, bool hasP2) {
    return Container(
      decoration: BoxDecoration(
        color: _squareBgColor(sq.type),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
      ),
      child: Stack(
        children: [
          // Number
          Positioned(
            top: 1, left: 2,
            child: Text(
              '${sq.position}',
              style: const TextStyle(fontSize: 5.5, color: Colors.white70),
            ),
          ),
          // Icon
          if (sq.type != GooseSquareType.normal)
            Center(
              child: Text(
                sq.type.emoji,
                style: const TextStyle(fontSize: 9),
              ),
            ),
          // Destination arrow (ladder/hole)
          if (sq.destination != null)
            Positioned(
              bottom: 1, right: 1,
              child: Text(
                sq.type == GooseSquareType.ladder ? '↑${sq.destination}' : '↓${sq.destination}',
                style: TextStyle(
                  fontSize: 4.5,
                  color: sq.type == GooseSquareType.ladder ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ),
          // Players
          if (hasP1 || hasP2)
            Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasP1) _playerDot(AppColors.burgundy),
                  if (hasP1 && hasP2) const SizedBox(width: 1),
                  if (hasP2) _playerDot(AppColors.gold),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _playerDot(Color color) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
      );

  Color _squareBgColor(GooseSquareType t) {
    switch (t) {
      case GooseSquareType.normal:  return Colors.blueGrey.shade800.withOpacity(0.6);
      case GooseSquareType.ladder:  return Colors.green.shade700.withOpacity(0.7);
      case GooseSquareType.hole:    return Colors.red.shade700.withOpacity(0.7);
      case GooseSquareType.penance: return Colors.deepOrange.shade700.withOpacity(0.7);
      case GooseSquareType.finish:  return Colors.amber.shade600.withOpacity(0.9);
    }
  }

  // ── Control panel ──
  Widget _buildControlPanel() {
    final name = _playerName(_currentPlayer);
    final color = _playerColor(_currentPlayer);
    final onBoard = _currentPlayer == 1 ? _p1OnBoard : _p2OnBoard;

    String phase;
    if (!onBoard && !_waitingMovementRoll) {
      phase = 'Tira 4/5/6 per uscire dalla partenza';
    } else if (_waitingMovementRoll) {
      phase = 'Sei uscito! Tira per muoverti 🚀';
    } else if (_consecutiveSixes > 0) {
      phase = 'Hai fatto 6! Tira ancora ($_consecutiveSixes/2)';
    } else {
      phase = 'Il tuo turno, tira il dado!';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current player + phase
            Text(
              '${_currentPlayer == 1 ? "🔴" : "🟡"} $name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(phase, style: const TextStyle(fontSize: 12)),

            const SizedBox(height: AppSpacing.sm),

            // Dice + Roll button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dice display
                AnimatedBuilder(
                  animation: _diceAnim,
                  builder: (_, __) => Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _isRolling
                            ? _diceFaces[(_diceAnim.value * 6).toInt() % 6]
                            : (_lastRoll > 0 ? _diceFaces[_lastRoll - 1] : '🎲'),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.lg),

                // Roll button
                ElevatedButton(
                  onPressed: (_isRolling || _gameOver) ? null : _rollDice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    _isRolling ? '...' : 'TIRA IL DADO 🎲',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Rules modal ──
  void _showRules() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Regole', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              ...[
                ('🚀', 'Tira 4/5/6 per uscire dalla casella 0. 2 fallimenti consecutivi → il partner toglie un capo'),
                ('🎲', 'Se esci, tira di nuovo per muoverti'),
                ('👗', 'Ogni volta che superi un multiplo di 20: l\'avversario toglie un capo'),
                ('🪜', 'Scala: avanza e ricevi una ricompensa dal partner'),
                ('🕳️', 'Buco: torni indietro e fai una penitenza'),
                ('🔥', 'Casella Penitenza: penitenza hot obbligatoria'),
                ('6️⃣', 'Fai 6: tira ancora! Max 2 volte consecutive'),
                ('👕', 'Nessun capo rimasto: penitenza invece di spogliarsi'),
                ('🏆', 'Arriva alla casella 100 esattamente per vincere'),
                ('↩️', 'Se superi il 100: rimbalzi indietro'),
              ].map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(r.$2,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Legend
              Text('Legenda colori',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              ...[
                (Colors.green.shade700, '🪜 Scala'),
                (Colors.red.shade700, '🕳️ Buco'),
                (Colors.deepOrange.shade700, '🔥 Penitenza'),
                (Colors.amber.shade600, '🏆 Arrivo'),
                (Colors.blueGrey.shade800, 'Casella normale'),
              ].map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: e.$1,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(e.$2, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CONTENT DIALOG (reward / penance) ====================

class _ContentDialog extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final GooseContent content;
  final Color color;
  final VoidCallback? onDismiss;

  const _ContentDialog({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.content,
    required this.color,
    this.onDismiss,
  });

  @override
  State<_ContentDialog> createState() => _ContentDialogState();
}

class _ContentDialogState extends State<_ContentDialog> {
  Timer? _timer;
  int _remaining = 0;
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();
    if (widget.content.timerSeconds != null) {
      _remaining = widget.content.timerSeconds!;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() {
          _remaining = 0;
          _timerDone = true;
        });
        HapticFeedback.heavyImpact();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return m > 0 ? '${m}m ${s.toString().padLeft(2, '0')}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final hasTimer = widget.content.timerSeconds != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: AppSpacing.sm),

            Text(
              widget.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),
            Text(widget.subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center),

            const SizedBox(height: AppSpacing.md),
            Container(height: 1, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: AppSpacing.md),

            Text(widget.description,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center),

            const SizedBox(height: AppSpacing.sm),

            Text(
              widget.content.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Timer
            if (hasTimer) ...[
              const SizedBox(height: AppSpacing.lg),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                decoration: BoxDecoration(
                  color: _timerDone
                      ? Colors.green.withOpacity(0.15)
                      : widget.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _timerDone ? Colors.green : widget.color,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _timerDone ? Icons.check_circle : Icons.timer,
                      color: _timerDone ? Colors.green : widget.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timerDone ? 'Tempo scaduto! ✅' : _formatTime(_remaining),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _timerDone ? Colors.green : widget.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onDismiss != null) {
                    widget.onDismiss!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  hasTimer && !_timerDone ? 'Fatto in anticipo! ✓' : 'Fatto! 😈',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
