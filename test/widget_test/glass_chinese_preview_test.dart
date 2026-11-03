import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_look.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/glass_surface.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/app_theme.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/home/presentation/widgets/quick_water_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/quick_weight_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/steps_home_card.dart';
import 'package:opennutritracker/features/profile/presentation/weight_history_screen.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/run_ai_endpoint_probe_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/settings_screen.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// Renders the mint look in Simplified Chinese with the real screens.
///
/// The widget-test renderer deadlocks on a live backdrop blur, so the
/// floating bar keeps its translucent fill and the running app blurs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('glass screens render in Simplified Chinese', (tester) async {
    AppPalette.activeLook = AppLook.glass;
    final preferred = Directory('/opt/cursor/artifacts/screenshots');
    final dir = preferred.parent.existsSync()
        ? (preferred..createSync(recursive: true))
        : Directory.systemTemp.createTempSync('glass-shots');
    await tester.runAsync(() async {
      await initializeDateFormatting('zh');
      await _loadFont('Nunito', 'fonts/Nunito.ttf');
      await _loadFont('CustomIcons', 'fonts/CustomIcons.ttf');
      await _loadFont(
        'PreviewLatin',
        '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
      );
      await _loadFont(
        'PreviewCjk',
        '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf',
      );
      await _loadFont(
        'MaterialIcons',
        '${Platform.environment['HOME']}/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
    });
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = lookupS(const Locale('zh'));

    Future<void> shoot(
      String name,
      Widget body, {
      Size size = const Size(390, 844),
    }) async {
      await tester.binding.setSurfaceSize(size);
      final base = buildAppTheme(AppPalette.light, glass: true);
      const fallback = ['PreviewLatin', 'PreviewCjk'];
      final withCjk = base.textTheme.apply(
        fontFamily: 'Nunito',
        fontFamilyFallback: fallback,
      );
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => EnergyUnitProvider(usesKilojoules: false),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            theme: base.copyWith(
              textTheme: withCjk,
              primaryTextTheme: base.primaryTextTheme.apply(
                fontFamily: 'Nunito',
                fontFamilyFallback: fallback,
              ),
              appBarTheme: base.appBarTheme.copyWith(
                titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
                  fontFamily: 'Nunito',
                  fontFamilyFallback: fallback,
                ),
              ),
              // Button themes were built from the original text theme, so
              // they do not pick up the fallback applied above. Without it
              // a label such as 开启 draws as empty boxes.
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: base.colorScheme.primary,
                  textStyle: withCjk.labelLarge,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: base.colorScheme.primary,
                  foregroundColor: base.colorScheme.onPrimary,
                  textStyle: withCjk.labelLarge,
                ),
              ),
            ),
            builder: (context, child) => RepaintBoundary(
              key: const Key('shot'),
              child: child ?? const SizedBox.shrink(),
            ),
            home: body,
          ),
        ),
      );
      await tester.pump();
      // Let the calorie ring and the step-card future finish. A single
      // timed pump does not wait for idle, so a repeating ticker cannot hang.
      await tester.pump(const Duration(milliseconds: 900));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('shot')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${dir.path}/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await shoot(
      'home',
      Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: Text(s.homeLabel),
          backgroundColor: Colors.transparent,
          flexibleSpace: const GlassBarBackground(),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            DashboardWidget(
              totalKcalDaily: 1600,
              totalKcalLeft: 640,
              totalKcalSupplied: 780,
              totalKcalBurned: 180,
              totalCarbsIntake: 90,
              totalFatsIntake: 28,
              totalProteinsIntake: 42,
              totalCarbsGoal: 200,
              totalFatsGoal: 50,
              totalProteinsGoal: 80,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: QuickWeightWidget(
                      weightKg: 62.4,
                      bodyWeightUnit: BodyWeightUnit.kg,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: StepsHomeCard()),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: QuickWaterWidget(waterMlToday: 800, waterGoalMl: 2000),
            ),
            for (final meal in <(String, IconData, AddMealType, double)>[
              (
                s.breakfastLabel,
                Icons.bakery_dining_outlined,
                AddMealType.breakfastType,
                400,
              ),
              (
                s.lunchLabel,
                Icons.lunch_dining_outlined,
                AddMealType.lunchType,
                550,
              ),
              (
                s.dinnerLabel,
                Icons.dinner_dining_outlined,
                AddMealType.dinnerType,
                500,
              ),
              (
                s.snackLabel,
                CustomIcons.food_apple_outline,
                AddMealType.snackType,
                150,
              ),
            ])
              IntakeVerticalList(
                day: DateTime(2026, 11, 3),
                title: meal.$1,
                listIcon: meal.$2,
                addMealType: meal.$3,
                intakeList: const [],
                usesImperialUnits: false,
                mealKcalTarget: meal.$4,
                onDeleteIntakeCallback: (_, _) {},
              ),
          ],
        ),
        bottomNavigationBar: _PreviewGlassBar(
          labels: [s.homeLabel, s.diaryLabel, s.trendsLabel, s.youLabel],
        ),
      ),
      size: const Size(390, 1280),
    );

    final today = DateTime(2026, 11, 3);
    await shoot(
      'diary',
      Scaffold(
        appBar: AppBar(
          title: Text(s.diaryLabel),
          backgroundColor: Colors.transparent,
          flexibleSpace: const GlassBarBackground(),
        ),
        body: ListView(
          children: [
            DiaryTableCalendar(
              onDateSelected: (_, _) {},
              calendarDurationDays: const Duration(days: 60),
              focusedDate: today,
              currentDate: today,
              selectedDate: today,
              trackedDaysMap: const {},
            ),
          ],
        ),
      ),
    );

    await shoot(
      'body',
      WeightHistoryScreen(
        getUsecase: _ShotWeightLog(),
        addUsecase: _ShotAddWeight(),
        deleteUsecase: _ShotDeleteWeight(),
        configRepository: _ShotConfig(),
      ),
    );

    final getIt = GetIt.instance;
    getIt.registerSingleton<SettingsBloc>(_ShotSettingsBloc());
    getIt.registerSingleton<ProfileBloc>(_ShotProfileBloc());
    getIt.registerSingleton<HomeBloc>(_ShotHomeBloc());
    getIt.registerSingleton<DiaryBloc>(_ShotDiaryBloc());
    getIt.registerSingleton<CalendarDayBloc>(_ShotCalendarBloc());
    getIt.registerSingleton<TrendsBloc>(_ShotTrendsBloc());
    final credentials = AiCredentialStorage(_ShotStorage());
    getIt.registerSingleton<AiCredentialStorage>(credentials);
    getIt.registerSingleton<AiEndpointProbeRunner>(
      AiEndpointProbeRunner(credentials, _ShotProber()),
    );
    addTearDown(locator.reset);
    await shoot('settings', const SettingsScreen());

    expect(File('${dir.path}/home.png').existsSync(), isTrue);
  });
}

