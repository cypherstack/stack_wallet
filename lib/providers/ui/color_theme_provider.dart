import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

final colorThemeProvider = StateProvider<StackColors>(
    (ref) => StackColors.fromStackColorTheme(LightColors()));
