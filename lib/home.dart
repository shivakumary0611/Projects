// ignore_for_file: file_names
import 'package:cric_snap/database/databaseHelper.dart';
import 'package:cric_snap/innings/view.dart';
import 'package:cric_snap/innings/view_model.dart';
import 'package:cric_snap/match/view.dart';
import 'package:cric_snap/match/view_model.dart';
import 'package:cric_snap/players/view.dart';
import 'package:cric_snap/players/view_model.dart';
import 'package:cric_snap/services/quick_match_constants.dart';
import 'package:cric_snap/services/quick_match_data_source_db.dart';
import 'package:cric_snap/services/quick_match_service.dart';
import 'package:cric_snap/teams/view.dart';
import 'package:cric_snap/teams/view_model.dart';
import 'package:cric_snap/widget/custom_app_bar.dart';
import 'package:cric_snap/widget/custom_button.dart';
import 'package:cric_snap/widget/custom_text_field.dart';
import 'package:cric_snap/widget/navigation_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    _checkFirstTimeLaunch();
  }

  Future<void> _checkFirstTimeLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
      if (isFirstLaunch) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOnboardingGuide();
        });
      }
    } catch (_) {}
  }

  void _showOnboardingGuide() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _OnboardingDialog(
          onComplete: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_first_launch', false);
            } catch (_) {}
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Cric Snap',
        brandAssetPath: 'assets/images/app_icon.png',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<TeamViewModel>().loadTeams();
          if (!context.mounted) return;
          await context.read<PlayerViewModel>().loadPlayers();
          if (!context.mounted) return;
          await context.read<MatchesViewModel>().loadMatches();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1,
                children: [
                  NavigationCard(
                    key: const Key('home_quick_match_card'),
                    title: 'Quick Match',
                    icon: Icons.flash_on,
                    color: Colors.purple,
                    onTap: () {
                      _showQuickMatchSheet(context);
                    },
                  ),
                  NavigationCard(
                    title: 'Matches',
                    icon: Icons.sports_cricket,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MatchesView()),
                      );
                    },
                  ),
                  NavigationCard(
                    title: 'Players',
                    icon: Icons.person,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlayerView()),
                      );
                    },
                  ),
                  NavigationCard(
                    title: 'Teams',
                    icon: Icons.groups,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeamView()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Tips card ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pro Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _tipRow('Long press No Ball to enter free-hit runs'),
                    _tipRow('Long press Wide to add extra boundary runs'),
                    _tipRow('Long press Wicket to record runs on wicket ball'),
                    _tipRow('Pull down on any screen to refresh data'),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _tipRow(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.blue.shade400, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickMatchSheet(BuildContext parentContext) async {
    final oversController = TextEditingController(text: '5');
    final ballsPerOverController = TextEditingController(text: '6');
    final previewNum = await DatabaseHelper.instance.countMatches() + 1;
    if (!parentContext.mounted) return;

    showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final chipA = quickMatchTeamAName(previewNum);
        final chipB = quickMatchTeamBName(previewNum);

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.purple.shade600),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Quick Match',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _quickTeamChip(
                      label: chipA,
                      sub: 'Home - bats first',
                      color: Colors.deepOrange.shade100,
                    ),
                    const SizedBox(width: 10),
                    const Text('vs'),
                    const SizedBox(width: 10),
                    _quickTeamChip(
                      label: chipB,
                      sub: 'Away',
                      color: Colors.indigo.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        key: const Key('quick_match_overs_field'),
                        controller: oversController,
                        hint: 'Overs',
                        prefixIcon: Icons.sports_score,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomButton(
                  key: const Key('quick_match_start_button'),
                  title: 'Start Quick Match',
                  icon: Icons.play_arrow,
                  onPressed: () async {
                    final overs =
                        int.tryParse(oversController.text.trim()) ?? 5;
                    final ballsPerOver =
                        int.tryParse(ballsPerOverController.text.trim()) ?? 6;

                    if (overs <= 0) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid number of overs'),
                        ),
                      );
                      return;
                    }
                    if (ballsPerOver <= 0) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid balls per over'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(sheetContext);
                    await _startQuickMatch(parentContext, overs, ballsPerOver);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickTeamChip({
    required String label,
    required String sub,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startQuickMatch(
    BuildContext context,
    int overs,
    int ballsPerOver,
  ) async {
    try {
      final service = QuickMatchService(DbQuickMatchDataSource());
      final result = await service.start(
        overs: overs,
        ballsPerOver: ballsPerOver,
      );
      if (!context.mounted) return;

      final teamViewModel = context.read<TeamViewModel>();
      final matchesViewModel = context.read<MatchesViewModel>();
      final inningsViewModel = context.read<InningsViewModel>();

      await teamViewModel.loadTeams();
      if (!context.mounted) return;
      await matchesViewModel.loadMatches();
      if (!context.mounted) return;
      await inningsViewModel.loadInnings();
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InningsView(match: result.match)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start quick match: $e')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding Dialog (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingDialog extends StatefulWidget {
  final VoidCallback onComplete;
  const _OnboardingDialog({required this.onComplete});

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F4C3A), Color(0xFF082B20), Color(0xFF03140F)],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFFFBA08).withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: const Color(0xFFFFBA08).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        width: double.infinity,
        height: 540,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/app_icon.png',
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(width: 10),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ).createShader(bounds),
                      child: const Text(
                        'Cric Snap',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildWelcomePage(),
                    _buildFeaturesPage(),
                    _buildControlsPage(),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFFFFBA08)
                                : Colors.white30,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFBA08),
                        foregroundColor: const Color(0xFF0F4C3A),
                        minimumSize: const Size(120, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeInOutCubic,
                          );
                        } else {
                          widget.onComplete();
                          Navigator.pop(context);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _currentPage == 2
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(
              Icons.sports_cricket_rounded,
              size: 72,
              color: Color(0xFFFFBA08),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Cric Snap',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Capture, score, and record video highlights of your local cricket matches. Relive every boundary, wicket, and crucial delivery!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Features',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _featureRow(
            icon: Icons.flash_on_rounded,
            title: 'Quick Match',
            description:
                'Start scoring immediately with pre-configured team slots.',
          ),
          const SizedBox(height: 14),
          _featureRow(
            icon: Icons.videocam_rounded,
            title: 'Action Recordings',
            description:
                'Record highlights of deliveries and link them to scores.',
          ),
          const SizedBox(height: 14),
          _featureRow(
            icon: Icons.groups_rounded,
            title: 'Team & Player Management',
            description:
                'Register players, set rosters, and track career statistics.',
          ),
        ],
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFFBA08), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scoring Guide (Tap vs Long Press)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Main scoring buttons support quick actions and long presses:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),
            _controlRow(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFF59E0B),
              name: 'No Ball',
              tapAction: 'Quick tap scores 1 extra run automatically.',
              longAction:
                  'Long press opens choices for Free Hit scoring off the bat.',
            ),
            const SizedBox(height: 10),
            _controlRow(
              icon: Icons.swap_horiz,
              color: const Color(0xFF2563EB),
              name: 'Wide',
              tapAction: 'Quick tap scores 1 extra run automatically.',
              longAction:
                  'Long press opens choices to specify additional runs (byes/boundaries).',
            ),
            const SizedBox(height: 10),
            _controlRow(
              icon: Icons.close,
              color: const Color(0xFFDC2626),
              name: 'Wicket',
              tapAction: 'Quick tap records a normal wicket with 0 runs.',
              longAction:
                  'Long press opens choices to specify runs scored off the wicket ball.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlRow({
    required IconData icon,
    required Color color,
    required String name,
    required String tapAction,
    required String longAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Tap: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFBA08),
                        ),
                      ),
                      TextSpan(text: '$tapAction\n'),
                      const TextSpan(
                        text: 'Long Press: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFBA08),
                        ),
                      ),
                      TextSpan(text: longAction),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
