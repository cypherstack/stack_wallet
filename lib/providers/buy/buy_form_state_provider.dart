import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/buy/buy_form_state.dart';

final buyFormStateProvider = ChangeNotifierProvider<BuyFormState>(
  (ref) => BuyFormState(),
);
