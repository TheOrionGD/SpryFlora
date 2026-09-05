import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/plant_model.dart';
import '../models/plant_species.dart';
import '../services/ai_service.dart';
import '../services/excel_service.dart';
import '../services/image_service.dart';
import '../services/plant_repository.dart';
import '../services/watering_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/skeuo_live_camera_screen.dart';
import '../widgets/app_background.dart';

/// Refactored Screen 09: Camera-First & AI Species Identification Add Plant Flow
/// 1. Direct Camera Capture prompt upon opening
/// 2. Groq & Hugging Face Vision AI Species Identification & Cross-checking
/// 3. Plant Details Confirmation & Saving
class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DateTime _plantingDate = DateTime.now();
  PlantSpecies? _selectedSpecies;
  String _plantEnvironment = 'Pot'; // 'Pot' or 'Outdoor'
  bool _isLoadingSpecies = true;
  bool _isAnalyzingPhoto = false;
  bool _isSaving = false;

  final ExcelService _excelService = ExcelService();
  final PlantRepository _plantRepository = PlantRepository();
  final ImageService _imageService = ImageService();
  final AIService _aiService = AIService();

  List<PlantSpecies> _speciesList = [];
  String? _initialPhotoPath;

  // AI Identification Results
  bool _isPlantDetected = true;
  String _detectedObjectType = 'Plant / Leaf';
  String? _rejectionReason;
  String _identifiedSpeciesName = '';
  int _aiConfidence = 95;
  bool _isNewDiscovery = false;

  @override
  void initState() {
    super.initState();
    _loadSpeciesAndOpenCamera();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSpeciesAndOpenCamera() async {
    try {
      final list = await _excelService.loadSpeciesDatabase();
      if (mounted) {
        setState(() {
          _speciesList = list;
          if (list.isNotEmpty) {
            _selectedSpecies = list.first;
          }
          _isLoadingSpecies = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSpecies = false);
    }

    // Automatically trigger Camera Capture on opening if no photo present yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialPhotoPath == null && mounted) {
        _openLiveCamera();
      }
    });
  }

  Future<void> _openLiveCamera() async {
    final livePhoto = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => SkeuoLiveCameraScreen(
          title: 'Capture Plant Photo',
          prefix: 'plant_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );

    if (livePhoto != null && mounted) {
      _processCapturedPhoto(livePhoto);
    }
  }

  Future<void> _processCapturedPhoto(String photoPath) async {
    setState(() {
      _initialPhotoPath = photoPath;
      _isAnalyzingPhoto = true;
    });

    // Create a temporary dummy model for analysis
    final tempPlant = PlantModel(
      id: 'temp',
      plantName: 'New Plant',
      speciesName: _selectedSpecies?.name ?? 'Tulsi',
      plantingDate: DateTime.now(),
      lifespanDays: 120,
      wateringIntervalDays: 3,
    );

    // Analyze captured photo using Groq Vision, Hugging Face, and Gemini API
    final result = await _aiService.analyzePlantPhoto(
      plant: tempPlant,
      photoPath: photoPath,
    );

    if (!mounted) return;

    setState(() {
      _isAnalyzingPhoto = false;
      _isPlantDetected = result.isPlantDetected;
      _detectedObjectType = result.detectedObjectType;
      _rejectionReason = result.rejectionReason;
      _identifiedSpeciesName = result.identifiedSpecies;
      _aiConfidence = result.confidencePercent;
      _isNewDiscovery = result.isNewDiscovery;

      if (result.isPlantDetected) {
        // Find or assign matching species in database
        if (result.matchedSpecies != null) {
          _selectedSpecies = result.matchedSpecies;
        } else {
          _selectedSpecies = PlantSpecies(
            commonName: result.identifiedSpecies,
            lifespanDays: 180,
            wateringIntervalDays: 3,
            sunlight: 'Bright Indirect Light',
            targetSunlightHours: 4,
            description: 'Identified by SpryFlora AI Vision.',
          );
        }

        // Auto-fill plant name if controller is empty
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = result.identifiedSpecies;
        }
      }
    });
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

    setState(() => _isSaving = true);

    try {
      final species = _selectedSpecies ??
          PlantSpecies(
            commonName: _identifiedSpeciesName.isNotEmpty
                ? _identifiedSpeciesName
                : 'Tulsi',
            lifespanDays: 180,
            wateringIntervalDays: 3,
          );

      final nextWatering = WateringService.calculateInitialNextWatering(
        _plantingDate,
        species.wateringIntervalDays,
      );

      final newPlant = PlantModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plantName: _nameController.text.trim(),
        speciesName: species.name,
        lifespanDays: species.lifespanDays,
        wateringIntervalDays: species.wateringIntervalDays,
        plantingDate: _plantingDate,
        lastWateredDate: _plantingDate,
        nextWateringDate: nextWatering,
        location: _plantEnvironment,
        initialPhotoPath: _initialPhotoPath,
      );

      await _plantRepository.addPlant(newPlant);

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
                                    'Groq & Hugging Face AI analyzing plant species...',
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
                          // Plant Name Input
                          _buildFieldLabel('Plant Nickname'),
                          const SizedBox(height: 6),
                          _buildTextInput(
                            controller: _nameController,
                            hint: 'Enter plant name (e.g. Tulsi, Rose)',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter a plant name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Identified Plant Species Selector
                          _buildFieldLabel('Species & Classification'),
                          const SizedBox(height: 6),
                          _buildSpeciesDropdown(),
                          const SizedBox(height: 16),

                          // Planting Date Selector
                          _buildFieldLabel('Planting Date'),
                          const SizedBox(height: 6),
                          _buildDateSelector(),
                          const SizedBox(height: 18),

                          // Environment Selector (Pot / Outdoor)
                          _buildFieldLabel('Where is it planted?'),
                          const SizedBox(height: 8),
                          _buildEnvironmentSelector(),
                          const SizedBox(height: 28),

                          // Submit Action Button
                          _isSaving
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: SkeuoTheme.primaryGreen),
                                )
                              : FunBouncyButton(
                                  text: 'Add Plant to Garden',
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
              'Add New Plant',
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
      onTap: _capturePhotoOptions,
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFC62828), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Non-Plant Image Detected',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _rejectionReason ??
                  'The AI scanner detected a $_detectedObjectType instead of a plant. Please capture a clear image of plant leaves.',
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
              label: const Text('Re-Scan Plant Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
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
                      : (_selectedSpecies?.name ?? 'Tulsi'),
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
              _isNewDiscovery ? 'NEW SPECIES' : 'GROQ & HF VERIFIED',
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

  Widget _buildSpeciesDropdown() {
    if (_isLoadingSpecies) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PlantSpecies>(
          value: _selectedSpecies,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: SkeuoTheme.primaryGreen),
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: SkeuoTheme.textPrimary,
          ),
          items: _speciesList.map((species) {
            return DropdownMenuItem<PlantSpecies>(
              value: species,
              child: Text(species.name),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedSpecies = val;
                if (_nameController.text.isEmpty) {
                  _nameController.text = val.name;
                }
              });
            }
          },
        ),
      ),
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
          label: 'Pot',
          isSelected: _plantEnvironment == 'Pot',
          onTap: () => setState(() => _plantEnvironment = 'Pot'),
        ),
        const SizedBox(width: 24),
        _buildEnvOption(
          label: 'Outdoor',
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

  Future<void> _capturePhotoOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Capture Plant Photo',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: SkeuoTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openLiveCamera();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF81C784), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_rounded,
                                size: 32, color: SkeuoTheme.primaryGreen),
                            const SizedBox(height: 8),
                            Text(
                              'Live Camera',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: SkeuoTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final path = await _imageService.pickFromGallery(
                          prefix:
                              'plant_${DateTime.now().millisecondsSinceEpoch}',
                        );
                        if (path != null && mounted) {
                          _processCapturedPhoto(path);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF81C784), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_library_rounded,
                                size: 32, color: SkeuoTheme.primaryGreen),
                            const SizedBox(height: 8),
                            Text(
                              'Gallery',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: SkeuoTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