class _ShotWeightLog extends Fake implements GetWeightLogUsecase {
  @override
  Future<List<WeightLogEntity>> getAllEntries() async => [
    WeightLogEntity(date: DateTime(2026, 10, 1), weightKg: 64.2),
    WeightLogEntity(date: DateTime(2026, 10, 18), weightKg: 63.1),
    WeightLogEntity(date: DateTime(2026, 11, 3), weightKg: 62.4),
  ];
}

class _ShotAddWeight extends Fake implements AddWeightLogUsecase {
  @override
  Future<void> addEntry(WeightLogEntity entry) async {}
}

class _ShotDeleteWeight extends Fake implements DeleteWeightLogUsecase {
  @override
  Future<void> deleteEntry(WeightLogEntity entry) async {}
}

class _ShotConfig extends Fake implements ConfigRepository {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(false, false, false, AppThemeEntity.system);
}

class _ShotSettingsBloc extends Fake implements SettingsBloc {
  @override
  SettingsState get state =>
      const SettingsLoadedState('1.0.0', false, AppThemeEntity.system, false);

  @override
  Stream<SettingsState> get stream => const Stream<SettingsState>.empty();

  @override
  void add(SettingsEvent event) {}
}

class _ShotProfileBloc extends Fake implements ProfileBloc {}

class _ShotHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _ShotDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _ShotCalendarBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

class _ShotTrendsBloc extends Fake implements TrendsBloc {
  @override
  void add(TrendsEvent event) {}
}

class _ShotStorage implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ShotProber extends Fake implements AiEndpointProber {}

/// Same chrome as the home tab bar, without the blocs that bar needs.
/// Blur is off in this test; the device build blurs.
class _PreviewGlassBar extends StatelessWidget {
  final List<String> labels;

  const _PreviewGlassBar({required this.labels});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final muted = AppPalette.light.textMuted;
    const icons = [
      Icons.home_outlined,
      Icons.book_outlined,
      Icons.insights_outlined,
      Icons.account_circle_outlined,
    ];
    Widget item(int index) {
      final selected = index == 0;
      final color = selected ? accent : muted;
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icons[index], size: 24, color: color),
            Text(
              labels[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 96,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
              child: GlassSurface(
                borderRadius: 32,
                child: SizedBox(
                  height: 58,
                  child: Row(
                    children: [
                      item(0),
                      item(1),
                      const SizedBox(width: 64),
                      item(2),
                      item(3),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: FloatingActionButton(
                onPressed: () {},
                elevation: 0,
                backgroundColor: accent,
                child: const Icon(Icons.add, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _loadFont(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}
