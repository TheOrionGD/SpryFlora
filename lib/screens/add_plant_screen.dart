import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/plant_model.dart';
import '../models/plant_species.dart';
import '../services/excel_service.dart';
import '../services/image_service.dart';
import '../services/plant_repository.dart';
import '../services/watering_service.dart';
import '../theme/skeuo_theme.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/fun_bouncy_button.dart';
import '../widgets/skeuo_live_camera_screen.dart';

/// Screen 09: Add New Plant (from 255.jpg)
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
  bool _isSaving = false;

  final ExcelService _excelService = ExcelService();
  final PlantRepository _plantRepository = PlantRepository();
  final ImageService _imageService = ImageService();

  List<PlantSpecies> _speciesList = [];
  String? _initialPhotoPath;

  @override
  void initState() {
    super.initState();
    _loadSpecies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecies() async {
    try {
      final list = await _excelService.loadSpeciesDatabase();
      setState(() {
        _speciesList = list;
        if (list.isNotEmpty) {
          _selectedSpecies = list.first;
        }
        _isLoadingSpecies = false;
      });
    } catch (_) {
      setState(() => _isLoadingSpecies = false);
    }
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
    if (_selectedSpecies == null) return;
    if (_initialPhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an initial photo of your plant!'),
          backgroundColor: SkeuoTheme.warningOrange,
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
      backgroundColor: SkeuoTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: < Add New Plant
            _buildAppBar(),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plant Name
                      _buildFieldLabel('Plant Name'),
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

                      // Plant Species Dropdown
                      _buildFieldLabel('Plant Species'),
                      const SizedBox(height: 6),
                      _buildSpeciesDropdown(),
                      const SizedBox(height: 16),

                      // Planting Date
                      _buildFieldLabel('Planting Date'),
                      const SizedBox(height: 6),
                      _buildDateSelector(),
                      const SizedBox(height: 18),

                      // Where is it planted?
                      _buildFieldLabel('Where is it planted?'),
                      const SizedBox(height: 8),
                      _buildEnvironmentSelector(),
                      const SizedBox(height: 20),

                      // Initial Photo
                      _buildFieldLabel('Initial Photo'),
                      const SizedBox(height: 8),
                      _buildPhotoUploadBox(),
                      const SizedBox(height: 28),

                      // Add Plant Button
                      _isSaving
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: SkeuoTheme.primaryGreen),
                            )
                          : FunBouncyButton(
                              text: 'Add Plant',
                              onPressed: _savePlant,
                              color: SkeuoTheme.primaryGreen,
                              height: 52,
                              fontSize: 17,
                            ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          const SizedBox(width: 48),
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
              color: isSelected ? SkeuoTheme.textPrimary : SkeuoTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadBox() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4E8CE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _initialPhotoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
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
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: SkeuoTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
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
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: SkeuoTheme.primaryGreen,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
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
                'Upload Plant Photo',
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
                      onTap: () async {
                        Navigator.pop(ctx);
                        final livePhoto =
                            await Navigator.of(context).push<String?>(
                          MaterialPageRoute(
                            builder: (_) => SkeuoLiveCameraScreen(
                              title: 'Capture Plant Photo',
                              prefix:
                                  'plant_${DateTime.now().millisecondsSinceEpoch}',
                            ),
                          ),
                        );
                        if (livePhoto != null && mounted) {
                          setState(() => _initialPhotoPath = livePhoto);
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
                          setState(() => _initialPhotoPath = path);
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
