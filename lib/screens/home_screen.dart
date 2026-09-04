import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../services/user_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/fun_animated_plant.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/fun_confetti_overlay.dart';
import 'add_plant_screen.dart';
import 'ai_eco_buddy_screen.dart';
import 'my_plants_screen.dart';
import 'plant_details_screen.dart';
import 'profile_settings_screen.dart';
import 'virtual_companion_screen.dart';
import 'mascot_journey_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late UserService _userService;
  late PlantRepository _plantRepo;
  UserProfile? _userProfile;
  VirtualPlant? _virtualPlant;
  bool _isLoading = true;
  bool _showWaterConfetti = false;
  bool _showWaterDroplets = false;

  late AnimationController _headerCtrl;
  late AnimationController _staggerCtrl;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    _plantRepo = PlantRepository();
    _plantRepo.addListener(_onRepoChanged);

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut),
    );

    _loadData();
  }

  void _onRepoChanged() {
    if (mounted) {
      setState(() {
        _userProfile = _userService.currentUser;
        _virtualPlant = _userService.virtualPlant;
      });
    }
  }

  @override
  void dispose() {
    _plantRepo.removeListener(_onRepoChanged);
    _headerCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _plantRepo.loadLocalData();
    await NotificationService().checkAndNotifyDuePlants(_plantRepo.plants);
    if (mounted) {
      setState(() {
        _userProfile = _userService.currentUser;
        _virtualPlant = _userService.virtualPlant;
        _isLoading = false;
      });
      _headerCtrl.forward();
      _staggerCtrl.forward();
    }
  }

  Future<void> _waterVirtualPlant() async {
    setState(() {
      _showWaterDroplets = true;
      _showWaterConfetti = false;
    });
    await _userService.waterVirtualPlant();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _virtualPlant = _userService.virtualPlant;
        _showWaterDroplets = false;
        _showWaterConfetti = true;
      });
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) setState(() => _showWaterConfetti = false);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅 Good Morning';
    if (hour < 17) return '☀️ Good Afternoon';
    return '🌙 Good Evening';
  }

  List<PlantModel> get _duePlants =>
      _plantRepo.plants.where((p) => p.isWateringDue).toList()
        ..sort((a, b) => a.daysUntilWatering.compareTo(b.daysUntilWatering));

  List<PlantModel> get _allPlantsSorted {
    final plants = List<PlantModel>.from(_plantRepo.plants);
    plants.sort((a, b) {
      // Overdue first
      if (a.isWateringDue && !b.isWateringDue) return -1;
      if (!a.isWateringDue && b.isWateringDue) return 1;
      return a.daysUntilWatering.compareTo(b.daysUntilWatering);
    });
    return plants;
  }

  int get _wateredTodayCount {
    final today = DateTime.now();
    return _plantRepo.plants.where((p) {
      final lw = p.lastWateredDate;
      return lw.year == today.year &&
          lw.month == today.month &&
          lw.day == today.day;
    }).length;
  }

  int get _sunlitTodayCount {
    return _plantRepo.plants.where((p) => p.isSunlightLoggedToday).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: SkeuoTheme.primaryGreen),
                const SizedBox(height: 16),
                Text('Loading your garden...',
                    style: SkeuoTheme.funBody(
                        size: 16, color: SkeuoTheme.primaryGreen)),
              ],
            ),
          ),
        ),
      );
    }

    return FunConfettiOverlay(
      isActive: _showWaterConfetti,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: SafeArea(
            child: FadeTransition(
              opacity: _headerFade,
              child: _buildBody(),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: SkeuoTheme.primaryGreen,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),

            // ── Today's Mission Card (Screen 08) ─────────────────────────
            _buildTodaysMissionCard(),
            const SizedBox(height: 18),

            // ── Gamified Mascot Journey Banner ───────────────────────────
            _buildMascotJourneyBanner(),
            const SizedBox(height: 18),

            // ── Quick Garden Stats Overview ─────────────────────────────
            _buildQuickStats(),
            const SizedBox(height: 18),

            // ── Your Plant Section Card (Screen 08) ──────────────────────
            _buildYourPlantSection(),
            const SizedBox(height: 18),

            // ── Interactive Virtual Companion Card ───────────────────────
            _buildVirtualCompanion(),
            const SizedBox(height: 18),

            // ── Today's Checklist Tasks ─────────────────────────────────
            _buildTodaysChecklist(),
            const SizedBox(height: 22),

            // ── My Plants Section (Screen 08) ────────────────────────────
            _buildSectionHeader('My Plants', onSeeAll: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => const MyPlantsScreen()),
                  )
                  .then((_) => _loadData());
            }),
            const SizedBox(height: 12),
            _buildPlantsList(),
            const SizedBox(height: 20),

            // ── Add First Plant CTA if empty ─────────────────────────────
            if (_plantRepo.plants.isEmpty) ...[
              _buildAddFirstPlantCTA(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _userProfile?.childName.trim();
    final displayName = (name != null && name.isNotEmpty) ? name : 'Green Hero';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, $displayName! 🌱',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: SkeuoTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Let's grow together!",
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SkeuoTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Notification bell icon in circular card (Screen 08)
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔔 You are up to date on all plant care tasks!'),
                backgroundColor: SkeuoTheme.primaryGreen,
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: SkeuoTheme.cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: SkeuoTheme.textPrimary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ── Today's Mission Card (matching Screen 08) ─────────────────────────
  Widget _buildTodaysMissionCard() {
    final hasDue = _duePlants.isNotEmpty;
    final missionText =
        hasDue ? 'Water your plant' : 'Keep plants healthy in sunlight';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E8CE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE1F5FE),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.water_drop_rounded,
                color: Color(0xFF03A9F4),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Mission",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: SkeuoTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  missionText,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SkeuoTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.spa_rounded,
            color: SkeuoTheme.primaryGreen,
            size: 24,
          ),
        ],
      ),
    );
  }

  // ── Gamified Mascot Journey Banner Widget ─────────────────────────────
  Widget _buildMascotJourneyBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MascotJourneyScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E8449),
              Color(0xFF2ECC71),
              Color(0xFF27AE60),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mascot Thumbnail / Icon
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 2),
              ),
              child: Image.asset(
                'assets/sprites/mascot_pot_happy.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1C40F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'GAMIFIED MAP',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '16 Milestones',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mascot Growth Journey',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Explore your level path from seed to grand tree!',
                    style: TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF1E8449),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Your Plant Section (matching Screen 08) ───────────────────────────
  Widget _buildYourPlantSection() {
    final health = _virtualPlant?.health ?? 86;
    final level = _virtualPlant?.level ?? 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Plant',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: SkeuoTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Mascot Image
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 120,
                  child: Image.asset(
                    'assets/sprites/mascot_pot_happy.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/logo/mascot_transparent.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Health & Level
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SkeuoTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '$health%',
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: SkeuoTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level $level',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SkeuoTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Stats ──────────────────────────────────────────────────────────────
  Widget _buildQuickStats() {
    final total = _plantRepo.plants.length;
    final wateredToday = _wateredTodayCount;
    final sunlitToday = _sunlitTodayCount;
    final dueCount = _duePlants.length;

    return Row(
      children: [
        Expanded(
            child: _buildStatCard('$total', 'Total\nPlants', '🌿',
                const Color(0xFFE8F5E9), SkeuoTheme.primaryGreen)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard('$wateredToday', 'Watered\nToday', '💧',
                const Color(0xFFE3F2FD), SkeuoTheme.waterBlue)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard('$sunlitToday', 'Sunlit\nToday', '☀️',
                const Color(0xFFFFF8E1), const Color(0xFFFFA000))),
        const SizedBox(width: 8),
        Expanded(
            child: _buildStatCard(
                '$dueCount',
                'Need\nWater',
                '⚠️',
                dueCount > 0
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFF1FAF1),
                dueCount > 0
                    ? const Color(0xFFEF5350)
                    : SkeuoTheme.primaryGreen)),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, String emoji, Color bg, Color color) {
    return _AnimatedCard(
      delay: 100,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: SkeuoTheme.raisedShadows(blur: 8, offset: 3),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value, style: SkeuoTheme.funHeading(size: 22, color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: SkeuoTheme.funLabel(
                    size: 10, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  // ── Virtual Companion ────────────────────────────────────────────────────────
  Widget _buildVirtualCompanion() {
    final health = _virtualPlant?.health.toDouble() ?? 70;
    final level = _virtualPlant?.level ?? 1;
    final waterings = _virtualPlant?.wateringsCount ?? 0;

    return _AnimatedCard(
      delay: 200,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: SkeuoTheme.yellowGreenGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: SkeuoTheme.highRaisedShadows(),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '🌟 My Buddy Plant',
                  style: SkeuoTheme.funHeading(size: 16, color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.$level ⭐',
                    style: SkeuoTheme.funLabel(size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animated plant with droplets on watering
            FunAnimatedPlant(
              health: health,
              size: 160,
              isWatered: _virtualPlant?.wateringsCount != null &&
                  _virtualPlant!.wateringsCount > 0,
              showDroplets: _showWaterDroplets,
            ),

            const SizedBox(height: 16),

            Text(
              'Watered $waterings times',
              style: SkeuoTheme.funLabel(
                  size: 11, color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FunBouncyButton(
                text: '💧 Water My Buddy!',
                onPressed: _waterVirtualPlant,
                color: Colors.white,
                textColor: SkeuoTheme.primaryGreenDark,
                height: 50,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Text(title,
            style:
                SkeuoTheme.funHeading(size: 18, color: SkeuoTheme.textPrimary)),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: SkeuoTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'See All →',
                style: SkeuoTheme.funLabel(
                    size: 12, color: SkeuoTheme.primaryGreen),
              ),
            ),
          ),
      ],
    );
  }

  // ── Plants List (horizontal) ─────────────────────────────────────────────────
  Widget _buildPlantsList() {
    final plants = _allPlantsSorted.take(8).toList();
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plants.length + 1, // +1 for "Add" button
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == plants.length) return _buildAddPlantCard();
          return _buildPlantMiniCard(plants[i], i);
        },
      ),
    );
  }

  Widget _buildPlantMiniCard(PlantModel plant, int index) {
    final isDue = plant.isWateringDue;
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (_) => PlantDetailsScreen(plantId: plant.id)))
          .then((_) => _loadData()),
      child: _AnimatedCard(
        delay: 300 + index * 80,
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: isDue ? const Color(0xFFFFEBEE) : SkeuoTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDue
                  ? const Color(0xFFEF9A9A)
                  : SkeuoTheme.primaryGreen.withValues(alpha: 0.2),
              width: isDue ? 2 : 1.5,
            ),
            boxShadow: SkeuoTheme.raisedShadows(blur: 8, offset: 3),
          ),
          child: Column(
            children: [
              // Top accent strip
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color:
                      isDue ? const Color(0xFFEF5350) : SkeuoTheme.primaryGreen,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPlantThumbnailSmall(plant),
                      const SizedBox(height: 8),
                      Text(
                        plant.plantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: SkeuoTheme.funBody(
                            size: 12,
                            color: SkeuoTheme.textPrimary,
                            weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      if (isDue)
                        const Text('💧 Now!',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFEF5350),
                                fontWeight: FontWeight.w800))
                      else
                        Text(
                          plant.daysUntilWatering == 0
                              ? '💧 Today'
                              : 'In ${plant.daysUntilWatering}d',
                          style: SkeuoTheme.funLabel(
                              size: 10, color: SkeuoTheme.primaryGreen),
                        ),
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

  Widget _buildPlantThumbnailSmall(PlantModel plant) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: SkeuoTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: AppPhotoView(
          imagePath: plant.initialPhotoPath,
          fit: BoxFit.cover,
          fallback: const Icon(Icons.local_florist_rounded,
              color: SkeuoTheme.primaryGreen, size: 28),
        ),
      ),
    );
  }

  Widget _buildAddPlantCard() {
    return GestureDetector(
      onTap: () async {
        final added = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const AddPlantScreen()),
        );
        if (added == true) _loadData();
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: SkeuoTheme.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: SkeuoTheme.primaryGreen.withValues(alpha: 0.3),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: SkeuoTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),
            Text('Add Plant',
                style: SkeuoTheme.funBody(
                    size: 12,
                    color: SkeuoTheme.primaryGreen,
                    weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ── Add First Plant CTA ──────────────────────────────────────────────────────
  Widget _buildAddFirstPlantCTA() {
    return _AnimatedCard(
      delay: 300,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF1FAF1), Color(0xFFE8F5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: SkeuoTheme.primaryGreen.withAlpha(80), width: 1.5),
          boxShadow: SkeuoTheme.raisedShadows(blur: 10, offset: 4),
        ),
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFA5D6A7), width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/illustrations/welcome_plant.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Plants Yet!',
              style: SkeuoTheme.funHeading(
                  size: 22, color: SkeuoTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first plant and start\nyour amazing garden journey! 🌿',
              textAlign: TextAlign.center,
              style:
                  SkeuoTheme.funBody(size: 14, color: SkeuoTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FunBouncyButton(
                text: '+ Add My First Plant 🌱',
                onPressed: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const AddPlantScreen()),
                  );
                  if (added == true) _loadData();
                },
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Today's Checklist ────────────────────────────────────────────────────────
  Widget _buildTodaysChecklist() {
    final plants = _plantRepo.plants;
    if (plants.isEmpty) return const SizedBox.shrink();

    final today = DateTime.now();
    final duePlants = plants.where((p) => p.isWateringDue).toList();
    final wateredToday = plants.where((p) {
      final lw = p.lastWateredDate;
      return lw.year == today.year &&
          lw.month == today.month &&
          lw.day == today.day;
    }).toList();
    final sunlitToday = plants.where((p) => p.isSunlightLoggedToday).toList();

    return _AnimatedCard(
      delay: 500,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SkeuoTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: SkeuoTheme.primaryGreen.withValues(alpha: 0.2),
              width: 1.5),
          boxShadow: SkeuoTheme.raisedShadows(blur: 8, offset: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📋 Today's Tasks",
                style: SkeuoTheme.funHeading(
                    size: 16, color: SkeuoTheme.textPrimary)),
            const SizedBox(height: 14),
            _buildChecklistItem(
              emoji: '💧',
              text: duePlants.isEmpty
                  ? 'All plants watered! Great job!'
                  : '${duePlants.length} plant${duePlants.length > 1 ? 's' : ''} need watering',
              isDone: duePlants.isEmpty,
            ),
            const SizedBox(height: 10),
            _buildChecklistItem(
              emoji: '☀️',
              text: sunlitToday.length == plants.length
                  ? 'All plants got their sunshine today!'
                  : '${sunlitToday.length} of ${plants.length} plants logged sunlight',
              isDone: sunlitToday.length == plants.length,
            ),
            const SizedBox(height: 10),
            _buildChecklistItem(
              emoji: '📸',
              text: wateredToday.isNotEmpty
                  ? 'Logged ${wateredToday.length} plant${wateredToday.length > 1 ? 's' : ''} today'
                  : 'No check-ins logged today yet',
              isDone: wateredToday.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(
      {required String emoji, required String text, required bool isDone}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone ? SkeuoTheme.primaryGreen : SkeuoTheme.surfaceDark,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : Icons.circle_outlined,
            color: isDone ? Colors.white : SkeuoTheme.textMuted,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: SkeuoTheme.funBody(
              size: 13,
              color: isDone
                  ? SkeuoTheme.primaryGreenDark
                  : SkeuoTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        if (index == _currentNavIndex) return;
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 0:
            break;
          case 1:
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MyPlantsScreen()))
                .then((_) {
              _loadData();
              setState(() => _currentNavIndex = 0);
            });
            break;
          case 2:
            Navigator.of(context)
                .push(
                    MaterialPageRoute(builder: (_) => const AIEcoBuddyScreen()))
                .then((_) {
              _loadData();
              setState(() => _currentNavIndex = 0);
            });
            break;
          case 3:
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (_) => const VirtualCompanionScreen()))
                .then((_) {
              _loadData();
              setState(() => _currentNavIndex = 0);
            });
            break;
          case 4:
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (_) => const ProfileSettingsScreen()))
                .then((_) {
              _loadData();
              setState(() => _currentNavIndex = 0);
            });
            break;
        }
      },
    );
  }
}

/// Slide-in + fade card with configurable delay
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, required this.delay});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: child),
      ),
      child: widget.child,
    );
  }
}

/// Pulsing widget for "!" alert icons
class _PulsingWidget extends StatefulWidget {
  final Widget child;
  const _PulsingWidget({required this.child});

  @override
  State<_PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<_PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}
