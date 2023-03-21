import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/utilities/paynym_is_api.dart';

final paynymAPIProvider = Provider<PaynymIsApi>((_) => PaynymIsApi());
