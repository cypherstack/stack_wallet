import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/utilities/paynym_api.dart';

final paynymAPIProvider = Provider<PaynymAPI>((_) => PaynymAPI());
