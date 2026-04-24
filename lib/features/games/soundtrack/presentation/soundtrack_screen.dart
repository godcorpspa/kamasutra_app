import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SoundtrackScreen extends StatefulWidget {
  const SoundtrackScreen({super.key});

  @override
  State<SoundtrackScreen> createState() => _SoundtrackScreenState();
}

class _SoundtrackScreenState extends State<SoundtrackScreen> {
  bool _gameStarted = false;
  int _currentPlayer = 1;
  int _currentRound = 0;

  final List<Map<String, dynamic>> _playlist = [];
  final TextEditingController _songController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();

  static const List<Map<String, dynamic>> _promptMeta = [
    {'key': 'first_impression', 'emoji': '✨', 'color': Color(0xFF8B5CF6)},
    {'key': 'special_moment', 'emoji': '💕', 'color': Color(0xFFEC4899)},
    {'key': 'road_trip', 'emoji': '🚗', 'color': Color(0xFF06B6D4)},
    {'key': 'romantic_evening', 'emoji': '🕯️', 'color': Color(0xFFF59E0B)},
    {'key': 'energy', 'emoji': '💃', 'color': Color(0xFF10B981)},
    {'key': 'comfort', 'emoji': '🤗', 'color': Color(0xFF6366F1)},
    {'key': 'passion', 'emoji': '🔥', 'color': Color(0xFFEF4444)},
    {'key': 'nostalgia', 'emoji': '⏳', 'color': Color(0xFF8B5CF6)},
    {'key': 'future_together', 'emoji': '🌟', 'color': Color(0xFFF97316)},
    {'key': 'our_song', 'emoji': '💑', 'color': Color(0xFFEC4899)},
  ];

  List<Map<String, dynamic>> get _prompts => _promptMeta.map((meta) {
    final key = meta['key'] as String;
    return {
      'title': 'soundtrack_prompts.$key.title'.tr(),
      'description': 'soundtrack_prompts.$key.desc'.tr(),
      'emoji': meta['emoji'],
      'color': meta['color'],
    };
  }).toList();

  @override
  void dispose() {
    _songController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'games.soundtrack.app_bar_title'.tr(),
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
          // Header
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.music_note,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'game_ui.your_soundtrack'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'game_ui.create_love_playlist'.tr(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Preview prompts
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
                  'game_ui.playlist_themes'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _prompts.take(5).map((prompt) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (prompt['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            prompt['emoji'] as String,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            prompt['title'] as String,
                            style: TextStyle(
                              color: prompt['color'] as Color,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'game_ui.and_more_themes'.tr(args: ['${_prompts.length - 5}']),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // How it works
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
                  'game_ui.how_it_works'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildHowItWorksStep(
                  Icons.music_note,
                  'games.soundtrack.step_receive_theme'.tr(),
                  const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 12),
                _buildHowItWorksStep(
                  Icons.edit,
                  'games.soundtrack.step_choose_song'.tr(),
                  const Color(0xFFEC4899),
                ),
                const SizedBox(height: 12),
                _buildHowItWorksStep(
                  Icons.playlist_play,
                  'games.soundtrack.step_final_playlist'.tr(),
                  const Color(0xFF10B981),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _gameStarted = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'game_ui.create_playlist'.tr(),
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

  Widget _buildHowItWorksStep(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
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
    if (_currentRound >= _prompts.length) {
      return _buildPlaylistView();
    }

    final prompt = _prompts[_currentRound];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'game_ui.song_of'.tr(namedArgs: {'current': '${_currentRound + 1}', 'total': '${_prompts.length}'}),
                style: const TextStyle(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _currentPlayer == 1
                      ? const Color(0xFF8B5CF6).withOpacity(0.3)
                      : const Color(0xFFEC4899).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'game_ui.player_chooses'.tr(namedArgs: {'player': '$_currentPlayer'}),
                  style: TextStyle(
                    color: _currentPlayer == 1
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFFEC4899),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentRound + 1) / _prompts.length,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
          const SizedBox(height: 32),

          // Prompt card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (prompt['color'] as Color).withOpacity(0.3),
                  (prompt['color'] as Color).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (prompt['color'] as Color).withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                Text(
                  prompt['emoji'] as String,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  prompt['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prompt['description'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Input fields
          TextField(
            controller: _songController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'game_ui.song_title_label'.tr(),
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: const Icon(Icons.music_note, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _artistController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'game_ui.artist_label'.tr(),
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: const Icon(Icons.person, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _skipPrompt,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('game_ui.skip_action'.tr()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _addSong,
                  icon: const Icon(Icons.add),
                  label: Text('game_ui.add_btn'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: prompt['color'] as Color,
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

  void _addSong() {
    if (_songController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('game_ui.enter_song_title'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prompt = _prompts[_currentRound];

    setState(() {
      _playlist.add({
        'song': _songController.text,
        'artist': _artistController.text.isEmpty ? 'game_ui.unknown_artist'.tr() : _artistController.text,
        'theme': prompt['title'],
        'emoji': prompt['emoji'],
        'color': prompt['color'],
        'addedBy': _currentPlayer,
      });

      _songController.clear();
      _artistController.clear();
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      _currentRound++;
    });
  }

  void _skipPrompt() {
    setState(() {
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      _currentRound++;
    });
  }

  Widget _buildPlaylistView() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8B5CF6).withOpacity(0.3),
                const Color(0xFFEC4899).withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.playlist_play,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'game_ui.your_playlist'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'game_ui.songs_count'.tr(namedArgs: {'count': '${_playlist.length}'}),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        // Playlist
        Expanded(
          child: _playlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'game_ui.no_songs_added'.tr(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _playlist.length,
                  itemBuilder: (context, index) {
                    final song = _playlist[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (song['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (song['color'] as Color).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: (song['color'] as Color).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                song['emoji'] as String,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song['song'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  song['artist'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${song['theme']} • Partner ${song['addedBy']}',
                                  style: TextStyle(
                                    color: song['color'] as Color,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('game_ui.exit'.tr()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _restartGame,
                  icon: const Icon(Icons.refresh),
                  label: Text('game_ui.new_playlist'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
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

  void _restartGame() {
    setState(() {
      _playlist.clear();
      _currentRound = 0;
      _currentPlayer = 1;
    });
  }
}
