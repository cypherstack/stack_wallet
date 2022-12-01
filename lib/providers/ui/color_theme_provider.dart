import 'package:epicmobile/utilities/theme/dark_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final colorThemeProvider = StateProvider<StackColors>(
    (ref) => StackColors.fromStackColorTheme(DarkColors()));
