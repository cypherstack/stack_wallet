import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utilities/clipboard_interface.dart';

final pClipboard = Provider<ClipboardInterface>(
  (ref) => const ClipboardWrapper(),
);
