import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/leaderboard_service.dart';
import '../services/badge_service.dart';
import '../models/player_rank.dart';
import '../app_localizations.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeFilter = 'all';
  String? _selectedLeagueFilter;
  List<Map<String, dynamic>> _scores = [];
  bool _isLoading = true;
  int? _userRank;
  PlayerRank? _userRankInfo;
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String _currentMode = 'overall'; // 'classic', 'race', 'overall'

  final List<String> _avatars = ['😀', '😎', '🤓', '🦊', '🐱', '🐶', '🦁', '🐯', '🐻', '🐼', '🐨', '🐸', '🦄', '🐲', '👻', '🤖'];

  final List<Map<String, dynamic>> _leagues = [
    {'key': null, 'name': 'Tüm Ligler', 'emoji': '🌍', 'color': Colors.grey},
    {'key': 'bronze', 'name': 'Bronz', 'emoji': '🥉', 'color': Color(0xFFCD7F32)},
    {'key': 'silver', 'name': 'Gümüş', 'emoji': '🥈', 'color': Color(0xFFC0C0C0)},
    {'key': 'gold', 'name': 'Altın', 'emoji': '🥇', 'color': Color(0xFFFFD700)},
    {'key': 'platinum', 'name': 'Platin', 'emoji': '💎', 'color': Color(0xFF00CED1)},
    {'key': 'diamond', 'name': 'Elmas', 'emoji': '👑', 'color': Color(0xFF9400D3)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentMode = ['classic', 'race', 'overall'][_tabController.index];
      });
      _loadLeaderboard();
    });
    _loadLeaderboard();
    _loadUserRankInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRankInfo() async {
    final rankInfo = await LeaderboardService.getUserRankInfo();
    if (mounted) setState(() => _userRankInfo = rankInfo);
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    print('🔍 [LEADERBOARD] Loading... Mode: $_currentMode, Filter: $_selectedTimeFilter');
    try {
      List<Map<String, dynamic>> scores;

      if (_currentMode == 'overall') {
        // Overall mode - kullan mevcut sistemi
        print('🔍 [LEADERBOARD] Fetching overall leaderboard...');
        scores = await LeaderboardService.getLeaderboard(_selectedTimeFilter, leagueFilter: _selectedLeagueFilter);
      } else {
        // Classic veya Race mode - mod bazlı leaderboard
        print('🔍 [LEADERBOARD] Fetching mode leaderboard: $_currentMode');
        scores = await LeaderboardService.getModeLeaderboard(_currentMode, _selectedTimeFilter);

        // League filter uygula
        if (_selectedLeagueFilter != null) {
          scores = scores.where((s) => s['league'] == _selectedLeagueFilter).toList();
        }
      }

      print('✅ [LEADERBOARD] Got ${scores.length} scores');

      // User rank hesapla
      int? userRank;
      if (_currentUserId != null) {
        for (int i = 0; i < scores.length; i++) {
          if (scores[i]['odaId'] == _currentUserId) {
            userRank = i + 1;
            break;
          }
        }
      }

      setState(() { _scores = scores; _userRank = userRank; _isLoading = false; });
    } catch (e) {
      print('❌ [LEADERBOARD] Error: $e');
      print('❌ [LEADERBOARD] Stack trace: ${StackTrace.current}');
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _getUserBadge(String? userId) async {
    if (userId == null) return null;

    try {
      final snapshot = await FirebaseDatabase.instance.ref('users/$userId/selectedBadge').get();
      if (!snapshot.exists) return null;

      final badgeId = snapshot.value as String;
      final badge = BadgeType.getById(badgeId);
      return badge?.icon;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
            ? [const Color(0xFF1A237E), const Color(0xFF121212), const Color(0xFF121212)]
            : [const Color(0xFF90CAF9), const Color(0xFFE3F2FD), const Color(0xFFF5F5F5)],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Geri Butonu
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Başlık
                    Text(
                      '🏆 ${AppLocalizations.currentLanguage == 'tr' ? 'Liderlik Tablosu' : 'Leaderboard'}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Placeholder for symmetry
                    const SizedBox(width: 44),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Butonları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildTabButton(0, '⚔️', 'Klasik', isDark),
                    const SizedBox(width: 10),
                    _buildTabButton(1, '🏁', 'Race', isDark),
                    const SizedBox(width: 10),
                    _buildTabButton(2, '🌍', 'Genel', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // İçerik
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (_userRankInfo != null) _buildUserInfoBar(isDark),
                      const SizedBox(height: 12),
                      _buildTimeFilters(isDark),
                      const SizedBox(height: 12),
                      _buildLeagueFilters(isDark),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(50),
                              child: CircularProgressIndicator(),
                            )
                          : _scores.isEmpty
                              ? _buildEmptyState()
                              : _buildLeaderboardList(isDark),
                    ],
                  ),
                ),
              ),
              if (_userRank != null) _buildUserRankBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoBar(bool isDark) {
    final rank = _userRankInfo!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFD700).withOpacity(0.9), const Color(0xFFFF8C00).withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        // Sola yaslı - Lig
        _buildInfoChip(rank.leagueEmoji, rank.leagueName, Color(rank.leagueColor)),
        const Spacer(),
        // Ortada - Level
        _buildInfoChip('📊', 'Lvl ${rank.level}', Colors.blue),
        const Spacer(),
        // Ortada - Win Rate
        _buildInfoChip('🎯', '%${(rank.winRate * 100).toStringAsFixed(0)}', Colors.green),
        const Spacer(),
        // Sağa yaslı - Period Games
        _buildInfoChip('🎮', '${rank.periodGames}/25', Colors.orange),
      ]),
    );
  }

  Widget _buildInfoChip(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTimeFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        _buildTimeButton('today', AppLocalizations.get('lbToday'), Icons.today, isDark),
        const SizedBox(width: 10),
        _buildTimeButton('week', AppLocalizations.get('lbThisWeek'), Icons.date_range, isDark),
        const SizedBox(width: 10),
        _buildTimeButton('all', AppLocalizations.get('lbAllTime'), Icons.emoji_events, isDark),
      ]),
    );
  }

  Widget _buildTimeButton(String key, String label, IconData icon, bool isDark) {
    bool isSelected = _selectedTimeFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _selectedTimeFilter = key); _loadLeaderboard(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
              ? LinearGradient(colors: [const Color(0xFF4facfe), const Color(0xFF00f2fe)])
              : LinearGradient(
                  colors: isDark
                    ? [const Color(0xFF2D2D2D), const Color(0xFF252525)]
                    : [Colors.white, Colors.grey.shade50],
                ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                ? Colors.white.withOpacity(0.3)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF4facfe).withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLeagueFilters(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _leagues.length,
        itemBuilder: (context, index) {
          final league = _leagues[index];
          bool isSelected = _selectedLeagueFilter == league['key'];
          return GestureDetector(
            onTap: () { setState(() => _selectedLeagueFilter = league['key']); _loadLeaderboard(); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [(league['color'] as Color).withOpacity(0.9), (league['color'] as Color).withOpacity(0.7)],
                      )
                    : LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2D2D2D), const Color(0xFF252525)]
                            : [Colors.white, Colors.grey.shade50],
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (league['color'] as Color).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(children: [
                Text(league['emoji'], style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  league['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2D2D2D), const Color(0xFF252525)]
                : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('🎮', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.get('noScoresYet'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedLeagueFilter != null
                ? (AppLocalizations.currentLanguage == 'tr' ? 'Bu ligde henüz oyuncu yok!' : 'No players in this league yet!')
                : (AppLocalizations.currentLanguage == 'tr' ? 'Online oyun kazan ve sıralamaya gir!' : 'Win online games to enter the leaderboard!'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  Widget _buildLeaderboardList(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          _scores.length,
          (index) => _buildListItem(index, _scores[index], isDark),
        ),
      ),
    );
  }

  Widget _buildListItem(int index, Map<String, dynamic> score, bool isDark) {
    int rank = index + 1;
    int avatarIndex = score['avatar'] ?? 0;
    String avatar = avatarIndex < _avatars.length ? _avatars[avatarIndex] : '😀';
    String nickname = score['nickname'] ?? 'Anonim';
    int level = score['level'] ?? 1;
    double winRate = (score['winRate'] ?? 0.0).toDouble();
    int totalScore = score['totalScore'] ?? 0;
    String league = score['league'] ?? 'bronze';
    bool isCurrentUser = score['odaId'] == _currentUserId;

    String leagueEmoji = {'bronze': '🥉', 'silver': '🥈', 'gold': '🥇', 'platinum': '💎', 'diamond': '👑'}[league] ?? '🥉';

    // Top 3 için özel gradientler
    List<Color> getTopRankGradient() {
      if (rank == 1) return [const Color(0xFFFFD700), const Color(0xFFFF8C00)];
      if (rank == 2) return [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)];
      if (rank == 3) return [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
      return isDark
          ? [const Color(0xFF2D2D2D), const Color(0xFF252525)]
          : [Colors.white, Colors.grey.shade50];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isCurrentUser
            ? LinearGradient(colors: [const Color(0xFF2196F3).withOpacity(0.9), const Color(0xFF1976D2).withOpacity(0.9)])
            : rank <= 3
                ? LinearGradient(colors: getTopRankGradient())
                : LinearGradient(colors: getTopRankGradient()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? Colors.white.withOpacity(0.3)
              : rank <= 3
                  ? Colors.white.withOpacity(0.3)
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: 1.5,
        ),
        boxShadow: (isCurrentUser || rank <= 3)
            ? [
                BoxShadow(
                  color: isCurrentUser
                      ? const Color(0xFF2196F3).withOpacity(0.4)
                      : rank == 1
                          ? const Color(0xFFFFD700).withOpacity(0.4)
                          : rank == 2
                              ? const Color(0xFFC0C0C0).withOpacity(0.4)
                              : const Color(0xFFCD7F32).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isCurrentUser || rank <= 3
                ? Colors.white.withOpacity(0.25)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: rank <= 3 ? 18 : 14,
                color: isCurrentUser || rank <= 3
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(avatar, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: FutureBuilder<String?>(
                future: _getUserBadge(score['odaId']),
                builder: (context, snapshot) {
                  final badgeIcon = snapshot.data;
                  return Text(
                    badgeIcon != null ? '$badgeIcon $nickname' : nickname,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isCurrentUser || rank <= 3 ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            if (isCurrentUser) Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.currentLanguage == 'tr' ? 'SEN' : 'YOU',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            if (_currentMode == 'overall') ...[
              Text(leagueEmoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                'Lvl $level',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser || rank <= 3 ? Colors.white.withOpacity(0.85) : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '%${(winRate * 100).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser || rank <= 3 ? Colors.white.withOpacity(0.85) : Colors.green.shade600,
                ),
              ),
            ] else ...[
              Text(
                '${score['wins'] ?? 0} ${AppLocalizations.currentLanguage == 'tr' ? 'galibiyet' : 'wins'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser || rank <= 3 ? Colors.white.withOpacity(0.85) : Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${score['gamesPlayed'] ?? 0} ${AppLocalizations.currentLanguage == 'tr' ? 'oyun' : 'games'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser || rank <= 3 ? Colors.white.withOpacity(0.85) : Colors.grey.shade600,
                ),
              ),
              if (_currentMode == 'race' && score['fastestWin'] != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.timer, size: 12, color: isCurrentUser || rank <= 3 ? Colors.white.withOpacity(0.85) : Colors.orange.shade600),
                const SizedBox(width: 2),
                Text(_formatTime(score['fastestWin']), style: TextStyle(fontSize: 12, color: isCurrentUser || rank <= 3 ? Colors.white.withOpacity(0.85) : Colors.orange.shade600)),
              ],
            ],
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentUser || rank <= 3
                ? Colors.white.withOpacity(0.25)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text(
              '$totalScore',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCurrentUser || rank <= 3 ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            Text(
              _currentMode == 'overall'
                  ? (AppLocalizations.currentLanguage == 'tr' ? 'puan' : 'pts')
                  : (AppLocalizations.currentLanguage == 'tr' ? 'skor' : 'score'),
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser || rank <= 3 ? Colors.white.withOpacity(0.85) : Colors.grey.shade600,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTabButton(int index, String emoji, String label, bool isDark) {
    final isSelected = _tabController.index == index;

    // Seçili buton için özel renkler
    List<Color> getSelectedGradient() {
      if (index == 0) {
        // Klasik - Mavi
        return [Color(0xFF2196F3), Color(0xFF1976D2)];
      } else if (index == 1) {
        // Race - Mor
        return [Color(0xFF9C27B0), Color(0xFF7B1FA2)];
      } else {
        // Genel - Koyu Lacivert
        return [Color(0xFF1A237E), Color(0xFF0D1642)];
      }
    }

    Color getSelectedBorderColor() {
      if (index == 0) return Colors.blue.withOpacity(0.5);
      if (index == 1) return Colors.purple.withOpacity(0.5);
      return Color(0xFF3949AB).withOpacity(0.5);
    }

    Color getSelectedShadowColor() {
      if (index == 0) return Colors.blue.withOpacity(0.4);
      if (index == 1) return Colors.purple.withOpacity(0.4);
      return Color(0xFF1A237E).withOpacity(0.4);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabController.animateTo(index);
            _currentMode = index == 0 ? 'classic' : (index == 1 ? 'race' : 'overall');
          });
          _loadLeaderboard();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: getSelectedGradient())
                : LinearGradient(colors: isDark ? [Color(0xFF2D2D2D), Color(0xFF252525)] : [Colors.white, Colors.grey.shade50]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? getSelectedBorderColor() : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: getSelectedShadowColor(), blurRadius: 8, spreadRadius: 1)]
                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 0.5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserRankBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2196F3).withOpacity(0.9), const Color(0xFF1976D2).withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            '${AppLocalizations.get('yourRank')}: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#$_userRank',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (_userRankInfo != null && _currentMode == 'overall') ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_userRankInfo!.leagueEmoji} ${_userRankInfo!.leagueName}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
}