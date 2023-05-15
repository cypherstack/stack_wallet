import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';

final applicationThemesDirectoryPathProvider = StateProvider((ref) => "");

final colorProvider = StateProvider<StackColors>(
  (ref) => StackColors.fromStackColorTheme(
    ref.watch(themeProvider.state).state,
  ),
);

final themeProvider = StateProvider<StackTheme>(
  (ref) => ref.watch(
    pThemeService.select(
      (value) => value.getTheme(
        themeId: "light",
      )!,
    ),
  ),
);
