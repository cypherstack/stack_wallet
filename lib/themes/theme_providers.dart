import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

final applicationThemesDirectoryPathProvider = StateProvider((ref) => "");

final colorProvider = StateProvider<StackColors>(
  (ref) => StackColors.fromStackColorTheme(
    ref.watch(themeProvider.state).state,
  ),
);

final themeProvider = StateProvider<StackTheme>((ref) {
  // Return default if no theme was properly loaded on startup. This should
  // technically never actually be read but we don't want an optional.
  // Ideally Riverpod would would give us some kind of 'late' provider option
  return StackTheme.fromJson(
    json: darkJson,
    // Explicitly use ref.read here as we do not want any rebuild on this
    // value change.
    applicationThemesDirectoryPath:
        ref.read(applicationThemesDirectoryPathProvider),
  );
});

// /// example
// class ExampleWidget extends ConsumerWidget {
//   const ExampleWidget({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Column(
//       children: [
//         const Text("Hello, world!"),
//         SvgPicture.file(
//           File(
//             ref.watch(themeProvider).assets.bellNew,
//           ),
//         ),
//       ],
//     );
//   }
// }
