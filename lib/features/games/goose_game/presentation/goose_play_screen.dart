import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

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

// ── Clothing slot icons per player ──
const _kIconsP1 = ['👕', '👖', '🩲', '🧦'];
const _kIconsP2 = ['👗', '👙', '🩱', '👠'];

// ── Board canvas / tile constants ──
const double _kTileW    = 96.0;    // isometric tile width
const double _kTileH    = 48.0;    // isometric tile height
const double _kBlockH   = 22.0;    // 3-D block depth
const double _kTileStep = 1.18;    // grid-to-screen spacing multiplier
const double _kRound    = 5.0;     // corner rounding for tiles
const double _kBoardCX  = 2200.0;  // board centre-X in the large canvas
const double _kBoardTY  = 80.0;    // board top-Y in the large canvas
const double _kCanvasW  = 3600.0;
const double _kCanvasH  = 1900.0;
const _kSkin = Color(0xFFFFCCBC);  // skin tone for pawn heads
const _kHair = Color(0xFF4A2C2A);  // dark hair colour

// ── Serpentine path: irregular winding snake ──
// The path winds with varying-width horizontal runs, vertical drops,
// narrowing passages, upward zigzags and repeating spiral modules.
// Grid spans cols 0-18, rows 0-37.  pos 0 = START, pos 100 = FINISH.
const List<Offset> _kGridPath = [
  // ── Right run (pos 0-6): Start→1→2→3→4→5→6 ──
  Offset(0, 0),    // 0  START
  Offset(1, 0),    // 1
  Offset(2, 0),    // 2
  Offset(3, 0),    // 3
  Offset(4, 0),    // 4
  Offset(5, 0),    // 5
  Offset(6, 0),    // 6

  // ── Drop 3 (pos 7-9): 6↓7↓8↓9 ──
  Offset(6, 1),    // 7
  Offset(6, 2),    // 8
  Offset(6, 3),    // 9

  // ── Right run (pos 10-14): 9→10→11→12→13→14 ──
  Offset(7, 3),    // 10
  Offset(8, 3),    // 11
  Offset(9, 3),    // 12
  Offset(10, 3),   // 13
  Offset(11, 3),   // 14

  // ── Drop 2 (pos 15-16): 14↓15↓16 ──
  Offset(11, 4),   // 15
  Offset(11, 5),   // 16

  // ── Drop + right run 7 (pos 17-23): 16↓17→18→…→23 ──
  Offset(11, 6),   // 17
  Offset(12, 6),   // 18
  Offset(13, 6),   // 19
  Offset(14, 6),   // 20
  Offset(15, 6),   // 21
  Offset(16, 6),   // 22
  Offset(17, 6),   // 23

  // ── Drop 2 (pos 24-25): 23↓24↓25 ──
  Offset(17, 7),   // 24
  Offset(17, 8),   // 25

  // ── Left 1 + drop (pos 26-27): 25←26↓27 ──
  Offset(16, 8),   // 26
  Offset(16, 9),   // 27

  // ── Left 2 + drop (pos 28-30): 27←28←29↓30 ──
  Offset(15, 9),   // 28
  Offset(14, 9),   // 29
  Offset(14, 10),  // 30

  // ── Left 2 + drop (pos 31-33): 30←31←32↓33 ──
  Offset(13, 10),  // 31
  Offset(12, 10),  // 32
  Offset(12, 11),  // 33

  // ── Drop + right 3 (pos 34-36): 33↓34→35→36 ──
  Offset(12, 12),  // 34
  Offset(13, 12),  // 35
  Offset(14, 12),  // 36

  // ── Drop 5 (pos 37-41): 36↓37↓38↓39↓40↓41 ──
  Offset(14, 13),  // 37
  Offset(14, 14),  // 38
  Offset(14, 15),  // 39
  Offset(14, 16),  // 40
  Offset(14, 17),  // 41

  // ── Right 2 + up 2 (pos 42-45): 41→42→43↑44↑45 ──
  Offset(15, 17),  // 42
  Offset(16, 17),  // 43
  Offset(16, 16),  // 44
  Offset(16, 15),  // 45

  // ── Right 2 (pos 46-47): 45→46→47 ──
  Offset(17, 15),  // 46
  Offset(18, 15),  // 47

  // ── Drop 5 (pos 48-52): 47↓48↓49↓50↓51↓52 ──
  Offset(18, 16),  // 48
  Offset(18, 17),  // 49
  Offset(18, 18),  // 50
  Offset(18, 19),  // 51
  Offset(18, 20),  // 52

  // ── Left 2 + drop (pos 53-55): 52←53←54↓55 ──
  Offset(17, 20),  // 53
  Offset(16, 20),  // 54
  Offset(16, 21),  // 55

  // ── Left 3 + drop (pos 56-59): 55←56←57←58↓59 ──
  Offset(15, 21),  // 56
  Offset(14, 21),  // 57
  Offset(13, 21),  // 58
  Offset(13, 22),  // 59

  // ── Drop + right 4 (pos 60-63): 59↓60→61→62→63 ──
  Offset(13, 23),  // 60
  Offset(14, 23),  // 61
  Offset(15, 23),  // 62
  Offset(16, 23),  // 63

  // ── Drop + right 2 (pos 64-66): 63↓64→65→66 ──
  Offset(16, 24),  // 64
  Offset(17, 24),  // 65
  Offset(18, 24),  // 66

  // ── Drop 3 (pos 67-69): 66↓67↓68↓69 ──
  Offset(18, 25),  // 67
  Offset(18, 26),  // 68
  Offset(18, 27),  // 69

  // ── Left 2 + up + left 4 (pos 70-75): 69←70←71↑72←73←74←75 ──
  Offset(17, 27),  // 70
  Offset(16, 27),  // 71
  Offset(16, 26),  // 72
  Offset(15, 26),  // 73
  Offset(14, 26),  // 74
  Offset(13, 26),  // 75

  // ── Drop 4 (pos 76-79): 75↓76↓77↓78↓79 ──
  Offset(13, 27),  // 76
  Offset(13, 28),  // 77
  Offset(13, 29),  // 78
  Offset(13, 30),  // 79

  // ── Right 3 + drop (pos 80-83): 79→80→81→82↓83 ──
  Offset(14, 30),  // 80
  Offset(15, 30),  // 81
  Offset(16, 30),  // 82
  Offset(16, 31),  // 83

  // ── Right 2 (pos 84-85): 83→84→85 ──
  Offset(17, 31),  // 84
  Offset(18, 31),  // 85

  // ── Drop 3 (pos 86-88): 85↓86↓87↓88 ──
  Offset(18, 32),  // 86
  Offset(18, 33),  // 87
  Offset(18, 34),  // 88

  // ── Left 2 + up + left 4 (pos 89-94): 88←89←90↑91←92←93←94 ──
  Offset(17, 34),  // 89
  Offset(16, 34),  // 90
  Offset(16, 33),  // 91
  Offset(15, 33),  // 92
  Offset(14, 33),  // 93
  Offset(13, 33),  // 94

  // ── Drop 4 (pos 95-98): 94↓95↓96↓97↓98 ──
  Offset(13, 34),  // 95
  Offset(13, 35),  // 96
  Offset(13, 36),  // 97
  Offset(13, 37),  // 98

  // ── Right 2 (pos 99-100 FINISH): 98→99→100 ──
  Offset(14, 37),  // 99
  Offset(15, 37),  // 100  FINISH 🏆
];

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

  // ── Background music ──
  final AudioPlayer _bgMusic = AudioPlayer();


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
    _startBgMusic();
  }

  Future<void> _startBgMusic() async {
    try {
      await _bgMusic.setReleaseMode(ReleaseMode.loop);
      await _bgMusic.setVolume(0.25);
      await _bgMusic.play(AssetSource('audio/goose_bg_music.mp3'));
    } catch (_) {
      // Audio file not yet available – silently ignore
    }
  }

  // Background image is now rendered as a widget (Image.asset) behind the board.

  @override
  void dispose() {
    _bgMusic.stop();
    _bgMusic.dispose();
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
    _bgMusic.stop();
    setState(() => _gameOver = true);
    await _showContentDialog(_ContentDialogArgs(
      emoji: '🏆', title: '${_playerName(_currentPlayer)} VINCE!',
      subtitle: 'Hai raggiunto la casella 100! 🎉',
      description: '🔥 PREMIO FINALE — Il partner del perdente esegue:',
      content: _rand(kFinalRewards), color: _kGold,
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

  // ── Player clothing panel (status bar) ──
  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1060), Color(0xFF1A0840)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.withOpacity(0.45)),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.25), blurRadius: 12)],
      ),
      child: Row(children: [
        Expanded(child: _buildClothingPanel(1)),
        Container(
          width: 1, height: 54,
          color: Colors.white.withOpacity(0.12),
          margin: const EdgeInsets.symmetric(horizontal: 10),
        ),
        Expanded(child: _buildClothingPanel(2)),
      ]),
    );
  }

  Widget _buildClothingPanel(int p) {
    final name     = _playerName(p);
    final clothes  = p == 1 ? _p1Clothing : _p2Clothing;
    final color    = _playerColor(p);
    final isActive = _currentPlayer == p && !_gameOver;
    final icons    = p == 1 ? _kIconsP1 : _kIconsP2;
    final onBoard  = p == 1 ? _p1OnBoard : _p2OnBoard;
    final pos      = p == 1 ? _p1Pos : _p2Pos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name row
        Row(children: [
          Icon(p == 1 ? Icons.male : Icons.female, color: color, size: 13),
          const SizedBox(width: 3),
          Expanded(
            child: Text(name,
              style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12,
                shadows: [Shadow(color: color.withOpacity(0.55), blurRadius: 5)],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            onBoard ? '📍$pos' : '🚀',
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.22),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text('▶', style: TextStyle(color: color, fontSize: 7)),
            ),
          ],
        ]),
        const SizedBox(height: 5),
        // Clothing icon slots
        Row(
          children: List.generate(4, (i) {
            final has = i < clothes;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: has ? color.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: has ? color.withOpacity(0.55) : Colors.white12,
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: has ? 1.0 : 0.18,
                    child: Text(icons[i], style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Isometric 3D board with camera follow ──
  Widget _buildBoard() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final vw = constraints.maxWidth;
      final vh = constraints.maxHeight;

      // Compute iso grid position for the active player
      final activePos = _currentPlayer == 1 ? _p1Pos : _p2Pos;
      final g = _kGridPath[activePos.clamp(0, _kGridPath.length - 1)];

      // Convert grid → canvas coordinates (with spacing multiplier)
      const hw = _kTileW / 2, hh = _kTileH / 2;
      final playerCX = _kBoardCX + (g.dx - g.dy) * hw * _kTileStep;
      final playerCY = _kBoardTY + (g.dx + g.dy) * hh * _kTileStep;

      // Camera offset: shift canvas so active player is viewport-centred
      final camEnd = Offset(vw / 2 - playerCX, vh / 2 - playerCY);

      final painter = _IsoBoardPainter(
        board: _board,
        p1Pos: _p1Pos,        p2Pos: _p2Pos,
        p1OnBoard: _p1OnBoard, p2OnBoard: _p2OnBoard,
        p1Color: _kP1,         p2Color: _kP2,
        p1Name: widget.config.player1Name,
        p2Name: widget.config.player2Name,
      );

      return Stack(
        children: [
          // Background image layer (static, fills viewport)
          Positioned.fill(
            child: Image.asset(
              'assets/images/goose_board_bg.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.45),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.3),
                    radius: 1.4,
                    colors: [
                      Color(0xFF1A0A2E),
                      Color(0xFF0D0D1A),
                      Color(0xFF050510),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Board layer
          ClipRect(
            child: TweenAnimationBuilder<Offset>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              tween: Tween<Offset>(end: camEnd),
              builder: (_, cam, child) =>
                  Transform.translate(offset: cam, child: child!),
              child: SizedBox(
                width:  _kCanvasW,
                height: _kCanvasH,
                child: CustomPaint(
                  size: const Size(_kCanvasW, _kCanvasH),
                  painter: painter,
                ),
              ),
            ),
          ),
        ],
      );
    });
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

// ==================== ISOMETRIC BOARD PAINTER ====================

class _IsoBoardPainter extends CustomPainter {
  final List<GooseSquare> board;
  final int    p1Pos, p2Pos;
  final bool   p1OnBoard, p2OnBoard;
  final Color  p1Color, p2Color;
  final String p1Name, p2Name;

  const _IsoBoardPainter({
    required this.board,
    required this.p1Pos,     required this.p2Pos,
    required this.p1OnBoard, required this.p2OnBoard,
    required this.p1Color,   required this.p2Color,
    required this.p1Name,    required this.p2Name,
  });

  // Map board position → isometric grid (col, row) using the spiral path.
  Offset _gridOf(int pos) =>
      _kGridPath[pos.clamp(0, _kGridPath.length - 1)];

  // Convert grid coordinate → screen coordinate (isometric projection).
  Offset _toScreen(Offset g) {
    const hw = _kTileW / 2, hh = _kTileH / 2;
    return Offset(
      _kBoardCX + (g.dx - g.dy) * hw * _kTileStep,
      _kBoardTY + (g.dx + g.dy) * hh * _kTileStep,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ── 0. Themed background ──
    _drawBackground(canvas, size);

    // ── 1. Draw path-connecting trail between consecutive cells ──
    final trailPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < board.length - 1; i++) {
      final from = _toScreen(_gridOf(i));
      final to   = _toScreen(_gridOf(i + 1));
      canvas.drawLine(from, to, trailPaint);
    }

    // Draw small direction arrows along the trail every 4 cells
    final arrowPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < board.length - 1; i += 4) {
      final from = _toScreen(_gridOf(i));
      final to   = _toScreen(_gridOf(i + 1));
      final mid  = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final dir  = Offset(to.dx - from.dx, to.dy - from.dy);
      final len  = dir.distance;
      if (len < 1) continue;
      final u = Offset(dir.dx / len, dir.dy / len);
      final perp = Offset(-u.dy, u.dx);
      const aLen = 5.0;
      final tip = Offset(mid.dx + u.dx * aLen, mid.dy + u.dy * aLen);
      canvas.drawLine(tip, Offset(mid.dx - u.dx * aLen + perp.dx * aLen,
          mid.dy - u.dy * aLen + perp.dy * aLen), arrowPaint);
      canvas.drawLine(tip, Offset(mid.dx - u.dx * aLen - perp.dx * aLen,
          mid.dy - u.dy * aLen - perp.dy * aLen), arrowPaint);
    }

    // ── 2. Draw tiles (painter's algorithm: far → near) ──
    final order = List.generate(board.length, (i) => i)
      ..sort((a, b) => (_gridOf(a).dx + _gridOf(a).dy)
          .compareTo(_gridOf(b).dx + _gridOf(b).dy));

    for (final pos in order) {
      if (pos >= board.length) continue;
      final sc = _toScreen(_gridOf(pos));
      _drawTile(canvas, sc, board[pos], pos == p1Pos, pos == p2Pos);
    }
  }

  // ── Themed background ──
  // Background image is rendered as a widget layer behind the CustomPaint.
  // Here we only draw a soft vignette overlay on the transparent canvas.
  void _drawBackground(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Soft vignette overlay
    canvas.drawRect(bgRect, Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.35),
        ],
        stops: const [0.4, 1.0],
      ).createShader(bgRect));
  }

  // Build a rounded isometric diamond path using quadratic bezier corners.
  Path _roundedDiamond(Offset vT, Offset vR, Offset vB, Offset vL, double r) {
    return Path()
      // Start mid-way on top-left edge, approach top vertex
      ..moveTo(vT.dx + (vL.dx - vT.dx) * r, vT.dy + (vL.dy - vT.dy) * r)
      // Round corner at top
      ..quadraticBezierTo(vT.dx, vT.dy,
          vT.dx + (vR.dx - vT.dx) * r, vT.dy + (vR.dy - vT.dy) * r)
      // Line to near right vertex
      ..lineTo(vR.dx + (vT.dx - vR.dx) * r, vR.dy + (vT.dy - vR.dy) * r)
      // Round corner at right
      ..quadraticBezierTo(vR.dx, vR.dy,
          vR.dx + (vB.dx - vR.dx) * r, vR.dy + (vB.dy - vR.dy) * r)
      // Line to near bottom vertex
      ..lineTo(vB.dx + (vR.dx - vB.dx) * r, vB.dy + (vR.dy - vB.dy) * r)
      // Round corner at bottom
      ..quadraticBezierTo(vB.dx, vB.dy,
          vB.dx + (vL.dx - vB.dx) * r, vB.dy + (vL.dy - vB.dy) * r)
      // Line to near left vertex
      ..lineTo(vL.dx + (vB.dx - vL.dx) * r, vL.dy + (vB.dy - vL.dy) * r)
      // Round corner at left
      ..quadraticBezierTo(vL.dx, vL.dy,
          vL.dx + (vT.dx - vL.dx) * r, vL.dy + (vT.dy - vL.dy) * r)
      ..close();
  }

  void _drawTile(Canvas canvas, Offset c, GooseSquare sq, bool hasP1, bool hasP2) {
    const hw = _kTileW / 2, hh = _kTileH / 2, bh = _kBlockH;
    const r = 0.12; // rounding factor (0 = sharp, 0.5 = max)
    final vT = Offset(c.dx,      c.dy - hh);
    final vR = Offset(c.dx + hw, c.dy     );
    final vB = Offset(c.dx,      c.dy + hh);
    final vL = Offset(c.dx - hw, c.dy     );

    final col   = _topColor(sq.type);
    final colBr = _brighten(col, 0.18); // brighter highlight
    final colL  = _dim(col, 0.30);
    final colR  = _dim(col, 0.48);

    // ── Soft glow shadow under tile ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + bh + 3), width: hw * 1.6, height: hh * 0.9),
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ── Left face (rounded bottom-left) ──
    final leftFace = Path()
      ..moveTo(vL.dx, vL.dy)..lineTo(vB.dx, vB.dy)
      ..lineTo(vB.dx, vB.dy + bh)
      ..quadraticBezierTo(vB.dx - hw * 0.06, vB.dy + bh,
          vL.dx, vL.dy + bh)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = colL);

    // ── Right face (rounded bottom-right) ──
    final rightFace = Path()
      ..moveTo(vB.dx, vB.dy)..lineTo(vR.dx, vR.dy)
      ..lineTo(vR.dx, vR.dy + bh)
      ..quadraticBezierTo(vR.dx - hw * 0.06, vR.dy + bh,
          vB.dx, vB.dy + bh)
      ..close();
    canvas.drawPath(rightFace, Paint()..color = colR);

    // ── Top face (rounded diamond) with gradient ──
    final topFace = _roundedDiamond(vT, vR, vB, vL, r);

    // Gradient fill: lighter at top-left, darker at bottom-right
    final topGrad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [colBr, col, _dim(col, 0.12)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCenter(center: c, width: hw * 2, height: hh * 2));
    canvas.drawPath(topFace, topGrad);

    // Subtle inner highlight at top edge
    canvas.drawPath(topFace, Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 1.2);

    // ── Glow border for special tiles ──
    final gc = _glowColor(sq.type);
    if (gc != null) {
      // Outer glow
      canvas.drawPath(topFace, Paint()
        ..style = PaintingStyle.stroke
        ..color = gc.withOpacity(0.35)
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      // Sharp border
      canvas.drawPath(topFace, Paint()
        ..style = PaintingStyle.stroke
        ..color = gc.withOpacity(0.8)
        ..strokeWidth = 1.8);
    }

    // ── Tile content (number, icon, destination) ──
    final isSpecial = sq.type != GooseSquareType.normal;

    if (!isSpecial) {
      // Normal tile: show position number
      if (sq.position > 0) {
        _txt(canvas, '${sq.position}', c,
            sz: _kTileW * 0.18, col: Colors.white.withOpacity(0.75), bold: true);
      } else {
        _txt(canvas, 'START', c,
            sz: _kTileW * 0.14, col: Colors.white70, bold: true);
      }
    } else {
      // Special tile: show big icon centred, NO position number
      switch (sq.type) {
        case GooseSquareType.ladder:
          _txt(canvas, '🪜', Offset(c.dx, c.dy - hh * 0.10), sz: _kTileW * 0.35); break;
        case GooseSquareType.hole:
          _txt(canvas, '🕳️', Offset(c.dx, c.dy - hh * 0.10), sz: _kTileW * 0.35); break;
        case GooseSquareType.penance:
          _txt(canvas, '🔥', Offset(c.dx, c.dy - hh * 0.10), sz: _kTileW * 0.32); break;
        case GooseSquareType.finish:
          _txt(canvas, '🏆', Offset(c.dx, c.dy - hh * 0.15), sz: _kTileW * 0.40); break;
        default: break;
      }
    }

    // ── Player pawns ──
    if (!hasP1 && !hasP2) return;
    final baseY = c.dy - hh - 6;
    if (hasP1 && hasP2) {
      _drawPawn(canvas, Offset(c.dx - 18, baseY), p1Color, '♂');
      _drawPawn(canvas, Offset(c.dx + 18, baseY), p2Color, '♀');
    } else if (hasP1) {
      _drawPawn(canvas, Offset(c.dx, baseY), p1Color, '♂');
    } else {
      _drawPawn(canvas, Offset(c.dx, baseY), p2Color, '♀');
    }
  }

  // ── Cute glowing gem pawn with heart shape ───────────────────────
  void _drawPawn(Canvas canvas, Offset base, Color color, String symbol) {
    const s = 16.0;
    final cx = base.dx, cy = base.dy - s * 1.5;

    // Outer glow halo
    canvas.drawCircle(Offset(cx, cy), s * 2.0, Paint()
      ..color = color.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    // Shadow on ground
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, base.dy + 2), width: s * 1.8, height: s * 0.5),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Pedestal (small rounded trapezoid)
    final pedestal = Path()
      ..moveTo(cx - s * 0.5, base.dy)
      ..lineTo(cx + s * 0.5, base.dy)
      ..lineTo(cx + s * 0.35, base.dy - s * 0.45)
      ..lineTo(cx - s * 0.35, base.dy - s * 0.45)
      ..close();
    canvas.drawPath(pedestal, Paint()..color = _dim(color, 0.45));
    canvas.drawPath(pedestal, Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.0);

    // Main gem body (rounded circle with gradient)
    final gemRect = Rect.fromCenter(center: Offset(cx, cy), width: s * 1.8, height: s * 1.8);
    canvas.drawOval(gemRect, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [_brighten(color, 0.5), color, _dim(color, 0.35)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(gemRect));

    // Glass highlight (top-left arc)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - s * 0.2, cy - s * 0.2), width: s * 1.2, height: s * 1.1),
      pi * 0.9, pi * 0.7, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withOpacity(0.55)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round);

    // Sparkle dot
    canvas.drawCircle(Offset(cx - s * 0.35, cy - s * 0.35), 2.0,
      Paint()..color = Colors.white.withOpacity(0.85));

    // Outer ring
    canvas.drawOval(gemRect, Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5);

    // Inner glow ring
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: s * 2.2, height: s * 2.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color.withOpacity(0.25)
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Gender symbol in centre
    _txt(canvas, symbol, Offset(cx, cy), sz: s * 0.85,
        col: Colors.white.withOpacity(0.9), bold: true);

    // Stem connecting pedestal to gem
    canvas.drawLine(
      Offset(cx, base.dy - s * 0.45),
      Offset(cx, cy + s * 0.9),
      Paint()
        ..color = _dim(color, 0.3)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round);
  }

  // ── Helpers ─────────────────────────────────────────────────────────
  Color _topColor(GooseSquareType t) {
    switch (t) {
      case GooseSquareType.normal:  return const Color(0xFF243555);
      case GooseSquareType.ladder:  return const Color(0xFF1A4A2A);
      case GooseSquareType.hole:    return const Color(0xFF4A1018);
      case GooseSquareType.penance: return const Color(0xFF4A2800);
      case GooseSquareType.finish:  return const Color(0xFF4A3A00);
    }
  }

  Color? _glowColor(GooseSquareType t) {
    switch (t) {
      case GooseSquareType.ladder:  return _kGreen;
      case GooseSquareType.hole:    return _kRed;
      case GooseSquareType.penance: return _kOrange;
      case GooseSquareType.finish:  return _kGold;
      default: return null;
    }
  }

  Color _dim(Color c, double f) => Color.fromARGB(
    c.alpha,
    (c.red   * (1 - f)).clamp(0, 255).round(),
    (c.green * (1 - f)).clamp(0, 255).round(),
    (c.blue  * (1 - f)).clamp(0, 255).round(),
  );

  Color _brighten(Color c, double f) => Color.fromARGB(
    c.alpha,
    (c.red   + (255 - c.red)   * f).clamp(0, 255).round(),
    (c.green + (255 - c.green) * f).clamp(0, 255).round(),
    (c.blue  + (255 - c.blue)  * f).clamp(0, 255).round(),
  );

  void _txt(Canvas canvas, String text, Offset center,
      {double sz = 10, Color col = Colors.white, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: sz, color: col, height: 1,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _IsoBoardPainter old) =>
      old.p1Pos != p1Pos || old.p2Pos != p2Pos ||
      old.p1OnBoard != p1OnBoard || old.p2OnBoard != p2OnBoard;
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
