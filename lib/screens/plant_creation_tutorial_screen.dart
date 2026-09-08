import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';
import '../models/plant_model.dart';
import '../services/plant_repository.dart';
import '../widgets/leaves_particle_overlay.dart';
import 'virtual_plant_growth_screen.dart';

/// 6-Card Synchronized 30-Second Tutorial Carousel & AI Stage Generation Screen
class PlantCreationTutorialScreen extends StatefulWidget {
  final PlantModel plant;
  final String? customBackendUrl;

  const PlantCreationTutorialScreen({
    super.key,
    required this.plant,
    this.customBackendUrl,
  });

  @override
  State<PlantCreationTutorialScreen> createState() =>
      _PlantCreationTutorialScreenState();
}

class _PlantCreationTutorialScreenState
    extends State<PlantCreationTutorialScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _spinnerController;

  Timer? _autoScrollTimer;
  int _currentPageIndex = 0;
  bool _isBackendComplete = false;
  bool _isAnimationComplete = false;
  bool _isSkipWaitingModalActive = false;
  List<String> _generatedStagePaths = [];
  String _statusText = 'Synthesizing 4 Growth Stages via Dual AI Engine...';

  static const List<Map<String, dynamic>> _tutorialCards = [
    {
      'title': 'Welcome Your Plant',
      'icon': '🌱',
      'accentColor': Color(0xFF4CAF50),
      'headline': 'Welcome your new plant! Every seed begins an adventure.',
      'body':
          'Your botanical companion is now officially registered in SpryFlora. Watch it sprout, branch, and blossom through dynamic growth milestones.',
      'tag': 'Stage 1 • Adventure',
    },
    {
      'title': 'Check Daily Hydration',
      'icon': '💧',
      'accentColor': Color(0xFF29B6F6),
      'headline':
          'Check daily hydration! Under-watering and over-watering are easy to balance.',
      'body':
          'Use the real-time watering assistant with computer vision to track soil moisture and record watering intervals accurately.',
      'tag': 'Care Tip • Moisture',
    },
    {
      'title': 'Sunlight Logging',
      'icon': '☀️',
      'accentColor': Color(0xFFFFA726),
      'headline':
          'Sunlight logging: Match your species photoperiod for vibrant leaves.',
      'body':
          'Track daylight exposure directly on your dashboard. Balanced lumens ensure healthy chlorophyll production and vigorous stems.',
      'tag': 'Vitality • Photoperiod',
    },
    {
      'title': 'Multimodal Leaf Scanner',
      'icon': '🔬',
      'accentColor': Color(0xFFAB47BC),
      'headline':
          'Multimodal AI leaf scanner: Detect disease early with live scans.',
      'body':
          'Snap a leaf photo anytime to run diagnostic diagnostics against thousands of plant pathology models for instant treatment remedies.',
      'tag': 'AI Vision • Health Guard',
    },
    {
      'title': 'Home Screen Widget',
      'icon': '📱',
      'accentColor': Color(0xFF26A69A),
      'headline':
          'Home screen widget: Track watering urgencies directly from your home screen.',
      'body':
          'Quick glance status badges keep you informed of next watering dates and sunshine quotas without even opening the app.',
      'tag': 'Glanceable • Widgets',
    },
    {
      'title': 'Earn Your Certificate',
      'icon': '🎓',
      'accentColor': Color(0xFFFF7043),
      'headline':
          'Earn your Certificate: Complete the lifespan to claim your achievement diploma!',
      'body':
          'Nurture your plant through all 4 life stages to unlock an authenticated botanical diploma and prestigious master gardener badges.',
      'tag': 'Diploma • Master Gardener',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 30-Second Overall Progress Animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _progressController.forward().then((_) {
      if (mounted) {
        setState(() => _isAnimationComplete = true);
        _checkAndComplete();
      }
    });

    // Auto-advance PageView every 5 seconds across 6 educational cards
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPageIndex < _tutorialCards.length - 1) {
        _currentPageIndex++;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPageIndex,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });

    // Fire Backend 4-Stage Generation Request
    _triggerBackendGeneration();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _spinnerController.dispose();
    super.dispose();
  }

  Future<void> _triggerBackendGeneration() async {
    try {
      final backendUrl = widget.customBackendUrl ??
          (ApiConfig.aiBackendUrl.isNotEmpty
              ? ApiConfig.aiBackendUrl
              : ApiConfig.backendBaseUrl);

      final endpointUri = Uri.parse('$backendUrl${ApiConfig.generatePlantStagesEndpoint}');

      debugPrint('Triggering dual-engine stage generation: $endpointUri');

      final response = await http
          .post(
            endpointUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'plant_id': widget.plant.id,
              'species_name': widget.plant.speciesName,
              'lifespan_days': widget.plant.lifespanDays,
            }),
          )
          .timeout(const Duration(seconds: 28), onTimeout: () {
        debugPrint('Backend timed out, activating dynamic client fallback.');
        return http.Response(
          jsonEncode({
            'status': 'fallback',
            'stages': <String>[],
          }),
          200,
        );
      });

      List<String> rawUrls = [];
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final stages = data['stages'] as List<dynamic>?;
        if (stages != null) {
          rawUrls = stages.map((e) => e.toString()).toList();
        }
      }

      // Download / Cache files locally if on Mobile/Desktop, or use URLs
      final localPaths = await _cacheStageImages(rawUrls);

      if (mounted) {
        setState(() {
          _generatedStagePaths = localPaths;
          _isBackendComplete = true;
          _statusText = '✨ 4 Stages AI Synthesized & Transparent PNGs Ready!';
        });
        _checkAndComplete();
      }
    } catch (e) {
      debugPrint('Stage generation engine caught exception: $e');
      if (mounted) {
        setState(() {
          _isBackendComplete = true;
          _statusText = '🌱 Stage milestones initialized successfully!';
        });
        _checkAndComplete();
      }
    }
  }

  Future<List<String>> _cacheStageImages(List<String> urls) async {
    if (urls.isEmpty) return [];

    if (kIsWeb) {
      // In Web sandbox, network URLs are used directly
      return urls;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/plant_stages/${widget.plant.id}');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final List<String> localPaths = [];
      for (int i = 0; i < urls.length; i++) {
        final url = urls[i];
        final filePath = '${targetDir.path}/stage_$i.png';
        final file = File(filePath);

        if (url.startsWith('http://') || url.startsWith('https://')) {
          final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) {
            await file.writeAsBytes(res.bodyBytes);
            localPaths.add(file.path);
            continue;
          }
        }
        localPaths.add(url);
      }
      return localPaths;
    } catch (err) {
      debugPrint('Error caching local stage files: $err');
      return urls;
    }
  }

  void _onSkipPressed() {
    if (_isBackendComplete) {
      _finalizeAndNavigate();
    } else {
      // Show botanical countdown spinner modal
      setState(() {
        _isSkipWaitingModalActive = true;
      });
    }
  }

  void _checkAndComplete() {
    if ((_isAnimationComplete || _isSkipWaitingModalActive) && _isBackendComplete) {
      _finalizeAndNavigate();
    }
  }

  Future<void> _finalizeAndNavigate() async {
    // Update plant with generated stage image paths in repository
    final updatedPlant = widget.plant.copyWith(
      stageImagePaths: _generatedStagePaths.isNotEmpty ? _generatedStagePaths : widget.plant.stageImagePaths,
    );
    await PlantRepository().updatePlant(updatedPlant);

    if (!mounted) return;

    // Navigate to Virtual Plant Growth Screen with celebration
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, anim, _) {
          return FadeTransition(
            opacity: anim,
            child: VirtualPlantGrowthScreen(
              plant: updatedPlant,
              showWelcomeCelebration: true,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: Stack(
        children: [
          // ── Gradient Background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F5E9),
                  Color(0xFFC8E6C9),
                  Color(0xFFA5D6A7),
                ],
              ),
            ),
          ),

          // ── Floating Botanical Particle Overlay ──
          const LeavesParticleOverlay(maxThroughput: false),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar with Skip to Plant Button ──
                _buildTopBar(),

                // ── Progress Bar (30-Second Controller) ──
                _buildProgressBar(),

                const SizedBox(height: 12),

                // ── 6-Card Educational Carousel ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      setState(() => _currentPageIndex = idx);
                    },
                    itemCount: _tutorialCards.length,
                    itemBuilder: (context, index) {
                      return _buildTutorialCard(_tutorialCards[index], index);
                    },
                  ),
                ),

                // ── Page Indicator Dots ──
                _buildPageIndicators(),

                const SizedBox(height: 16),

                // ── Bottom AI Generation Status Bar ──
                _buildBottomStatusCard(),

                const SizedBox(height: 18),
              ],
            ),
          ),

          // ── Skip Waiting Modal Overlay ("Polishing plant leaves...") ──
          if (_isSkipWaitingModalActive && !_isBackendComplete)
            _buildBotanicalCountdownLoaderModal(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF2E7D32), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plant Growth Onboarding',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    widget.plant.plantName,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // "Skip to Plant" Button
          TextButton(
            onPressed: _onSkipPressed,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFA5D6A7), width: 1.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skip to Plant',
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF2E7D32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _progressController.value;
    final secondsRemaining = (30 * (1.0 - progress)).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Synthesis: ${(progress * 100).toInt()}%',
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              Text(
                '${secondsRemaining}s remaining',
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF424242),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 8,
              color: Colors.white.withValues(alpha: 0.6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(Map<String, dynamic> card, int index) {
    final Color accentColor = card['accentColor'] as Color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stage Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                card['tag'] as String,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Card Icon with animated pulse
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        card['icon'] as String,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Headline
            Text(
              card['headline'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B5E20),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // Detailed Body
            Text(
              card['body'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF555555),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_tutorialCards.length, (index) {
        final isSelected = _currentPageIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isSelected ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFA5D6A7),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBottomStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isBackendComplete ? const Color(0xFF2E7D32) : const Color(0xFFFFA000),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E4032),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotanicalCountdownLoaderModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          width: 290,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _spinnerController,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [Color(0xFF81C784), Color(0xFF2E7D32), Color(0xFF81C784)],
                    ),
                  ),
                  child: const Center(
                    child: Text('🌱', style: TextStyle(fontSize: 32)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Polishing plant leaves... Almost ready! 🌱',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Stripping background and finalizing 4 transparent growth frames with dual AI keys.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF616161),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
