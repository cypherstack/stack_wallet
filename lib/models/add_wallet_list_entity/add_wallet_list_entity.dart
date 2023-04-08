import 'package:equatable/equatable.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

abstract class AddWalletListEntity extends Equatable {
  Coin get coin;
  String get name;
  String get ticker;
}
