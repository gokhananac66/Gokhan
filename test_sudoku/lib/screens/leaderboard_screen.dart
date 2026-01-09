import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/leaderboard_service.dart';
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
    try {
      List<Map<String, dynamic>> scores;

      if (_currentMode == 'overall') {
        // Overall mode - kullan mevcut sistemi
        scores = await LeaderboardService.getLeaderboard(_selectedTimeFilter, leagueFilter: _selectedLeagueFilter);
      } else {
        // Classic veya Race mode - mod bazlı leaderboard
        scores = await LeaderboardService.getModeLeaderboard(_currentMode, _selectedTimeFilter);

        // League filter uygula
        if (_selectedLeagueFilter != null) {
          scores = scores.where((s) => s['league'] == _selectedLeagueFilter).toList();
        }
      }

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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Liderlik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark ? [Color(0xFF2D2D2D), Color(0xFF1E1E1E)] : [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 8, spreadRadius: 1),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              indicator: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.sports_esports, size: 18), text: '⚔️ Klasik'),
                Tab(icon: Icon(Icons.speed, size: 18), text: '🏁 Race'),
                Tab(icon: Icon(Icons.emoji_events, size: 18), text: '🌍 Genel'),
              ],
            ),
          ),
        ),
      ),
      body: Column(children: [
        if (_userRankInfo != null) _buildUserInfoBar(isDark),
        _buildTimeFilters(isDark),
        _buildLeagueFilters(isDark),
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _scores.isEmpty ? _buildEmptyState() : _buildLeaderboardList(isDark)),
        if (_userRank != null) _buildUserRankBar(isDark),
      ]),
    );
  }

  Widget _buildUserInfoBar(bool isDark) {
    final rank = _userRankInfo!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(rank.leagueColor).withOpacity(0.3), Color(rank.leagueColor).withOpacity(0.1)])),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildInfoChip(rank.leagueEmoji, rank.leagueName, Color(rank.leagueColor)),
        _buildInfoChip('📊', 'Lvl ${rank.level}', Colors.blue),
        _buildInfoChip('🎯', '%${(rank.winRate * 100).toStringAsFixed(0)}', Colors.green),
        _buildInfoChip('🎮', '${rank.periodGames}/25', Colors.orange),
      ]),
    );
  }

  Widget _buildInfoChip(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
      ]),
    );
  }

  Widget _buildTimeFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(children: [
        _buildTimeButton('today', AppLocalizations.get('lbToday'), Icons.today, isDark),
        const SizedBox(width: 8),
        _buildTimeButton('week', AppLocalizations.get('lbThisWeek'), Icons.date_range, isDark),
        const SizedBox(width: 8),
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
              ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600])
              : null,
            color: isSelected ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5) : null,
            boxShadow: isSelected ? [
              BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
            ] : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            const SizedBox(width: 6),
            Flexible(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)), overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }

  Widget _buildLeagueFilters(bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _leagues.length,
        itemBuilder: (context, index) {
          final league = _leagues[index];
          bool isSelected = _selectedLeagueFilter == league['key'];
          return GestureDetector(
            onTap: () { setState(() => _selectedLeagueFilter = league['key']); _loadLeaderboard(); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: isSelected ? (league['color'] as Color).withOpacity(0.2) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100), borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? league['color'] as Color : Colors.transparent, width: 2)),
              child: Row(children: [
                Text(league['emoji'], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(league['name'], style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? league['color'] as Color : (isDark ? Colors.grey.shade400 : Colors.grey.shade700))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🎮', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      Text(AppLocalizations.get('noScoresYet'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(_selectedLeagueFilter != null ? 'Bu ligde henüz oyuncu yok!' : 'Online oyun kazan ve sıralamaya gir!', style: TextStyle(color: Colors.grey.shade600)),
    ]));
  }

  Widget _buildLeaderboardList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scores.length,
        itemBuilder: (context, index) => _buildListItem(index, _scores[index], isDark),
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
    Color rankColor = rank == 1 ? const Color(0xFFFFD700) : rank == 2 ? Colors.grey.shade400 : rank == 3 ? const Color(0xFFCD7F32) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser ? (isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser ? Border.all(color: Colors.blue, width: 2) : rank <= 3 ? Border.all(color: rankColor, width: 1) : null,
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: rank <= 3 ? rankColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300), shape: BoxShape.circle),
          child: Center(child: Text(rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: rank <= 3 ? 16 : 14, color: rank <= 3 ? Colors.white : (isDark ? Colors.white : Colors.black87)))),
        ),
        const SizedBox(width: 12),
        Text(avatar, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(nickname, style: TextStyle(fontWeight: FontWeight.bold, color: isCurrentUser ? Colors.blue : null), overflow: TextOverflow.ellipsis)),
            if (isCurrentUser) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)), child: const Text('SEN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
          ]),
          Row(children: [
            if (_currentMode == 'overall') ...[
              Text(leagueEmoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('Lvl $level', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Text('%${(winRate * 100).toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
            ] else ...[
              Text('${score['wins'] ?? 0} galibiyet', style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
              const SizedBox(width: 8),
              Text('${score['gamesPlayed'] ?? 0} oyun', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              if (_currentMode == 'race' && score['fastestWin'] != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.timer, size: 12, color: Colors.orange.shade600),
                const SizedBox(width: 2),
                Text(_formatTime(score['fastestWin']), style: TextStyle(fontSize: 12, color: Colors.orange.shade600)),
              ],
            ],
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$totalScore', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_currentMode == 'overall' ? 'puan' : 'skor', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
      ]),
    );
  }

  Widget _buildUserRankBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D2D2D), const Color(0xFF1E1E1E)]
              : [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          top: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            '${AppLocalizations.get('yourRank')}: ',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              '#$_userRank',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (_userRankInfo != null && _currentMode == 'overall') ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Color(_userRankInfo!.leagueColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(_userRankInfo!.leagueColor).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Text(
                '${_userRankInfo!.leagueEmoji} ${_userRankInfo!.leagueName}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(_userRankInfo!.leagueColor),
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