import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/plant_model.dart';
import '../models/plant_species.dart';
import '../services/excel_service.dart';
import '../services/plant_repository.dart';
import '../services/watering_service.dart';
import '../services/weather_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/app_background.dart';
import '../widgets/cloud_transition.dart';
import 'realtime_plant_scanner_screen.dart';

/// Screen 09 / Confirmation Screen: AI-Identified Plant Confirmation
/// Receives auto-captured real-time photo & AI classification from RealtimePlantScannerScreen
class AddPlantScreen extends StatefulWidget {
  final String? autoCapturedPhotoPath;
  final PlantSpecies? initialSpecies;
  final String? identifiedSpeciesName;
  final int? aiConfidence;
  final bool isNewDiscovery;
  final bool isPlantDetected;
  final String? rejectionReason;
  final String? detectedObjectType;

  const AddPlantScreen({
    super.key,
    this.autoCapturedPhotoPath,
    this.initialSpecies,
    this.identifiedSpeciesName,
    this.aiConfidence,
    this.isNewDiscovery = false,
    this.isPlantDetected = true,
    this.rejectionReason,
    this.detectedObjectType,
  });

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DateTime _plantingDate = DateTime.now();
  PlantSpecies? _selectedSpecies;
  String _plantEnvironment = 'Indoor'; // 'Indoor' or 'Outdoor'
  final _locationController = TextEditingController(text: 'Study Desk');
  String _selectedLocation = 'Study Desk';

  final List<Map<String, dynamic>> _popularLocations = const [
    {'name': 'Study Desk', 'emoji': '📚'},
    {'name': 'My Bedroom', 'emoji': '🛏️'},
    {'name': 'Window Sill', 'emoji': '🪟'},
    {'name': 'Balcony Garden', 'emoji': '🌿'},
    {'name': 'Playroom', 'emoji': '🧸'},
    {'name': 'Backyard Garden', 'emoji': '🏡'},
    {'name': 'Classroom', 'emoji': '🎒'},
    {'name': 'Living Room', 'emoji': '🛋️'},
  ];

  final bool _isAnalyzingPhoto = false;
  bool _isSaving = false;

  final ExcelService _excelService = ExcelService();
  final PlantRepository _plantRepository = PlantRepository();

  String? _initialPhotoPath;

  // AI Identification Results
  bool _isPlantDetected = true;
  String _detectedObjectType = 'Plant / Leaf';
  String? _rejectionReason;
  String _identifiedSpeciesName = '';
  int _aiConfidence = 90;
  bool _isNewDiscovery = false;

  @override
  void initState() {
    super.initState();
    _isPlantDetected = widget.isPlantDetected;
    _rejectionReason = widget.rejectionReason;
    _detectedObjectType = widget.detectedObjectType ?? 'Plant / Leaf';

    final isProblemOnFeature = !_isPlantDetected ||
        (widget.identifiedSpeciesName?.contains('Problem on SpryFlora') ?? false) ||
        (widget.detectedObjectType?.contains('Problem on SpryFlora') ?? false) ||
        (widget.rejectionReason?.contains('Problem on SpryFlora') ?? false);

    if (isProblemOnFeature) {
      _isPlantDetected = false;
      _selectedSpecies = null;
      _identifiedSpeciesName = '';
      _nameController.text = '';
      _aiConfidence = 0;
      _detectedObjectType = widget.detectedObjectType ?? 'Problem on SpryFlora feature';
      _rejectionReason = widget.rejectionReason ??
          'There is a problem on the SpryFlora plant recognition feature. Please select your plant species manually below.';
    } else if (widget.autoCapturedPhotoPath != null) {
      _initialPhotoPath = widget.autoCapturedPhotoPath;
      _selectedSpecies = widget.initialSpecies;
      _identifiedSpeciesName = widget.identifiedSpeciesName ?? (widget.initialSpecies?.name ?? '');
      _nameController.text = _identifiedSpeciesName.isNotEmpty ? 'My $_identifiedSpeciesName' : '';
      _aiConfidence = widget.aiConfidence ?? 90;
      _isNewDiscovery = widget.isNewDiscovery;
      _plantEnvironment = _detectPlantType(widget.initialSpecies);
    }
    _loadSpeciesAndOpenCamera();
    _fetchGpsLocation();
  }

