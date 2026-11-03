import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_look.dart';
import 'package:opennutritracker/core/presentation/widgets/glass_backdrop.dart';
import 'package:opennutritracker/core/presentation/widgets/glass_surface.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/app_theme.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Renders the glass look in Simplified Chinese.
///
/// The widget-test renderer deadlocks on a live backdrop blur, so these
/// frames use the same frosted material without the GPU blur. The running
/// app still blurs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('glass screens render in Simplified Chinese', (tester) async {
    AppPalette.activeLook = AppLook.glass;
    final preferred = Directory('/opt/cursor/artifacts/screenshots');
    final dir = preferred.parent.existsSync()
        ? (preferred..createSync(recursive: true))
        : Directory.systemTemp.createTempSync('glass-shots');
    await tester.runAsync(() async {
      await _loadFont(
        'PreviewLatin',
        '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
      );
      await _loadFont(
        'PreviewCjk',
        '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf',
      );
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final s = lookupS(const Locale('zh'));

    Future<void> shoot(String name, Widget body) async {
      final base = buildAppTheme(AppPalette.light, glass: true);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          theme: base.copyWith(
            textTheme: base.textTheme.apply(
              fontFamily: 'PreviewLatin',
              fontFamilyFallback: const ['PreviewCjk'],
            ),
            primaryTextTheme: base.primaryTextTheme.apply(
              fontFamily: 'PreviewLatin',
              fontFamilyFallback: const ['PreviewCjk'],
            ),
            appBarTheme: base.appBarTheme.copyWith(
              titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
                fontFamily: 'PreviewLatin',
                fontFamilyFallback: const ['PreviewCjk'],
              ),
            ),
          ),
          builder: (context, child) => RepaintBoundary(
            key: const Key('shot'),
            child: GlassBackdrop(
              enabled: true,
              dark: false,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          home: body,
        ),
      );
      await tester.pump();
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

    Widget bar() => const SafeArea(top: false, child: _TabBar());

    await shoot(
      'home',
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.homeLabel)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            GlassSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    s.kcalLeftLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4E675E),
                    ),
                  ),
                  const Text(
                    '640',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0C8F6A),
                    ),
                  ),
                  const Text('千卡'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.waterHomeTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(s.waterChipLabel(800, 2000)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: const LinearProgressIndicator(
                      value: 0.4,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final amount in [200, 300, 500])
                        OutlinedButton(
                          onPressed: () {},
                          child: Text(s.waterQuickAdd(amount)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_walk_outlined,
                    color: Color(0xFF0C8F6A),
                  ),
                  const SizedBox(width: 8),
                  Text(s.stepsHomeLabel),
                  const Spacer(),
                  const Text(
                    '8432',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: bar(),
      ),
    );

    await shoot(
      'diary',
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.diaryLabel)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final meal in [s.breakfastLabel, s.lunchLabel, s.dinnerLabel])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassSurface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('鸡胸沙拉    410 千卡'),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: bar(),
      ),
    );

    await shoot(
      'body',
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.profileWeightHistoryTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(s.bodyMetricWeight),
                  selected: false,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  label: Text(s.bodyMetricBodyFat),
                  selected: false,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  label: Text(s.bodyMetricWaist),
                  selected: true,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  label: Text(s.bodyMetricHip),
                  selected: false,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  label: Text(s.bodyMetricChest),
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            const GlassSurface(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: SizedBox(height: 180, child: _TrendLine()),
            ),
            const SizedBox(height: 8),
            const GlassSurface(
              child: ListTile(title: Text('77.5 厘米'), subtitle: Text('今天')),
            ),
          ],
        ),
      ),
    );

    await shoot(
      'settings',
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.settingsLabel)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassSurface(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.blur_on_outlined),
                    title: Text(s.appLookLabel),
                    subtitle: Text(s.appLookGlassLabel),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.brightness_medium_outlined),
                    title: Text(s.settingsThemeLabel),
                    subtitle: Text(s.settingsThemeSystemDefaultLabel),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.translate_outlined),
                    title: Text(s.appTitle),
                    subtitle: const Text('简体中文'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(File('${dir.path}/home.png').existsSync(), isTrue);
    expect(find.text('简体中文'), findsOneWidget);
  });
}

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassSurface(
        borderRadius: 32,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _item(Icons.home_outlined, s.homeLabel, true),
              _item(Icons.book_outlined, s.diaryLabel, false),
              _item(Icons.insights_outlined, s.trendsLabel, false),
              _item(Icons.account_circle_outlined, s.youLabel, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, bool selected) {
    final color = selected ? const Color(0xFF0C8F6A) : const Color(0xFF4E675E);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

class _TrendLine extends StatelessWidget {
  const _TrendLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LinePainter(), child: const SizedBox.expand());
  }
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0C8F6A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.75)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.7,
        size.width * 0.45,
        size.height * 0.45,
        size.width * 0.7,
        size.height * 0.4,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.36,
        size.width * 0.9,
        size.height * 0.28,
        size.width * 0.95,
        size.height * 0.22,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _loadFont(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}
