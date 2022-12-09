import 'package:epicpay/utilities/theme/dark_colors.dart';
import 'package:epicpay/utilities/theme/stack_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final colorThemeProvider = StateProvider<StackColors>(
    (ref) => StackColors.fromStackColorTheme(DarkColors()));