  String _detectPlantType(PlantSpecies? species) {
    if (species == null) return 'Indoor';
    final light = species.sunlight.toLowerCase();
    final name = species.name.toLowerCase();
    if (light.contains('indoor') ||
        light.contains('low') ||
        name.contains('zz') ||
        name.contains('snake') ||
        name.contains('pothos') ||
        name.contains('money') ||
        name.contains('spider')) {
      return 'Indoor';
    }
    return 'Outdoor';
  }

  Future<void> _fetchGpsLocation() async {
    try {
      final pos = await WeatherService().getCurrentPosition();
      if (pos != null) {
        final loc = await WeatherService().reverseGeocode(pos.latitude, pos.longitude);
        if (mounted && loc.isNotEmpty) {
          setState(() {
            _selectedLocation = loc;
            _locationController.text = loc;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadSpeciesAndOpenCamera() async {
    try {
      await _excelService.loadSpeciesDatabase();
    } catch (_) {}

    // If opened directly without auto-captured photo, launch live scanner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialPhotoPath == null && mounted) {
        _openLiveCamera();
      }
    });
  }

  Future<void> _openLiveCamera() async {
    final navResult = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RealtimePlantScannerScreen()),
    );
    if (navResult == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _showSpeciesPickerBottomSheet() async {
    List<PlantSpecies> speciesList = _excelService.speciesList;
    if (speciesList.isEmpty) {
      try {
        speciesList = await _excelService.loadSpeciesDatabase();
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = filter.isEmpty
                ? speciesList
                : speciesList.where((s) {
                    final q = filter.toLowerCase();
                    return s.name.toLowerCase().contains(q) ||
                        s.description.toLowerCase().contains(q);
                  }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Botanical Species 🌿',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: SkeuoTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8EE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: TextField(
                      autofocus: false,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search_rounded, color: SkeuoTheme.primaryGreen),
                        hintText: 'Search plant species (e.g. Tulsi, Rose, Aloe)...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                      onChanged: (val) {
                        setSheetState(() => filter = val.trim());
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No matching species found.\nTry a different search term!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(color: SkeuoTheme.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, idx) {
                              final sp = filtered[idx];
                              final isSelected = _selectedSpecies?.name.toLowerCase() == sp.name.toLowerCase();
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFC8E6C9) : const Color(0xFFF1F8EE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('🌿', style: TextStyle(fontSize: 18)),
                                ),
                                title: Text(
                                  sp.name,
                                  style: GoogleFonts.nunito(
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                    color: isSelected ? SkeuoTheme.primaryGreen : SkeuoTheme.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '💧 Water every ${sp.wateringIntervalDays}d • ☀️ ${sp.sunlight}',
                                  style: GoogleFonts.nunito(fontSize: 12, color: SkeuoTheme.textSecondary),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded, color: SkeuoTheme.primaryGreen)
                                    : const Icon(Icons.chevron_right_rounded, color: Colors.black26),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  setState(() {
                                    _selectedSpecies = sp;
                                    _identifiedSpeciesName = sp.name;
                                    _isPlantDetected = true;
                                    if (_nameController.text.trim().isEmpty ||
                                        _nameController.text.startsWith('My ')) {
                                      _nameController.text = 'My ${sp.name}';
                                    }
                                    _plantEnvironment = _detectPlantType(sp);
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SkeuoTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: SkeuoTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _plantingDate = picked);
    }
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) return;

    if (_initialPhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture a photo of your plant!'),
          backgroundColor: SkeuoTheme.warningOrange,
        ),
      );
      return;
    }

    if (!_isPlantDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cannot save non-plant photo ($_detectedObjectType). Please capture a real plant photo.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (_selectedSpecies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your plant species from the botanical list below.'),
          backgroundColor: SkeuoTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final species = _selectedSpecies!;

      final nextWatering = WateringService.calculateInitialNextWatering(
        _plantingDate,
        species.wateringIntervalDays,
      );

      final finalLocation = _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : _selectedLocation;

      final newPlant = PlantModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plantName: _nameController.text.trim(),
        speciesName: species.name,
        lifespanDays: species.lifespanDays,
        wateringIntervalDays: species.wateringIntervalDays,
        plantingDate: _plantingDate,
        lastWateredDate: _plantingDate,
        nextWateringDate: nextWatering,
        location: finalLocation,
        initialPhotoPath: _initialPhotoPath,
      );

      await CloudTransitionOverlay.run(
        context,
        message: '🌱 Welcoming to My Plants...',
        task: () async {
          await _plantRepository.addPlant(newPlant);
        },
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              '🌱 "${newPlant.plantName}" added to your My Plants collection!'),
          backgroundColor: SkeuoTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save plant. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top App Bar
              _buildAppBar(),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Step 1 & Step 2: Camera Capture & Reticle Preview ──
                        _buildPhotoCaptureSection(),

                        const SizedBox(height: 18),

                        // AI Analysis Loading Indicator or Result Status
                        if (_isAnalyzingPhoto)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFF81C784)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: SkeuoTheme.primaryGreen,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'SpryFlora analyzing your plant species...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_initialPhotoPath != null)
                          _buildAIAnalysisBanner(),

                        const SizedBox(height: 20),

                        // ── Step 3: Plant Details Confirmation Form ───────────
                        if (_isPlantDetected) ...[
                          // Identified Data-Driven Species Card
                          _buildFieldLabel('Species & Classification (Data-Driven)'),
                          const SizedBox(height: 6),
                          _buildDataDrivenSpeciesCard(),
                          const SizedBox(height: 16),

                          // Plant Nickname Input
                          _buildFieldLabel('Plant Buddy Nickname 🏷️'),
                          const SizedBox(height: 6),
                          _buildTextInput(
                            controller: _nameController,
                            hint: 'Give your plant buddy a fun name! (e.g. Leafy, Spikey, Sunny)',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please give your plant buddy a name!';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Kid Care Guide Steps
                          _buildKidCareStepsSection(),
                          const SizedBox(height: 16),

                          // Planting Date Selector
                          _buildFieldLabel('Planting Birthday 🎂'),
                          const SizedBox(height: 6),
                          _buildDateSelector(),
                          const SizedBox(height: 18),

                          // Environment Selector (Pot / Outdoor)
                          _buildFieldLabel('Where is it growing? 🪴'),
                          const SizedBox(height: 8),
                          _buildEnvironmentSelector(),
                          const SizedBox(height: 18),

                          // Plant Location Selector & Custom Location Input
                          _buildFieldLabel('Where do you keep your plant buddy? 📍'),
                          const SizedBox(height: 8),
                          _buildLocationSelectorSection(),
                          const SizedBox(height: 28),

                          // Submit Action Button
                          _isSaving
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: SkeuoTheme.primaryGreen),
                                )
                              : FunBouncyButton(
                                  text: '🌱 Welcome Plant to My Garden! 🌟',
                                  onPressed: _savePlant,
                                  color: SkeuoTheme.primaryGreen,
                                  height: 52,
                                  fontSize: 17,
                                ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              'Adopt a Plant Buddy 🌱',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: SkeuoTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded,
                color: SkeuoTheme.primaryGreen, size: 24),
            tooltip: 'Live Camera',
            onPressed: _openLiveCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCaptureSection() {
    return GestureDetector(
      onTap: _openLiveCamera,
      child: Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          color: _initialPhotoPath == null
              ? const Color(0xFFE8F5E9)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isPlantDetected
                ? const Color(0xFF81C784)
                : const Color(0xFFE57373),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _initialPhotoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppPhotoView(
                      imagePath: _initialPhotoPath,
                      fit: BoxFit.cover,
                      fallback: const Center(
                        child: Icon(Icons.eco_rounded,
                            size: 48, color: SkeuoTheme.primaryGreen),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: SkeuoTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Retake',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC8E6C9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: SkeuoTheme.primaryGreen,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to Open Live Camera Scanner',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: SkeuoTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Snap your plant leaf or seedling to auto-identify',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SkeuoTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAIAnalysisBanner() {
    if (!_isPlantDetected) {
      final isFeatureIssue = _detectedObjectType.contains('SpryFlora') ||
          (_rejectionReason?.contains('SpryFlora') ?? false);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFeatureIssue ? const Color(0xFFFFF3E0) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFeatureIssue ? const Color(0xFFFFB74D) : const Color(0xFFEF5350),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: isFeatureIssue ? const Color(0xFFE65100) : const Color(0xFFC62828),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isFeatureIssue
                        ? 'Problem on SpryFlora Feature'
                        : 'Non-Plant Image Detected',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isFeatureIssue ? const Color(0xFFE65100) : const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _rejectionReason ??
                  (isFeatureIssue
                      ? 'There is a problem on the SpryFlora plant recognition feature. Please choose your plant species from the botanical catalog below or scan again.'
                      : 'The AI scanner detected a $_detectedObjectType instead of a plant. Please capture a clear image of plant leaves.'),
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openLiveCamera,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text(isFeatureIssue ? 'Re-Scan with SpryFlora Camera' : 'Re-Scan Plant Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFeatureIssue ? const Color(0xFFEF6C00) : const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _isNewDiscovery ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isNewDiscovery
              ? const Color(0xFFFFD54F)
              : const Color(0xFFE8F5E9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isNewDiscovery
                  ? const Color(0xFFFFECB3)
                  : const Color(0xFFE8F5E9),
            ),
            child: Text(
              _isNewDiscovery ? '🎖️' : '🌿',
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isNewDiscovery
                      ? 'New Discovery Identified!'
                      : 'AI Species Match ($_aiConfidence% Confidence)',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isNewDiscovery
                        ? const Color(0xFFE65100)
                        : SkeuoTheme.textSecondary,
                  ),
                ),
                Text(
                  _identifiedSpeciesName.isNotEmpty
                      ? _identifiedSpeciesName
                      : (_selectedSpecies?.name ?? 'Botanical Specimen'),
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: SkeuoTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isNewDiscovery
                  ? const Color(0xFFFF8F00)
                  : SkeuoTheme.primaryGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isNewDiscovery ? 'NEW SPECIES' : 'SPRYFLORA VERIFIED',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: SkeuoTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: SkeuoTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFFA5D6A7),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDataDrivenSpeciesCard() {
    if (_selectedSpecies == null) {
      return GestureDetector(
        onTap: _showSpeciesPickerBottomSheet,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8EE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
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
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFC8E6C9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded,
                    color: Color(0xFF2E7D32), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Botanical Species 🌿',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: SkeuoTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to choose species from SpryFlora database or scan a plant above.',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: SkeuoTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: SkeuoTheme.primaryGreen, size: 28),
            ],
          ),
        ),
      );
    }

    final speciesName = _selectedSpecies!.name;
    final description = _selectedSpecies!.description;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
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
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFC8E6C9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded,
                color: Color(0xFF2E7D32), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        speciesName,
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: SkeuoTheme.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showSpeciesPickerBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CHANGE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.edit_rounded, color: Colors.white, size: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SkeuoTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildMiniBadge(
                      icon: _plantEnvironment == 'Indoor' ? Icons.home_rounded : Icons.park_rounded,
                      label: '$_plantEnvironment Plant',
                      color: const Color(0xFF1E88E5),
                      bgColor: const Color(0xFFE3F2FD),
                    ),
                    _buildMiniBadge(
                      icon: Icons.my_location_rounded,
                      label: _selectedLocation.isNotEmpty ? _selectedLocation : 'GPS Location',
                      color: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFE8F5E9),
                    ),
                    _buildMiniBadge(
                      icon: Icons.straighten_rounded,
                      label: '15-25 cm • Day 0 Sprout',
                      color: const Color(0xFFE65100),
                      bgColor: const Color(0xFFFFF3E0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKidCareStepsSection() {
    final species = _selectedSpecies;
    final interval = species?.wateringIntervalDays ?? 3;
    final sunlight = species?.sunlight ?? 'Bright Light';
    final targetHours = species?.targetSunlightHours ?? 4;
    final temp = species?.idealTemp ?? '18°C - 30°C';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EBD8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                'Kid Care Guide — 5 Easy Steps',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: SkeuoTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCareStepRow(
            stepNumber: '1',
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF03A9F4),
            title: 'Watering Goal',
            subtitle: 'Water every $interval days in the morning',
          ),
          const SizedBox(height: 10),
          _buildCareStepRow(
            stepNumber: '2',
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFFFA000),
            title: 'Sunlight Target',
            subtitle: '$sunlight ($targetHours hours of light daily)',
          ),
          const SizedBox(height: 10),
          _buildCareStepRow(
            stepNumber: '3',
            icon: Icons.thermostat_rounded,
            iconColor: const Color(0xFFE74C3C),
            title: 'Ideal Temperature',
            subtitle: 'Thrives best in $temp',
          ),
          const SizedBox(height: 10),
          _buildCareStepRow(
            stepNumber: '4',
            icon: Icons.spa_rounded,
            iconColor: const Color(0xFF4CAF50),
            title: 'Growth Stage',
            subtitle: 'Starting at Seedling / Sprout stage',
          ),
          const SizedBox(height: 10),
          _buildCareStepRow(
            stepNumber: '5',
            icon: Icons.stars_rounded,
            iconColor: const Color(0xFF9C27B0),
            title: 'Daily Check-in Mission',
            subtitle: 'Check in daily to water, log sunlight & earn Eco XP!',
          ),
        ],
      ),
    );
  }

  Widget _buildCareStepRow({
    required String stepNumber,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: SkeuoTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: SkeuoTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final dateStr = DateFormat('dd MMM yyyy').format(_plantingDate);

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateStr,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SkeuoTheme.textPrimary,
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              color: SkeuoTheme.primaryGreen,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentSelector() {
    return Row(
      children: [
        _buildEnvOption(
          label: 'Flowerpot 🪴',
          isSelected: _plantEnvironment == 'Indoor' || _plantEnvironment == 'Pot',
          onTap: () => setState(() => _plantEnvironment = 'Indoor'),
        ),
        const SizedBox(width: 24),
        _buildEnvOption(
          label: 'Garden Ground 🌳',
          isSelected: _plantEnvironment == 'Outdoor',
          onTap: () => setState(() => _plantEnvironment = 'Outdoor'),
        ),
      ],
    );
  }

  Widget _buildEnvOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? SkeuoTheme.primaryGreen : Colors.white,
              border: Border.all(
                color: isSelected
                    ? SkeuoTheme.primaryGreen
                    : const Color(0xFFC8E6C9),
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? SkeuoTheme.textPrimary
                  : SkeuoTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularLocations.map((loc) {
            final name = loc['name'] as String;
            final emoji = loc['emoji'] as String;
            final isSelected = _selectedLocation == name &&
                (_locationController.text.trim() == name ||
                    _locationController.text.trim().isEmpty);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLocation = name;
                  _locationController.text = name;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? SkeuoTheme.primaryGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? SkeuoTheme.primaryGreen
                        : const Color(0xFFC8E6C9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: isSelected ? 6 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : SkeuoTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Custom Location Text Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: _locationController,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: SkeuoTheme.textPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.place_rounded,
                  color: SkeuoTheme.primaryGreen, size: 20),
              hintText: 'Or type where you keep it (e.g. My Bookshelf, Sunny Corner)',
              hintStyle: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SkeuoTheme.textSecondary.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _selectedLocation = val.trim();
              });
            },
          ),
        ),
      ],
    );
  }
}
