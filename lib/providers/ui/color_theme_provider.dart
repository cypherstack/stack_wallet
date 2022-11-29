import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';

final colorThemeProvider = StateProvider<StackColors>(
    (ref) => StackColors.fromStackColorTheme(LightColors()));
