import 'package:flutter_test/flutter_test.dart';

// 1. Unit Tests - Models
import 'unit/models/plant_model_test.dart' as plant_model_test;
import 'unit/models/user_model_test.dart' as user_model_test;
import 'unit/models/daily_checkin_model_test.dart' as daily_checkin_model_test;
import 'unit/models/plant_species_test.dart' as plant_species_test;

// 2. Unit Tests - Services
import 'unit/services/plant_health_engine_test.dart' as plant_health_engine_test;
import 'unit/services/watering_service_test.dart' as watering_service_test;
import 'unit/services/plant_repository_test.dart' as plant_repository_test;
import 'unit/services/user_service_test.dart' as user_service_test;
import 'unit/services/ai_service_test.dart' as ai_service_test;
import 'unit/services/excel_service_test.dart' as excel_service_test;

// 3. Widget & UI Component Tests
import 'widgets/skeuo_components_test.dart' as skeuo_components_test;
import 'widgets/login_screen_test.dart' as login_screen_test;
import 'widgets/garden_screen_test.dart' as garden_screen_test;
import 'widgets/plant_details_screen_test.dart' as plant_details_screen_test;
import 'widgets/daily_checkin_screen_test.dart' as daily_checkin_screen_test;

// 4. End-to-End Integration Flow Tests
import 'integration/app_lifecycle_integration_test.dart' as app_lifecycle_integration_test;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SPR Flora - Master Test Suite', () {
    group('Unit Tests: Models', () {
      plant_model_test.main();
      user_model_test.main();
      daily_checkin_model_test.main();
      plant_species_test.main();
    });

    group('Unit Tests: Services & Business Logic', () {
      plant_health_engine_test.main();
      watering_service_test.main();
      plant_repository_test.main();
      user_service_test.main();
      ai_service_test.main();
      excel_service_test.main();
    });

    group('Widget & UI Tests', () {
      skeuo_components_test.main();
      login_screen_test.main();
      garden_screen_test.main();
      plant_details_screen_test.main();
      daily_checkin_screen_test.main();
    });

    group('Integration & App Lifecycle Flow Tests', () {
      app_lifecycle_integration_test.main();
    });
  });
}
