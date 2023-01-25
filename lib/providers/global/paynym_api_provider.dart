import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/paynym_is_api.dart';

final paynymAPIProvider = Provider<PaynymIsApi>((_) => PaynymIsApi());
