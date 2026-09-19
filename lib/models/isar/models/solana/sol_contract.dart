/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:isar_community/isar.dart';

import '../contract.dart';

part 'sol_contract.g.dart';

@collection
class SolContract extends Contract {
  SolContract({
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    this.logoUri,
    this.metadataAddress,
  });

  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true, replace: true)
  late final String address; // Mint address.

  @override
  late final String name;

  @override
  late final String symbol;

  @override
  late final int decimals;

  late final String? logoUri;

  late final String? metadataAddress;

  SolContract copyWith({
    Id? id,
    String? address,
    String? name,
    String? symbol,
    int? decimals,
    String? logoUri,
    String? metadataAddress,
  }) => SolContract(
    address: address ?? this.address,
    name: name ?? this.name,
    symbol: symbol ?? this.symbol,
    decimals: decimals ?? this.decimals,
    logoUri: logoUri ?? this.logoUri,
    metadataAddress: metadataAddress ?? this.metadataAddress,
  )..id = id ?? this.id;
}
