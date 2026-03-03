import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/goose_game.dart';

// ── Dark theme palette ──
const _kBg1      = Color(0xFF0D0D1A);
const _kBg2      = Color(0xFF1A0A2E);
const _kSurface  = Color(0xFF1E1E32);
const _kBorder   = Color(0xFF2E2E4A);
const _kGold     = Color(0xFFFFD700);
const _kRed      = Color(0xFFFF3B5C);
const _kGreen    = Color(0xFF00E676);
const _kOrange   = Color(0xFFFF6D00);
const _kBlue     = Color(0xFF448AFF);
const _kP1       = Color(0xFFEF5350);   // player 1 – red
const _kP2       = Color(0xFFFFD600);   // player 2 – gold

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

  // ── Positions ──
  int _p1Pos = 0, _p2Pos = 0;

  // ── Clothing (0-4) ──
  int _p1Clothing = 4, _p2Clothing = 4;

  // ── Exit mechanic ──
  bool _p1OnBoard = false, _p2OnBoard = false;
  int  _p1FailedExits = 0, _p2FailedExits = 0;
  bool _waitingMovementRoll = false;

  // ── Milestone tracking ──
  int _p1LastMilestone = 0, _p2LastMilestone = 0;

  // ── Turn ──
  int _currentPlayer = 1;
  int _consecutiveSixes = 0;

  // ── Dice ──
  int  _lastRoll = 0;
  bool _isRolling = false;

  // ── Status message overlay ──
  String? _statusMsg;
  Color   _statusColor = _kBlue;
  String  _statusEmoji = '🎲';
  Timer?  _statusTimer;

  // ── Game end ──
  bool _gameOver = false;

  // ── Animations ──
  late AnimationController _diceAnim;
  late AnimationController _shakeAnim;
  late ConfettiController  _confetti;

  static const _diceDots = ['⚀','⚁','⚂','⚃','⚄','⚅'];

  // ─────────────────────────── LIFECYCLE ────────────────────────────

  @override
  void initState() {
    super.initState();
    _board = _generateBoard();
    _diceAnim = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _shakeAnim = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _diceAnim.dispose();
    _shakeAnim.dispose();
    _confetti.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────── BOARD ────────────────────────────────

  List<GooseSquare> _generateBoard() {
    const total = 100;
    return List.generate(total + 1, (i) {
      if (i == 0)     return const GooseSquare(position: 0,     type: GooseSquareType.normal);
      if (i == total) return const GooseSquare(position: total, type: GooseSquareType.finish);
      if (kLadderMap.containsKey(i))
        return GooseSquare(position: i, type: GooseSquareType.ladder, destination: kLadderMap[i]);
      if (kHoleMap.containsKey(i))
        return GooseSquare(position: i, type: GooseSquareType.hole,   destination: kHoleMap[i]);
      if (kPenanceSquares.contains(i))
        return GooseSquare(position: i, type: GooseSquareType.penance);
      return GooseSquare(position: i, type: GooseSquareType.normal);
    });
  }

  // ─────────────────────────── STATUS OVERLAY ───────────────────────

  void _showStatus(String msg, {Color color = _kBlue, String emoji = '🎲'}) {
    _statusTimer?.cancel();
    setState(() { _statusMsg = msg; _statusColor = color; _statusEmoji = emoji; });
    _statusTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _statusMsg = null);
    });
  }

  // ─────────────────────────── DICE LOGIC ───────────────────────────

  Future<void> _rollDice() async {
    if (_isRolling || _gameOver) return;
    HapticFeedback.mediumImpact();
    setState(() => _isRolling = true);

    _diceAnim.repeat();
    _shakeAnim.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 650));
    _diceAnim.stop();

    final roll = _rng.nextInt(6) + 1;
    setState(() { _lastRoll = roll; _isRolling = false; });

    final onBoard = _currentPlayer == 1 ? _p1OnBoard : _p2OnBoard;

    if (!onBoard && !_waitingMovementRoll) {
      await _handleExitRoll(roll);
    } else {
      final isFirst = _waitingMovementRoll;
      if (_waitingMovementRoll) _waitingMovementRoll = false;
      await _movePlayer(roll, firstMove: isFirst);
      if (roll == 6 && _consecutiveSixes < 2 && !_gameOver) {
        _consecutiveSixes++;
        _showStatus('🎲 Hai fatto 6! Tira ancora! (${_consecutiveSixes}/2)',
            color: _kGold, emoji: '🎲');
      } else {
        _consecutiveSixes = 0;
        if (!_gameOver) _switchPlayer();
      }
    }
  }

  Future<void> _handleExitRoll(int roll) async {
    final name = _playerName(_currentPlayer);
    if (roll >= 4) {
      _waitingMovementRoll = true;
      if (_currentPlayer == 1) _p1FailedExits = 0; else _p2FailedExits = 0;
      _showStatus('$name esce! 🚀 Tira ancora per muoverti!',
          color: _kGreen, emoji: '🚀');
    } else {
      if (_currentPlayer == 1) _p1FailedExits++; else _p2FailedExits++;
      final failures = _currentPlayer == 1 ? _p1FailedExits : _p2FailedExits;
      if (failures >= 2) {
        if (_currentPlayer == 1) _p1FailedExits = 0; else _p2FailedExits = 0;
        await _removeClothingFrom(_currentPlayer,
            reason: '$name non riesce ad uscire per 2 turni!');
        _switchPlayer();
      } else {
        _showStatus('Serve 4, 5 o 6! (${2 - failures} tentativo rimasto)',
            color: _kRed, emoji: '⚠️');
        _switchPlayer();
      }
    }
  }

  Future<void> _movePlayer(int spaces, {required bool firstMove}) async {
    const total = 100;
    final oldPos = _currentPlayer == 1 ? _p1Pos : _p2Pos;
    int newPos = oldPos + spaces;

    if (newPos > total) {
      newPos = total - (newPos - total);
      _showStatus('Rimbalzo! Torna alla casella $newPos 🔄',
          color: _kOrange, emoji: '🔄');
    }

    setState(() {
      if (_currentPlayer == 1) { _p1Pos = newPos; if (firstMove) _p1OnBoard = true; }
      else                     { _p2Pos = newPos; if (firstMove) _p2OnBoard = true; }
    });

    await Future.delayed(const Duration(milliseconds: 350));
    await _checkMilestone(newPos);
    await _handleSquare(newPos);
  }

  Future<void> _checkMilestone(int pos) async {
    final last = _currentPlayer == 1 ? _p1LastMilestone : _p2LastMilestone;
    for (final m in [20, 40, 60, 80]) {
      if (pos >= m && last < m) {
        setState(() {
          if (_currentPlayer == 1) _p1LastMilestone = m;
          else _p2LastMilestone = m;
        });
        await _removeClothingFromOpponent(
            reason: '${_playerName(_currentPlayer)} ha superato la casella $m!');
        return;
      }
    }
  }

  Future<void> _handleSquare(int pos) async {
    if (pos >= _board.length) return;
    final sq = _board[pos];
    switch (sq.type) {
      case GooseSquareType.finish:
        await _handleVictory();
        break;
      case GooseSquareType.ladder:
        final dest = sq.destination!;
        await _showContentDialog(_ContentDialogArgs(
          emoji: '🪜', title: 'SCALA!',
          subtitle: 'Casella $pos → $dest (+${dest - pos})',
          description: 'Ricevi una ricompensa dal partner:',
          content: _rand(kRewards), color: _kGreen,
        ));
        setState(() { if (_currentPlayer == 1) _p1Pos = dest; else _p2Pos = dest; });
        break;
      case GooseSquareType.hole:
        final dest = sq.destination!;
        await _showContentDialog(_ContentDialogArgs(
          emoji: '🕳️', title: 'BUCO!',
          subtitle: 'Casella $pos → $dest (${dest - pos})',
          description: 'Fai una penitenza al partner:',
          content: _rand(kPenances), color: _kRed,
        ));
        setState(() { if (_currentPlayer == 1) _p1Pos = dest; else _p2Pos = dest; });
        break;
      case GooseSquareType.penance:
        await _showContentDialog(_ContentDialogArgs(
          emoji: '🔥', title: 'PENITENZA!',
          subtitle: 'Casella piccante!',
          description: 'Esegui questa penitenza:',
          content: _rand(kPenances), color: _kOrange,
        ));
        break;
      default:
        break;
    }
  }

  Future<void> _removeClothingFrom(int player, {required String reason}) async {
    final count = player == 1 ? _p1Clothing : _p2Clothing;
    if (count > 0) {
      setState(() { if (player == 1) _p1Clothing--; else _p2Clothing--; });
      await _showClothingModal(player, reason: reason);
    } else {
      await _showContentDialog(_ContentDialogArgs(
        emoji: '🔥', title: 'NUDO/A!',
        subtitle: '${_playerName(player)} non ha più capi!',
        description: 'Penitenza invece di spogliarsi 😈',
        content: _rand(kPenances), color: _kRed,
      ));
    }
  }

  Future<void> _removeClothingFromOpponent({required String reason}) async {
    final opp = _currentPlayer == 1 ? 2 : 1;
    await _removeClothingFrom(opp, reason: reason);
  }

  void _switchPlayer() {
    setState(() => _currentPlayer = _currentPlayer == 1 ? 2 : 1);
  }

  Future<void> _handleVictory() async {
    HapticFeedback.heavyImpact();
    _confetti.play();
    setState(() => _gameOver = true);
    await _showContentDialog(_ContentDialogArgs(
      emoji: '🏆', title: '${_playerName(_currentPlayer)} VINCE!',
      subtitle: 'Hai raggiunto la casella 100! 🎉',
      description: 'Ricompensa finale dal partner:',
      content: _rand(kRewards), color: _kGold,
      onDismiss: () { Navigator.of(context).pop(); context.pop(); },
    ));
  }

  // ── Helpers ──
  String       _playerName(int p)  => p == 1 ? widget.config.player1Name : widget.config.player2Name;
  Color        _playerColor(int p) => p == 1 ? _kP1 : _kP2;
  GooseContent _rand(List<GooseContent> l) => l[_rng.nextInt(l.length)];

  // ─────────────────────────── MODALS ───────────────────────────────

  Future<void> _showContentDialog(_ContentDialogArgs args) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => _ContentDialog(args: args),
    );
  }

  Future<void> _showClothingModal(int player, {required String reason}) async {
    final name      = _playerName(player);
    final remaining = player == 1 ? _p1Clothing : _p2Clothing;
    final color     = _playerColor(player);
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => _ClothingDialog(
          playerName: name, remaining: remaining,
          reason: reason, color: color),
    );
  }

  // ─────────────────────────── BUILD ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg1,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_kBg1, _kBg2, Color(0xFF0A1628)],
              ),
            ),
          ),

          Column(
            children: [
              _buildStatusBar(),
              Expanded(child: _buildBoard()),
              _buildControlPanel(),
            ],
          ),

          // Status toast (top of board area, never covers dice button)
          if (_statusMsg != null) _buildStatusToast(),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2,
              maxBlastForce: 15, minBlastForce: 6,
              emissionFrequency: 0.06, numberOfParticles: 35,
              gravity: 0.12,
              colors: const [_kP1, _kP2, _kGold, Colors.pink, _kGreen],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [_kGold, _kP1],
        ).createShader(b),
        child: const Text(
          '🎲 Gioco dell\'Oca',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white70),
          onPressed: _showRules,
        ),
      ],
    );
  }

  // ── Status toast overlay ──
  Widget _buildStatusToast() {
    return Positioned(
      top: 56, left: 12, right: 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_statusColor.withOpacity(0.92), _statusColor.withOpacity(0.75)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _statusColor.withOpacity(0.5),
                blurRadius: 16, spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Text(_statusEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusMsg!,
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Player status bar ──
  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _buildPlayerCard(1)),
          Container(width: 1, height: 52, color: _kBorder),
          Expanded(child: _buildPlayerCard(2)),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(int p) {
    final isActive = _currentPlayer == p && !_gameOver;
    final name     = _playerName(p);
    final pos      = p == 1 ? _p1Pos : _p2Pos;
    final clothes  = p == 1 ? _p1Clothing : _p2Clothing;
    final onBoard  = p == 1 ? _p1OnBoard : _p2OnBoard;
    final color    = _playerColor(p);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(colors: [color.withOpacity(0.18), Colors.transparent],
                begin: Alignment.centerLeft, end: Alignment.centerRight)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: color.withOpacity(0.6), width: 1.5) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Glowing dot
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              boxShadow: isActive ? [BoxShadow(color: color, blurRadius: 6, spreadRadius: 1)] : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(name,
            style: TextStyle(
              color: isActive ? color : Colors.white54,
              fontSize: 12, fontWeight: FontWeight.bold,
            ), overflow: TextOverflow.ellipsis)),
          if (isActive)
            Text('✦ turno', style: TextStyle(fontSize: 9, color: color)),
        ]),
        const SizedBox(height: 3),
        Row(children: [
          Text(
            onBoard ? '📍 $pos/100' : '🚀 partenza',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const Spacer(),
          // Clothing dots
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(
              i < clothes ? Icons.checkroom : Icons.close,
              size: 11,
              color: i < clothes ? color : Colors.white20,
            ),
          )),
        ]),
      ]),
    );
  }

  // ── Board grid ──
  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 2, crossAxisSpacing: 2,
        ),
        itemCount: _board.length,
        itemBuilder: (_, i) {
          final sq = _board[i];
          return _buildSquare(sq, _p1Pos == i, _p2Pos == i);
        },
      ),
    );
  }

  Widget _buildSquare(GooseSquare sq, bool hasP1, bool hasP2) {
    final base = _squareBase(sq.type);
    final glow = _squareGlow(sq.type);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [base.withOpacity(0.9), base.withOpacity(0.55)],
        ),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        boxShadow: glow != null
            ? [BoxShadow(color: glow.withOpacity(0.4), blurRadius: 3)]
            : null,
      ),
      child: Stack(children: [
        // Number
        Positioned(
          top: 1, left: 2,
          child: Text('${sq.position}',
              style: const TextStyle(fontSize: 5, color: Colors.white54)),
        ),
        // Type icon
        if (sq.type != GooseSquareType.normal)
          Center(child: Text(sq.type.emoji, style: const TextStyle(fontSize: 9))),
        // Jump indicator
        if (sq.destination != null)
          Positioned(
            bottom: 1, right: 1,
            child: Text(
              sq.type == GooseSquareType.ladder
                  ? '↑${sq.destination}' : '↓${sq.destination}',
              style: TextStyle(
                fontSize: 4.5,
                color: sq.type == GooseSquareType.ladder ? _kGreen : _kRed,
              ),
            ),
          ),
        // Player tokens
        if (hasP1 || hasP2)
          Positioned(
            bottom: 1, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasP1) _token(_kP1),
                if (hasP1 && hasP2) const SizedBox(width: 1),
                if (hasP2) _token(_kP2),
              ],
            ),
          ),
      ]),
    );
  }

  Widget _token(Color c) => Container(
        width: 9, height: 9,
        decoration: BoxDecoration(
          color: c, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [BoxShadow(color: c, blurRadius: 4, spreadRadius: 0.5)],
        ),
      );

  Color  _squareBase(GooseSquareType t) {
    switch (t) {
      case GooseSquareType.normal:  return const Color(0xFF1C2340);
      case GooseSquareType.ladder:  return const Color(0xFF0D3320);
      case GooseSquareType.hole:    return const Color(0xFF3D0A14);
      case GooseSquareType.penance: return const Color(0xFF3D1500);
      case GooseSquareType.finish:  return const Color(0xFF3D3000);
    }
  }

  Color? _squareGlow(GooseSquareType t) {
    switch (t) {
      case GooseSquareType.ladder:  return _kGreen;
      case GooseSquareType.hole:    return _kRed;
      case GooseSquareType.penance: return _kOrange;
      case GooseSquareType.finish:  return _kGold;
      default: return null;
    }
  }

  // ── Control panel ──
  Widget _buildControlPanel() {
    final name    = _playerName(_currentPlayer);
    final color   = _playerColor(_currentPlayer);
    final onBoard = _currentPlayer == 1 ? _p1OnBoard : _p2OnBoard;

    String phase;
    if (!onBoard && !_waitingMovementRoll)
      phase = '⚠️  Tira 4/5/6 per uscire dalla partenza';
    else if (_waitingMovementRoll)
      phase = '🚀 Sei uscito! Tira per muoverti';
    else if (_consecutiveSixes > 0)
      phase = '🎲 Hai fatto 6! Tira ancora (${_consecutiveSixes}/2)';
    else
      phase = '🎯 Il tuo turno, tira il dado!';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4),
            blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ── Dice ──
            _buildDice(color),
            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(text: TextSpan(children: [
                    TextSpan(text: _currentPlayer == 1 ? '🔴 ' : '🟡 '),
                    TextSpan(text: name,
                        style: TextStyle(color: color,
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ])),
                  const SizedBox(height: 2),
                  Text(phase,
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Roll button ──
            _buildRollButton(color),
          ],
        ),
      ),
    );
  }

  Widget _buildDice(Color playerColor) {
    return AnimatedBuilder(
      animation: _diceAnim,
      builder: (_, __) {
        final face = _isRolling
            ? _diceDots[(_diceAnim.value * 6).toInt() % 6]
            : (_lastRoll > 0 ? _diceDots[_lastRoll - 1] : '🎲');

        return Transform.rotate(
          angle: _isRolling ? _diceAnim.value * 2 * pi : 0,
          child: Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  playerColor.withOpacity(0.8),
                  playerColor.withOpacity(0.4),
                  const Color(0xFF0D0D1A),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: playerColor.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: playerColor.withOpacity(0.5),
                    blurRadius: 10, spreadRadius: 0),
                BoxShadow(color: Colors.black.withOpacity(0.6),
                    blurRadius: 6, offset: const Offset(3, 3)),
                BoxShadow(color: Colors.white.withOpacity(0.08),
                    blurRadius: 3, offset: const Offset(-1.5, -1.5)),
              ],
            ),
            child: Center(
              child: Text(face,
                style: TextStyle(
                  fontSize: _isRolling ? 26 : 30,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRollButton(Color color) {
    final enabled = !_isRolling && !_gameOver;
    return GestureDetector(
      onTap: enabled ? _rollDice : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: enabled ? null : Colors.white12,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [BoxShadow(color: color.withOpacity(0.5),
                    blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: Text(
          _isRolling ? '...' : 'TIRA 🎲',
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white30,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ── Rules ──
  void _showRules() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              )),
              const Text('Regole del Gioco',
                  style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...[
                (_kGreen,  '🪜', 'Scala: avanza e ricevi una ricompensa'),
                (_kRed,    '🕳️', 'Buco: torni indietro e fai una penitenza'),
                (_kOrange, '🔥', 'Penitenza: azione hot obbligatoria'),
                (_kGold,   '🏆', 'Arrivo: casella 100 = vittoria!'),
                (_kBlue,   '🚀', 'Esci dalla partenza con 4/5/6. 2 fail → partner spoglia'),
                (_kBlue,   '🎲', 'Se esci, tira ancora per muoverti'),
                (_kP2,     '👗', 'Ogni 20 caselle superate → avversario spoglia'),
                (_kGold,   '6️⃣', 'Fai 6 → tira ancora! Max 2 volte extra'),
                (_kRed,    '💀', 'Nessun capo rimasto → penitenza invece'),
                (_kBlue,   '↩️', 'Oltre 100 → rimbalzi indietro'),
              ].map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(width: 4, height: 28,
                      decoration: BoxDecoration(color: r.$1,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text(r.$2, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.$3,
                      style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ]),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== DIALOGS ====================

class _ContentDialogArgs {
  final String emoji, title, subtitle, description;
  final GooseContent content;
  final Color color;
  final VoidCallback? onDismiss;

  const _ContentDialogArgs({
    required this.emoji, required this.title,
    required this.subtitle, required this.description,
    required this.content, required this.color,
    this.onDismiss,
  });
}

// ── Beautiful content modal ──
class _ContentDialog extends StatefulWidget {
  final _ContentDialogArgs args;
  const _ContentDialog({required this.args});

  @override
  State<_ContentDialog> createState() => _ContentDialogState();
}

class _ContentDialogState extends State<_ContentDialog>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int  _remaining = 0;
  bool _timerDone = false;
  late AnimationController _entryAnim;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    _scaleAnim = CurvedAnimation(parent: _entryAnim, curve: Curves.elasticOut);
    _entryAnim.forward();

    if (widget.args.content.timerSeconds != null) {
      _remaining = widget.args.content.timerSeconds!;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining <= 1) {
          _timer?.cancel();
          setState(() { _remaining = 0; _timerDone = true; });
          HapticFeedback.heavyImpact();
        } else {
          setState(() => _remaining--);
        }
      });
    }
  }

  @override
  void dispose() { _timer?.cancel(); _entryAnim.dispose(); super.dispose(); }

  String _fmt(int s) {
    final m = s ~/ 60, sec = s % 60;
    return m > 0 ? '${m}m ${sec.toString().padLeft(2,'0')}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final a    = widget.args;
    final hasT = a.content.timerSeconds != null;
    final c    = a.color;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_kSurface, const Color(0xFF12121E)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: c.withOpacity(0.35), blurRadius: 30, spreadRadius: 2),
              const BoxShadow(color: Colors.black87, blurRadius: 20),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.withOpacity(0.3), c.withOpacity(0.05)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                Text(a.emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(a.title,
                  style: TextStyle(
                    color: c, fontSize: 24, fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: c.withOpacity(0.6), blurRadius: 12)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(a.subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            ),

            // ── Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(children: [
                Text(a.description,
                    style: TextStyle(color: c.withOpacity(0.8), fontSize: 12),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(a.content.text,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w600, height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // ── Timer ──
                if (hasT) ...[
                  const SizedBox(height: 14),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_timerDone ? _kGreen : c).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _timerDone ? _kGreen : c, width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_timerDone ? Icons.check_circle : Icons.timer_outlined,
                          color: _timerDone ? _kGreen : c, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _timerDone ? 'Tempo scaduto! ✅' : _fmt(_remaining),
                        style: TextStyle(
                          color: _timerDone ? _kGreen : c,
                          fontSize: 20, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: 18),
              ]),
            ),

            // ── Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    if (a.onDismiss != null) a.onDismiss!();
                    else Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [c, c.withOpacity(0.7)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: c.withOpacity(0.5),
                          blurRadius: 14, spreadRadius: 1)],
                    ),
                    child: Text(
                      hasT && !_timerDone ? '✓ Fatto in anticipo' : 'Fatto! 😈',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold, letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Clothing removed modal ──
class _ClothingDialog extends StatelessWidget {
  final String playerName;
  final int    remaining;
  final String reason;
  final Color  color;

  const _ClothingDialog({
    required this.playerName, required this.remaining,
    required this.reason,     required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_kSurface, Color(0xFF12121E)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 28)],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('👗', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 10),
          Text('TOGLI UN CAPO!',
              style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 10)],
              )),
          const SizedBox(height: 10),
          Text(reason,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(children: [
              Text(playerName,
                  style: TextStyle(color: color,
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    i < remaining ? Icons.checkroom : Icons.close,
                    color: i < remaining ? color : Colors.white24,
                    size: 22,
                  ),
                )),
              ),
              const SizedBox(height: 4),
              Text(remaining == 0 ? '🔥 Nessun capo rimasto!' : '$remaining rimasti',
                  style: TextStyle(
                      color: remaining == 0 ? _kRed : Colors.white54,
                      fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)],
              ),
              child: const Text('Fatto! 😈',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ),
        ]),
      ),
    );
  }
}
