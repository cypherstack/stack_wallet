import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/services/trade_notes_service.dart';

final tradeNoteServiceProvider =
    ChangeNotifierProvider<TradeNotesService>((ref) => TradeNotesService());
