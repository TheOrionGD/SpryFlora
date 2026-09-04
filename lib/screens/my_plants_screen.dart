import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_model.dart';
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/fun_confetti_overlay.dart';
import 'add_plant_screen.dart';
import 'ai_eco_buddy_screen.dart';
import 'plant_details_screen.dart';
import 'profile_settings_screen.dart';
import 'virtual_companion_screen.dart';

/// Screen 10: My Plants (from 255.jpg)
class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final PlantRepository _plantRepository = PlantRepository();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    await _plantRepository.loadLocalData();
    await _notificationService.checkAndNotifyDuePlants(_plantRepository.plants);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<PlantModel> get _sortedPlants {
    final plants = List<PlantModel>.from(_plantRepository.plants);
    plants.sort((a, b) => b.plantingDate.compareTo(a.plantingDate));
    return plants;
  }

  @override
  Widget build(BuildContext context) {
    return FunConfettiOverlay(
      isActive: _showConfetti,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: SkeuoTheme.primaryGreen),
                      )
                    : ListenableBuilder(
                        listenable: _plantRepository,
                        builder: (context, _) {
                          final plants = _sortedPlants;
                          if (plants.isEmpty) return _buildEmptyState();
                          return RefreshIndicator(
                            color: SkeuoTheme.primaryGreen,
                            onRefresh: _loadPlants,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 12, 20, 16),
                              itemCount: plants.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _buildPlantCard(plants[index]),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Button: + Add Plant (Screen 10)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FunBouncyButton(
                  text: '+ Add Plant',
                  onPressed: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => const AddPlantScreen()),
                    );
                    if (res == true) {
                      _loadPlants();
                      setState(() => _showConfetti = true);
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        if (mounted) setState(() => _showConfetti = false);
                      });
                    }
                  },
                  color: SkeuoTheme.primaryGreen,
                  height: 52,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 1) return;
            switch (index) {
              case 0:
                Navigator.of(context).pop();
                break;
              case 2:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const AIEcoBuddyScreen()),
                );
                break;
              case 3:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const VirtualCompanionScreen()),
                );
                break;
              case 4:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const ProfileSettingsScreen()),
                );
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: SkeuoTheme.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'My Plants',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: SkeuoTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPlantCard(PlantModel plant) {
    final age = plant.ageInDays;
    final health = plant.health;
    final status = health >= 75 ? 'Healthy' : 'Needs Care';

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlantDetailsScreen(plantId: plant.id),
          ),
        );
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EBD8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Plant Thumbnail
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AppPhotoView(
                  imagePath: plant.initialPhotoPath,
                  fit: BoxFit.cover,
                  fallback: Image.asset(
                    'assets/sprites/plant_potted.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.spa_rounded,
                      color: SkeuoTheme.primaryGreen,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Plant Name & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.plantName,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SkeuoTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$status · $age ${age == 1 ? 'Day' : 'Days'}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SkeuoTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Health Percentage (Screen 10)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Health $health%',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: SkeuoTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/sprites/mascot_pot_happy.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.spa_rounded,
                size: 72,
                color: SkeuoTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Plants Yet!',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: SkeuoTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first plant to track its watering and growth.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SkeuoTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

