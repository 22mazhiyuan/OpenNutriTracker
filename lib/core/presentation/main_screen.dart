import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:opennutritracker/core/presentation/widgets/glass_surface.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/presentation/widgets/demo_mode_banner.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/utils/health_rationale_service.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/meal_type_suggester.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';
import 'package:opennutritracker/features/home/home_page.dart';
import 'package:opennutritracker/features/home/presentation/screens/coming_soon_page.dart';
import 'package:opennutritracker/features/home/presentation/screens/weight_center_page.dart';
import 'package:opennutritracker/core/presentation/widgets/main_appbar.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedPageIndex = 0;
  bool _isDemoData = false;

  /// Guards against two lifecycle events asking the platform at once. The
  /// platform side clears the flag on read, so a race would not open the
  /// screen twice — but it would spend two channel round trips finding out.
  bool _checkingHealthRationale = false;

  late List<Widget> _bodyPages;
  late List<PreferredSizeWidget> _appbarPages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConfigDrivenUi();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // The activity is singleTop, so Health Connect reaching a process that is
    // already running never rebuilds this screen — a resume is the only signal
    // that an intent arrived.
    if (state == AppLifecycleState.resumed) {
      _maybeOpenHealthRationale();
    }
  }

  // Checked once per screen instance rather than kept live — leaving demo mode
  // always replaces this whole screen with the onboarding route (see
  // DemoModeBanner), so there is no in-place transition to react to.
  //
  // The policy-change notice #887 specified is deliberately **not** shown for
  // revision 1. #887's reasoning stands on the record and was not refuted —
  // the corrections name recipients that were always receiving data, so users
  // were under-informed for the whole time rather than recently — but the call
  // was made not to spend a first-launch dialog on it. The mechanism itself is
  // kept, not deleted: `URLConst.policyRevision`, the seeding in
  // `OnboardingBloc.saveOnboardingData` and `PolicyChangeDialog` are all still
  // live and tested, so a future revision that does warrant telling people can
  // restore this by calling the dialog again. What is gone is one call, not
  // the ability to notify.
  Future<void> _loadConfigDrivenUi() async {
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!mounted) return;
    setState(() => _isDemoData = config.isDemoData);
    await _maybeOpenHealthRationale();
  }

  /// Opens the health-sync screen when Health Connect asked the app to explain
  /// what it wants health data for (#927).
  ///
  /// Health Connect starts the app rather than rendering anything itself, so
  /// without this the user is dropped on the diary having asked a question
  /// nothing answered. The screen names the data, says what it is used for,
  /// and links the privacy policy.
  Future<void> _maybeOpenHealthRationale() async {
    if (_checkingHealthRationale) return;
    _checkingHealthRationale = true;
    final bool requested;
    try {
      requested = await HealthRationaleService.consumePendingRequest();
    } finally {
      _checkingHealthRationale = false;
    }
    if (!requested || !mounted) return;
    await Navigator.of(context).pushNamed(NavigationOptions.healthSyncRoute);
  }

  @override
  void didChangeDependencies() {
    _bodyPages = [
      const HomePage(),
      const ComingSoonPage(semanticsId: 'plaza-coming-soon'),
      const WeightCenterPage(),
      const ComingSoonPage(semanticsId: 'shop-coming-soon'),
      const ProfilePage(),
    ];
    _appbarPages = [
      const HomeAppbar(),
      MainAppbar(
        title: S.of(context).tabPlazaLabel,
        iconData: Icons.forum_outlined,
      ),
      MainAppbar(
        title: S.of(context).tabWeightCenterLabel,
        iconData: Icons.monitor_weight_outlined,
      ),
      MainAppbar(
        title: S.of(context).tabShopLabel,
        iconData: Icons.storefront_outlined,
      ),
      MainAppbar(
        title: S.of(context).youLabel,
        iconData: Icons.account_circle_outlined,
      ),
    ];
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final glass = AppPalette.glassActive;
    final nav = <Widget>[
      _NavItem(
        id: 'nav-home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: S.of(context).tabHomeLabel,
        index: 0,
        selectedIndex: _selectedPageIndex,
        palette: palette,
        onTap: _setPage,
      ),
      _NavItem(
        id: 'nav-plaza',
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum_rounded,
        label: S.of(context).tabPlazaLabel,
        index: 1,
        selectedIndex: _selectedPageIndex,
        palette: palette,
        onTap: _setPage,
      ),
      _NavItem(
        id: 'nav-weight-center',
        icon: Icons.monitor_weight_outlined,
        selectedIcon: Icons.monitor_weight_rounded,
        label: S.of(context).tabWeightCenterLabel,
        index: 2,
        selectedIndex: _selectedPageIndex,
        palette: palette,
        onTap: _setPage,
      ),
      _NavItem(
        id: 'nav-shop',
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront_rounded,
        label: S.of(context).tabShopLabel,
        index: 3,
        selectedIndex: _selectedPageIndex,
        palette: palette,
        onTap: _setPage,
      ),
      _NavItem(
        id: 'nav-mine',
        icon: Icons.account_circle_outlined,
        selectedIcon: Icons.account_circle_rounded,
        label: S.of(context).youLabel,
        index: 4,
        selectedIndex: _selectedPageIndex,
        palette: palette,
        onTap: _setPage,
      ),
    ];
    return Scaffold(
      extendBody: glass,
      appBar: _appbarPages[_selectedPageIndex],
      body: Column(
        children: [
          if (_isDemoData) const DemoModeBanner(),
          Expanded(
            child: IndexedStack(
              index: _selectedPageIndex,
              children: _bodyPages,
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        identifier: 'fab-add-item',
        child: FloatingActionButton(
          onPressed: () => _onFabPressed(context),
          tooltip: S.of(context).addLabel,
          child: const Icon(Icons.add, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: glass
          ? _GlassTabBar(children: nav)
          : BottomAppBar(
              color: palette.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              height: 72,
              padding: EdgeInsets.zero,
              child: Row(children: nav),
            ),
    );
  }

  void _setPage(int selectedIndex) {
    setState(() {
      _selectedPageIndex = selectedIndex;
    });
  }

  Future<void> _onFabPressed(BuildContext context) async {
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.glassActive ? Colors.transparent : null,
      builder: (BuildContext context) {
        final sheet = AddItemBottomSheet(
          day: DateTime.now(),
          showActivityTracking: config.showActivityTracking,
          usesImperialUnits: config.usesImperialFoodUnits,
          suggestedType: MealTypeSuggester.suggestFromTime(
            DateTime.now(),
            mealSharesPct: config.mealKcalSharesPct,
          ),
        );
        return AppPalette.glassActive ? GlassSheet(child: sheet) : sheet;
      },
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  final List<Widget> children;

  const _GlassTabBar({required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: GlassSurface(
          borderRadius: 28,
          child: SizedBox(height: 62, child: Row(children: children)),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String id;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final AppPalette palette;
  final void Function(int) onTap;

  const _NavItem({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : palette.textMuted;
    return Expanded(
      child: Semantics(
        identifier: id,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1,
                  duration: AppMotion.durationShort,
                  curve: AppMotion.emphasized,
                  child: Icon(
                    (selected && !AppPalette.glassActive) ? selectedIcon : icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
