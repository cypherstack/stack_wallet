// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SparkNamesTable extends SparkNames
    with TableInfo<$SparkNamesTable, SparkName> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SparkNamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'UNIQUE NOT NULL COLLATE NOCASE',
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validUntilMeta = const VerificationMeta(
    'validUntil',
  );
  @override
  late final GeneratedColumn<int> validUntil = GeneratedColumn<int>(
    'valid_until',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _additionalInfoMeta = const VerificationMeta(
    'additionalInfo',
  );
  @override
  late final GeneratedColumn<String> additionalInfo = GeneratedColumn<String>(
    'additional_info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    name,
    address,
    validUntil,
    additionalInfo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spark_names';
  @override
  VerificationContext validateIntegrity(
    Insertable<SparkName> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('valid_until')) {
      context.handle(
        _validUntilMeta,
        validUntil.isAcceptableOrUnknown(data['valid_until']!, _validUntilMeta),
      );
    } else if (isInserting) {
      context.missing(_validUntilMeta);
    }
    if (data.containsKey('additional_info')) {
      context.handle(
        _additionalInfoMeta,
        additionalInfo.isAcceptableOrUnknown(
          data['additional_info']!,
          _additionalInfoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  SparkName map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SparkName(
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      address:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}address'],
          )!,
      validUntil:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}valid_until'],
          )!,
      additionalInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}additional_info'],
      ),
    );
  }

  @override
  $SparkNamesTable createAlias(String alias) {
    return $SparkNamesTable(attachedDatabase, alias);
  }
}

