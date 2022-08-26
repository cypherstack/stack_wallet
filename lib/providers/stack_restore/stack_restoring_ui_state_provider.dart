import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/stack_restoring_ui_state.dart';

final stackRestoringUIStateProvider =
    ChangeNotifierProvider<StackRestoringUIState>(
        (ref) => StackRestoringUIState());
