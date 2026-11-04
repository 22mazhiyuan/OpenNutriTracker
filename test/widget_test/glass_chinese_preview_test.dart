import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/features/home/presentation/screens/coming_soon_page.dart';
import 'package:opennutritracker/features/home/presentation/widgets/home_entry_tile.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/home/presentation/widgets/quick_water_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/steps_home_card.dart';
import 'package:opennutritracker/features/home/presentation/widgets/today_kcal_card.dart';
import 'package:opennutritracker/features/home/presentation/widgets/weight_plan_card.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/features/profile/presentation/weight_history_screen.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/run_ai_endpoint_probe_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
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
          title: Text(s.appTitle),
          backgroundColor: Colors.transparent,
          flexibleSpace: const GlassBarBackground(),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: WeightPlanCard(
                currentKg: 62.4,
                targetKg: 58,
                startKg: 64.2,
                unit: BodyWeightUnit.kg,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: HomeEntryTile(
                          id: 'home-entry-diet',
                          icon: Icons.restaurant_outlined,
                          title: s.dietRecordLabel,
                          subtitle: '780 ${s.kcalLabel}',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HomeEntryTile(
                          id: 'home-entry-exercise',
                          icon: Icons.directions_run_outlined,
                          title: s.exerciseEntryLabel,
                          subtitle: '180 ${s.kcalLabel}',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: HomeEntryTile(
                          id: 'home-entry-weight',
                          icon: Icons.monitor_weight_outlined,
                          title: s.weightLabel,
                          subtitle: '62.4 ${s.kgLabel}',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HomeEntryTile(
                          id: 'home-entry-measurements',
                          icon: Icons.straighten_outlined,
                          title: s.measurementsEntryLabel,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  HomeEntryTile(
                    id: 'home-entry-trends',
                    icon: Icons.insights_outlined,
                    title: s.trendsLabel,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: StepsHomeCard()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HomeEntryTile(
                          id: 'home-entry-fasting',
                          icon: Icons.timer_outlined,
                          title: s.fastingEntryLabel,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const QuickWaterWidget(waterMlToday: 800, waterGoalMl: 2000),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                s.todayDietLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TodayKcalCard(
                totalKcalDaily: 1600,
                totalKcalLeft: 640,
                totalKcalSupplied: 780,
                totalKcalBurned: 180,
              ),
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
          labels: [
            s.tabHomeLabel,
            s.tabPlazaLabel,
            s.tabWeightCenterLabel,
            s.tabShopLabel,
            s.youLabel,
          ],
        ),
      ),
      size: const Size(390, 1480),
    );

    Widget tabScaffold(String title, Widget body, int selected) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          flexibleSpace: const GlassBarBackground(),
        ),
        body: body,
        bottomNavigationBar: _PreviewGlassBar(
          selected: selected,
          labels: [
            s.tabHomeLabel,
            s.tabPlazaLabel,
            s.tabWeightCenterLabel,
            s.tabShopLabel,
            s.youLabel,
          ],
        ),
      );
    }

    await shoot(
      'plaza',
      tabScaffold(
        s.tabPlazaLabel,
        const ComingSoonPage(semanticsId: 'plaza-coming-soon'),
        1,
      ),
    );

    await shoot(
      'center',
      tabScaffold(
        s.tabWeightCenterLabel,
        WeightHistoryScreen(
          embedded: true,
          getUsecase: _ShotWeightLog(),
          addUsecase: _ShotAddWeight(),
          deleteUsecase: _ShotDeleteWeight(),
          configRepository: _ShotConfig(),
          getUserUsecase: _ShotUser(),
        ),
        2,
      ),
    );

    await shoot(
      'shop',
      tabScaffold(
        s.tabShopLabel,
        const ComingSoonPage(semanticsId: 'shop-coming-soon'),
        3,
      ),
    );

    final getIt = GetIt.instance;
    getIt.registerSingleton<SettingsBloc>(_ShotSettingsBloc());
    getIt.registerSingleton<HomeBloc>(_ShotHomeBloc());
    getIt.registerSingleton<DiaryBloc>(_ShotDiaryBloc());
    getIt.registerSingleton<CalendarDayBloc>(_ShotCalendarBloc());
    getIt.registerSingleton<TrendsBloc>(_ShotTrendsBloc());
    final credentials = AiCredentialStorage(_ShotStorage());
    getIt.registerSingleton<AiCredentialStorage>(credentials);
    getIt.registerSingleton<AiEndpointProbeRunner>(
      AiEndpointProbeRunner(credentials, _ShotProber()),
    );
    final user = UserEntity(
      birthday: DateTime(1998, 4, 2),
      heightCM: 165,
      weightKG: 62.4,
      gender: UserGenderEntity.female,
      goal: UserWeightGoalEntity.loseWeight,
      pal: UserPALEntity.sedentary,
      targetWeightKg: 58,
    );
    getIt.registerSingleton<GetUserUsecase>(_ShotUser());
    getIt.registerSingleton<GetProfilesUsecase>(_ShotProfiles());
    getIt.registerSingleton<AddWeightLogUsecase>(_ShotAddWeight());
    final profileBloc = _LoadedProfileBloc(
      ProfileLoadedState(
        userBMI: const UserBMIEntity(
          bmiValue: 22.9,
          nutritionalStatus: UserNutritionalStatus.normalWeight,
        ),
        userEntity: user,
        bodyWeightUnit: BodyWeightUnit.kg,
        usesImperialHeightUnits: false,
        effectiveWaterGoalMl: 2000,
      ),
    );
    getIt.registerSingleton<ProfileBloc>(profileBloc);
    addTearDown(profileBloc.close);
    addTearDown(locator.reset);
    await shoot('mine', tabScaffold(s.youLabel, const ProfilePage(), 4));

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

class _LoadedProfileBloc extends Bloc<ProfileEvent, ProfileState>
    implements ProfileBloc {
  _LoadedProfileBloc(super.initialState) {
    on<LoadProfileEvent>((event, emit) => emit(state));
  }

  @override
  Future<UserEntity> getUser() async =>
      (state as ProfileLoadedState).userEntity;

  @override
  Future<void> setCaloriesTaperEnabled(bool enabled) async {}

  @override
  Future<void> updateUser(UserEntity userEntity) async {}
}

class _ShotUser extends Fake implements GetUserUsecase {
  @override
  Future<UserEntity> getUserData() async => UserEntity(
    birthday: DateTime(1998, 4, 2),
    heightCM: 165,
    weightKG: 62.4,
    gender: UserGenderEntity.female,
    goal: UserWeightGoalEntity.loseWeight,
    pal: UserPALEntity.sedentary,
    targetWeightKg: 58,
  );
}

class _ShotProfiles implements GetProfilesUsecase {
  static final _profile = ProfileEntity(
    id: 'p1',
    name: '我',
    createdAt: DateTime(2026, 1, 1),
    boxSuffix: '',
  );

  @override
  List<ProfileEntity> getProfiles() => [_profile];

  @override
  String get activeProfileId => 'p1';

  @override
  ProfileEntity? getActiveProfile() => _profile;
}

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
  final int selected;

  const _PreviewGlassBar({required this.labels, this.selected = 0});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final muted = AppPalette.light.textMuted;
    const icons = [
      Icons.home_outlined,
      Icons.forum_outlined,
      Icons.monitor_weight_outlined,
      Icons.storefront_outlined,
      Icons.account_circle_outlined,
    ];
    Widget item(int index) {
      final on = index == selected;
      final color = on ? accent : muted;
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: GlassSurface(
          borderRadius: 28,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [for (var i = 0; i < labels.length; i++) item(i)],
            ),
          ),
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