class SparkName extends DataClass implements Insertable<SparkName> {
  final String name;
  final String address;
  final int validUntil;
  final String? additionalInfo;
  const SparkName({
    required this.name,
    required this.address,
    required this.validUntil,
    this.additionalInfo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['valid_until'] = Variable<int>(validUntil);
    if (!nullToAbsent || additionalInfo != null) {
      map['additional_info'] = Variable<String>(additionalInfo);
    }
    return map;
  }

  SparkNamesCompanion toCompanion(bool nullToAbsent) {
    return SparkNamesCompanion(
      name: Value(name),
      address: Value(address),
      validUntil: Value(validUntil),
      additionalInfo:
          additionalInfo == null && nullToAbsent
              ? const Value.absent()
              : Value(additionalInfo),
    );
  }

  factory SparkName.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SparkName(
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      validUntil: serializer.fromJson<int>(json['validUntil']),
      additionalInfo: serializer.fromJson<String?>(json['additionalInfo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'validUntil': serializer.toJson<int>(validUntil),
      'additionalInfo': serializer.toJson<String?>(additionalInfo),
    };
  }

  SparkName copyWith({
    String? name,
    String? address,
    int? validUntil,
    Value<String?> additionalInfo = const Value.absent(),
  }) => SparkName(
    name: name ?? this.name,
    address: address ?? this.address,
    validUntil: validUntil ?? this.validUntil,
    additionalInfo:
        additionalInfo.present ? additionalInfo.value : this.additionalInfo,
  );
  SparkName copyWithCompanion(SparkNamesCompanion data) {
    return SparkName(
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      validUntil:
          data.validUntil.present ? data.validUntil.value : this.validUntil,
      additionalInfo:
          data.additionalInfo.present
              ? data.additionalInfo.value
              : this.additionalInfo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SparkName(')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('validUntil: $validUntil, ')
          ..write('additionalInfo: $additionalInfo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, address, validUntil, additionalInfo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SparkName &&
          other.name == this.name &&
          other.address == this.address &&
          other.validUntil == this.validUntil &&
          other.additionalInfo == this.additionalInfo);
}

class SparkNamesCompanion extends UpdateCompanion<SparkName> {
  final Value<String> name;
  final Value<String> address;
  final Value<int> validUntil;
  final Value<String?> additionalInfo;
  final Value<int> rowid;
  const SparkNamesCompanion({
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.additionalInfo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SparkNamesCompanion.insert({
    required String name,
    required String address,
    required int validUntil,
    this.additionalInfo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       address = Value(address),
       validUntil = Value(validUntil);
  static Insertable<SparkName> custom({
    Expression<String>? name,
    Expression<String>? address,
    Expression<int>? validUntil,
    Expression<String>? additionalInfo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (validUntil != null) 'valid_until': validUntil,
      if (additionalInfo != null) 'additional_info': additionalInfo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SparkNamesCompanion copyWith({
    Value<String>? name,
    Value<String>? address,
    Value<int>? validUntil,
    Value<String?>? additionalInfo,
    Value<int>? rowid,
  }) {
    return SparkNamesCompanion(
      name: name ?? this.name,
      address: address ?? this.address,
      validUntil: validUntil ?? this.validUntil,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<int>(validUntil.value);
    }
    if (additionalInfo.present) {
      map['additional_info'] = Variable<String>(additionalInfo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SparkNamesCompanion(')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('validUntil: $validUntil, ')
          ..write('additionalInfo: $additionalInfo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MwebUtxosTable extends MwebUtxos
    with TableInfo<$MwebUtxosTable, MwebUtxo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MwebUtxosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _outputIdMeta = const VerificationMeta(
    'outputId',
  );
  @override
  late final GeneratedColumn<String> outputId = GeneratedColumn<String>(
    'output_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockTimeMeta = const VerificationMeta(
    'blockTime',
  );
  @override
  late final GeneratedColumn<int> blockTime = GeneratedColumn<int>(
    'block_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockedMeta = const VerificationMeta(
    'blocked',
  );
  @override
  late final GeneratedColumn<bool> blocked = GeneratedColumn<bool>(
    'blocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("blocked" IN (0, 1))',
    ),
  );
  static const VerificationMeta _usedMeta = const VerificationMeta('used');
  @override
  late final GeneratedColumn<bool> used = GeneratedColumn<bool>(
    'used',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("used" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    outputId,
    address,
    value,
    height,
    blockTime,
    blocked,
    used,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mweb_utxos';
  @override
  VerificationContext validateIntegrity(
    Insertable<MwebUtxo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('output_id')) {
      context.handle(
        _outputIdMeta,
        outputId.isAcceptableOrUnknown(data['output_id']!, _outputIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outputIdMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('block_time')) {
      context.handle(
        _blockTimeMeta,
        blockTime.isAcceptableOrUnknown(data['block_time']!, _blockTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_blockTimeMeta);
    }
    if (data.containsKey('blocked')) {
      context.handle(
        _blockedMeta,
        blocked.isAcceptableOrUnknown(data['blocked']!, _blockedMeta),
      );
    } else if (isInserting) {
      context.missing(_blockedMeta);
    }
    if (data.containsKey('used')) {
      context.handle(
        _usedMeta,
        used.isAcceptableOrUnknown(data['used']!, _usedMeta),
      );
    } else if (isInserting) {
      context.missing(_usedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {outputId};
  @override
  MwebUtxo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MwebUtxo(
      outputId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}output_id'],
          )!,
      address:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}address'],
          )!,
      value:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}value'],
          )!,
      height:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}height'],
          )!,
      blockTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}block_time'],
          )!,
      blocked:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}blocked'],
          )!,
      used:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}used'],
          )!,
    );
  }

  @override
  $MwebUtxosTable createAlias(String alias) {
    return $MwebUtxosTable(attachedDatabase, alias);
  }
}

class MwebUtxo extends DataClass implements Insertable<MwebUtxo> {
  final String outputId;
  final String address;
  final int value;
  final int height;
  final int blockTime;
  final bool blocked;
  final bool used;
  const MwebUtxo({
    required this.outputId,
    required this.address,
    required this.value,
    required this.height,
    required this.blockTime,
    required this.blocked,
    required this.used,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['output_id'] = Variable<String>(outputId);
    map['address'] = Variable<String>(address);
    map['value'] = Variable<int>(value);
    map['height'] = Variable<int>(height);
    map['block_time'] = Variable<int>(blockTime);
    map['blocked'] = Variable<bool>(blocked);
    map['used'] = Variable<bool>(used);
    return map;
  }

  MwebUtxosCompanion toCompanion(bool nullToAbsent) {
    return MwebUtxosCompanion(
      outputId: Value(outputId),
      address: Value(address),
      value: Value(value),
      height: Value(height),
      blockTime: Value(blockTime),
      blocked: Value(blocked),
      used: Value(used),
    );
  }

  factory MwebUtxo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MwebUtxo(
      outputId: serializer.fromJson<String>(json['outputId']),
      address: serializer.fromJson<String>(json['address']),
      value: serializer.fromJson<int>(json['value']),
      height: serializer.fromJson<int>(json['height']),
      blockTime: serializer.fromJson<int>(json['blockTime']),
      blocked: serializer.fromJson<bool>(json['blocked']),
      used: serializer.fromJson<bool>(json['used']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'outputId': serializer.toJson<String>(outputId),
      'address': serializer.toJson<String>(address),
      'value': serializer.toJson<int>(value),
      'height': serializer.toJson<int>(height),
      'blockTime': serializer.toJson<int>(blockTime),
      'blocked': serializer.toJson<bool>(blocked),
      'used': serializer.toJson<bool>(used),
    };
  }

  MwebUtxo copyWith({
    String? outputId,
    String? address,
    int? value,
    int? height,
    int? blockTime,
    bool? blocked,
    bool? used,
  }) => MwebUtxo(
    outputId: outputId ?? this.outputId,
    address: address ?? this.address,
    value: value ?? this.value,
    height: height ?? this.height,
    blockTime: blockTime ?? this.blockTime,
    blocked: blocked ?? this.blocked,
    used: used ?? this.used,
  );
  MwebUtxo copyWithCompanion(MwebUtxosCompanion data) {
    return MwebUtxo(
      outputId: data.outputId.present ? data.outputId.value : this.outputId,
      address: data.address.present ? data.address.value : this.address,
      value: data.value.present ? data.value.value : this.value,
      height: data.height.present ? data.height.value : this.height,
      blockTime: data.blockTime.present ? data.blockTime.value : this.blockTime,
      blocked: data.blocked.present ? data.blocked.value : this.blocked,
      used: data.used.present ? data.used.value : this.used,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MwebUtxo(')
          ..write('outputId: $outputId, ')
          ..write('address: $address, ')
          ..write('value: $value, ')
          ..write('height: $height, ')
          ..write('blockTime: $blockTime, ')
          ..write('blocked: $blocked, ')
          ..write('used: $used')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(outputId, address, value, height, blockTime, blocked, used);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MwebUtxo &&
          other.outputId == this.outputId &&
          other.address == this.address &&
          other.value == this.value &&
          other.height == this.height &&
          other.blockTime == this.blockTime &&
          other.blocked == this.blocked &&
          other.used == this.used);
}

class MwebUtxosCompanion extends UpdateCompanion<MwebUtxo> {
  final Value<String> outputId;
  final Value<String> address;
  final Value<int> value;
  final Value<int> height;
  final Value<int> blockTime;
  final Value<bool> blocked;
  final Value<bool> used;
  final Value<int> rowid;
  const MwebUtxosCompanion({
    this.outputId = const Value.absent(),
    this.address = const Value.absent(),
    this.value = const Value.absent(),
    this.height = const Value.absent(),
    this.blockTime = const Value.absent(),
    this.blocked = const Value.absent(),
    this.used = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MwebUtxosCompanion.insert({
    required String outputId,
    required String address,
    required int value,
    required int height,
    required int blockTime,
    required bool blocked,
    required bool used,
    this.rowid = const Value.absent(),
  }) : outputId = Value(outputId),
       address = Value(address),
       value = Value(value),
       height = Value(height),
       blockTime = Value(blockTime),
       blocked = Value(blocked),
       used = Value(used);
  static Insertable<MwebUtxo> custom({
    Expression<String>? outputId,
    Expression<String>? address,
    Expression<int>? value,
    Expression<int>? height,
    Expression<int>? blockTime,
    Expression<bool>? blocked,
    Expression<bool>? used,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (outputId != null) 'output_id': outputId,
      if (address != null) 'address': address,
      if (value != null) 'value': value,
      if (height != null) 'height': height,
      if (blockTime != null) 'block_time': blockTime,
      if (blocked != null) 'blocked': blocked,
      if (used != null) 'used': used,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MwebUtxosCompanion copyWith({
    Value<String>? outputId,
    Value<String>? address,
    Value<int>? value,
    Value<int>? height,
    Value<int>? blockTime,
    Value<bool>? blocked,
    Value<bool>? used,
    Value<int>? rowid,
  }) {
    return MwebUtxosCompanion(
      outputId: outputId ?? this.outputId,
      address: address ?? this.address,
      value: value ?? this.value,
      height: height ?? this.height,
      blockTime: blockTime ?? this.blockTime,
      blocked: blocked ?? this.blocked,
      used: used ?? this.used,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (outputId.present) {
      map['output_id'] = Variable<String>(outputId.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (blockTime.present) {
      map['block_time'] = Variable<int>(blockTime.value);
    }
    if (blocked.present) {
      map['blocked'] = Variable<bool>(blocked.value);
    }
    if (used.present) {
      map['used'] = Variable<bool>(used.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MwebUtxosCompanion(')
          ..write('outputId: $outputId, ')
          ..write('address: $address, ')
          ..write('value: $value, ')
          ..write('height: $height, ')
          ..write('blockTime: $blockTime, ')
          ..write('blocked: $blocked, ')
          ..write('used: $used, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WalletDatabase extends GeneratedDatabase {
  _$WalletDatabase(QueryExecutor e) : super(e);
  $WalletDatabaseManager get managers => $WalletDatabaseManager(this);
  late final $SparkNamesTable sparkNames = $SparkNamesTable(this);
  late final $MwebUtxosTable mwebUtxos = $MwebUtxosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sparkNames, mwebUtxos];
}

typedef $$SparkNamesTableCreateCompanionBuilder =
    SparkNamesCompanion Function({
      required String name,
      required String address,
      required int validUntil,
      Value<String?> additionalInfo,
      Value<int> rowid,
    });
typedef $$SparkNamesTableUpdateCompanionBuilder =
    SparkNamesCompanion Function({
      Value<String> name,
      Value<String> address,
      Value<int> validUntil,
      Value<String?> additionalInfo,
      Value<int> rowid,
    });

class $$SparkNamesTableFilterComposer
    extends Composer<_$WalletDatabase, $SparkNamesTable> {
  $$SparkNamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get additionalInfo => $composableBuilder(
    column: $table.additionalInfo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SparkNamesTableOrderingComposer
    extends Composer<_$WalletDatabase, $SparkNamesTable> {
  $$SparkNamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get additionalInfo => $composableBuilder(
    column: $table.additionalInfo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SparkNamesTableAnnotationComposer
    extends Composer<_$WalletDatabase, $SparkNamesTable> {
  $$SparkNamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get additionalInfo => $composableBuilder(
    column: $table.additionalInfo,
    builder: (column) => column,
  );
}

class $$SparkNamesTableTableManager
    extends
        RootTableManager<
          _$WalletDatabase,
          $SparkNamesTable,
          SparkName,
          $$SparkNamesTableFilterComposer,
          $$SparkNamesTableOrderingComposer,
          $$SparkNamesTableAnnotationComposer,
          $$SparkNamesTableCreateCompanionBuilder,
          $$SparkNamesTableUpdateCompanionBuilder,
          (
            SparkName,
            BaseReferences<_$WalletDatabase, $SparkNamesTable, SparkName>,
          ),
          SparkName,
          PrefetchHooks Function()
        > {
  $$SparkNamesTableTableManager(_$WalletDatabase db, $SparkNamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SparkNamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SparkNamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SparkNamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> validUntil = const Value.absent(),
                Value<String?> additionalInfo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SparkNamesCompanion(
                name: name,
                address: address,
                validUntil: validUntil,
                additionalInfo: additionalInfo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String address,
                required int validUntil,
                Value<String?> additionalInfo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SparkNamesCompanion.insert(
                name: name,
                address: address,
                validUntil: validUntil,
                additionalInfo: additionalInfo,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SparkNamesTableProcessedTableManager =
    ProcessedTableManager<
      _$WalletDatabase,
      $SparkNamesTable,
      SparkName,
      $$SparkNamesTableFilterComposer,
      $$SparkNamesTableOrderingComposer,
      $$SparkNamesTableAnnotationComposer,
      $$SparkNamesTableCreateCompanionBuilder,
      $$SparkNamesTableUpdateCompanionBuilder,
      (
        SparkName,
        BaseReferences<_$WalletDatabase, $SparkNamesTable, SparkName>,
      ),
      SparkName,
      PrefetchHooks Function()
    >;
typedef $$MwebUtxosTableCreateCompanionBuilder =
    MwebUtxosCompanion Function({
      required String outputId,
      required String address,
      required int value,
      required int height,
      required int blockTime,
      required bool blocked,
      required bool used,
      Value<int> rowid,
    });
typedef $$MwebUtxosTableUpdateCompanionBuilder =
    MwebUtxosCompanion Function({
      Value<String> outputId,
      Value<String> address,
      Value<int> value,
      Value<int> height,
      Value<int> blockTime,
      Value<bool> blocked,
      Value<bool> used,
      Value<int> rowid,
    });

class $$MwebUtxosTableFilterComposer
    extends Composer<_$WalletDatabase, $MwebUtxosTable> {
  $$MwebUtxosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get outputId => $composableBuilder(
    column: $table.outputId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockTime => $composableBuilder(
    column: $table.blockTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blocked => $composableBuilder(
    column: $table.blocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MwebUtxosTableOrderingComposer
    extends Composer<_$WalletDatabase, $MwebUtxosTable> {
  $$MwebUtxosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get outputId => $composableBuilder(
    column: $table.outputId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockTime => $composableBuilder(
    column: $table.blockTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blocked => $composableBuilder(
    column: $table.blocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MwebUtxosTableAnnotationComposer
    extends Composer<_$WalletDatabase, $MwebUtxosTable> {
  $$MwebUtxosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get outputId =>
      $composableBuilder(column: $table.outputId, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get blockTime =>
      $composableBuilder(column: $table.blockTime, builder: (column) => column);

  GeneratedColumn<bool> get blocked =>
      $composableBuilder(column: $table.blocked, builder: (column) => column);

  GeneratedColumn<bool> get used =>
      $composableBuilder(column: $table.used, builder: (column) => column);
}

class $$MwebUtxosTableTableManager
    extends
        RootTableManager<
          _$WalletDatabase,
          $MwebUtxosTable,
          MwebUtxo,
          $$MwebUtxosTableFilterComposer,
          $$MwebUtxosTableOrderingComposer,
          $$MwebUtxosTableAnnotationComposer,
          $$MwebUtxosTableCreateCompanionBuilder,
          $$MwebUtxosTableUpdateCompanionBuilder,
          (
            MwebUtxo,
            BaseReferences<_$WalletDatabase, $MwebUtxosTable, MwebUtxo>,
          ),
          MwebUtxo,
          PrefetchHooks Function()
        > {
  $$MwebUtxosTableTableManager(_$WalletDatabase db, $MwebUtxosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MwebUtxosTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$MwebUtxosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$MwebUtxosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> outputId = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> blockTime = const Value.absent(),
                Value<bool> blocked = const Value.absent(),
                Value<bool> used = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MwebUtxosCompanion(
                outputId: outputId,
                address: address,
                value: value,
                height: height,
                blockTime: blockTime,
                blocked: blocked,
                used: used,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String outputId,
                required String address,
                required int value,
                required int height,
                required int blockTime,
                required bool blocked,
                required bool used,
                Value<int> rowid = const Value.absent(),
              }) => MwebUtxosCompanion.insert(
                outputId: outputId,
                address: address,
                value: value,
                height: height,
                blockTime: blockTime,
                blocked: blocked,
                used: used,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MwebUtxosTableProcessedTableManager =
    ProcessedTableManager<
      _$WalletDatabase,
      $MwebUtxosTable,
      MwebUtxo,
      $$MwebUtxosTableFilterComposer,
      $$MwebUtxosTableOrderingComposer,
      $$MwebUtxosTableAnnotationComposer,
      $$MwebUtxosTableCreateCompanionBuilder,
      $$MwebUtxosTableUpdateCompanionBuilder,
      (MwebUtxo, BaseReferences<_$WalletDatabase, $MwebUtxosTable, MwebUtxo>),
      MwebUtxo,
      PrefetchHooks Function()
    >;

class $WalletDatabaseManager {
  final _$WalletDatabase _db;
  $WalletDatabaseManager(this._db);
  $$SparkNamesTableTableManager get sparkNames =>
      $$SparkNamesTableTableManager(_db, _db.sparkNames);
  $$MwebUtxosTableTableManager get mwebUtxos =>
      $$MwebUtxosTableTableManager(_db, _db.mwebUtxos);
}
