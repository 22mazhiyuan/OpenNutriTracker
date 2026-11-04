import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/glass_surface.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';

class MainAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData iconData;

  const MainAppbar({super.key, required this.title, required this.iconData});

  @override
  Widget build(BuildContext context) {
    final glass = AppPalette.glassActive;
    return AppBar(
      backgroundColor: glass ? Colors.transparent : null,
      flexibleSpace: glass ? const GlassBarBackground() : null,
      leading: Icon(iconData),
      title: Text(title),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
