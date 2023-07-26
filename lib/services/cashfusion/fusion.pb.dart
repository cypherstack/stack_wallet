///
//  Generated code. Do not modify.
//  source: fusion.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class InputComponent extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InputComponent', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'prevTxid', $pb.PbFieldType.QY)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'prevIndex', $pb.PbFieldType.QU3)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pubkey', $pb.PbFieldType.QY)
    ..a<$fixnum.Int64>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'amount', $pb.PbFieldType.QU6, defaultOrMaker: $fixnum.Int64.ZERO)
  ;

  InputComponent._() : super();
  factory InputComponent({
    $core.List<$core.int>? prevTxid,
    $core.int? prevIndex,
    $core.List<$core.int>? pubkey,
    $fixnum.Int64? amount,
  }) {
    final _result = create();
    if (prevTxid != null) {
      _result.prevTxid = prevTxid;
    }
    if (prevIndex != null) {
      _result.prevIndex = prevIndex;
    }
    if (pubkey != null) {
      _result.pubkey = pubkey;
    }
    if (amount != null) {
      _result.amount = amount;
    }
    return _result;
  }
  factory InputComponent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InputComponent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InputComponent clone() => InputComponent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InputComponent copyWith(void Function(InputComponent) updates) => super.copyWith((message) => updates(message as InputComponent)) as InputComponent; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InputComponent create() => InputComponent._();
  InputComponent createEmptyInstance() => create();
  static $pb.PbList<InputComponent> createRepeated() => $pb.PbList<InputComponent>();
  @$core.pragma('dart2js:noInline')
  static InputComponent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputComponent>(create);
  static InputComponent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get prevTxid => $_getN(0);
  @$pb.TagNumber(1)
  set prevTxid($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPrevTxid() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrevTxid() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get prevIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set prevIndex($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPrevIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrevIndex() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get pubkey => $_getN(2);
  @$pb.TagNumber(3)
  set pubkey($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPubkey() => $_has(2);
  @$pb.TagNumber(3)
  void clearPubkey() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get amount => $_getI64(3);
  @$pb.TagNumber(4)
  set amount($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAmount() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmount() => clearField(4);
}

class OutputComponent extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'OutputComponent', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scriptpubkey', $pb.PbFieldType.QY)
    ..a<$fixnum.Int64>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'amount', $pb.PbFieldType.QU6, defaultOrMaker: $fixnum.Int64.ZERO)
  ;

  OutputComponent._() : super();
  factory OutputComponent({
    $core.List<$core.int>? scriptpubkey,
    $fixnum.Int64? amount,
  }) {
    final _result = create();
    if (scriptpubkey != null) {
      _result.scriptpubkey = scriptpubkey;
    }
    if (amount != null) {
      _result.amount = amount;
    }
    return _result;
  }
  factory OutputComponent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutputComponent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OutputComponent clone() => OutputComponent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OutputComponent copyWith(void Function(OutputComponent) updates) => super.copyWith((message) => updates(message as OutputComponent)) as OutputComponent; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static OutputComponent create() => OutputComponent._();
  OutputComponent createEmptyInstance() => create();
  static $pb.PbList<OutputComponent> createRepeated() => $pb.PbList<OutputComponent>();
  @$core.pragma('dart2js:noInline')
  static OutputComponent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OutputComponent>(create);
  static OutputComponent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get scriptpubkey => $_getN(0);
  @$pb.TagNumber(1)
  set scriptpubkey($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasScriptpubkey() => $_has(0);
  @$pb.TagNumber(1)
  void clearScriptpubkey() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get amount => $_getI64(1);
  @$pb.TagNumber(2)
  set amount($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAmount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmount() => clearField(2);
}

class BlankComponent extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BlankComponent', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  BlankComponent._() : super();
  factory BlankComponent() => create();
  factory BlankComponent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlankComponent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlankComponent clone() => BlankComponent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlankComponent copyWith(void Function(BlankComponent) updates) => super.copyWith((message) => updates(message as BlankComponent)) as BlankComponent; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BlankComponent create() => BlankComponent._();
  BlankComponent createEmptyInstance() => create();
  static $pb.PbList<BlankComponent> createRepeated() => $pb.PbList<BlankComponent>();
  @$core.pragma('dart2js:noInline')
  static BlankComponent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlankComponent>(create);
  static BlankComponent? _defaultInstance;
}

enum Component_Component {
  input, 
  output, 
  blank, 
  notSet
}

class Component extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, Component_Component> _Component_ComponentByTag = {
    2 : Component_Component.input,
    3 : Component_Component.output,
    4 : Component_Component.blank,
    0 : Component_Component.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Component', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'saltCommitment', $pb.PbFieldType.QY)
    ..aOM<InputComponent>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'input', subBuilder: InputComponent.create)
    ..aOM<OutputComponent>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'output', subBuilder: OutputComponent.create)
    ..aOM<BlankComponent>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blank', subBuilder: BlankComponent.create)
  ;

  Component._() : super();
  factory Component({
    $core.List<$core.int>? saltCommitment,
    InputComponent? input,
    OutputComponent? output,
    BlankComponent? blank,
  }) {
    final _result = create();
    if (saltCommitment != null) {
      _result.saltCommitment = saltCommitment;
    }
    if (input != null) {
      _result.input = input;
    }
    if (output != null) {
      _result.output = output;
    }
    if (blank != null) {
      _result.blank = blank;
    }
    return _result;
  }
  factory Component.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Component.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Component clone() => Component()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Component copyWith(void Function(Component) updates) => super.copyWith((message) => updates(message as Component)) as Component; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Component create() => Component._();
  Component createEmptyInstance() => create();
  static $pb.PbList<Component> createRepeated() => $pb.PbList<Component>();
  @$core.pragma('dart2js:noInline')
  static Component getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Component>(create);
  static Component? _defaultInstance;

  Component_Component whichComponent() => _Component_ComponentByTag[$_whichOneof(0)]!;
  void clearComponent() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.List<$core.int> get saltCommitment => $_getN(0);
  @$pb.TagNumber(1)
  set saltCommitment($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSaltCommitment() => $_has(0);
  @$pb.TagNumber(1)
  void clearSaltCommitment() => clearField(1);

  @$pb.TagNumber(2)
  InputComponent get input => $_getN(1);
  @$pb.TagNumber(2)
  set input(InputComponent v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasInput() => $_has(1);
  @$pb.TagNumber(2)
  void clearInput() => clearField(2);
  @$pb.TagNumber(2)
  InputComponent ensureInput() => $_ensure(1);

  @$pb.TagNumber(3)
  OutputComponent get output => $_getN(2);
  @$pb.TagNumber(3)
  set output(OutputComponent v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasOutput() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutput() => clearField(3);
  @$pb.TagNumber(3)
  OutputComponent ensureOutput() => $_ensure(2);

  @$pb.TagNumber(4)
  BlankComponent get blank => $_getN(3);
  @$pb.TagNumber(4)
  set blank(BlankComponent v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasBlank() => $_has(3);
  @$pb.TagNumber(4)
  void clearBlank() => clearField(4);
  @$pb.TagNumber(4)
  BlankComponent ensureBlank() => $_ensure(3);
}

class InitialCommitment extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InitialCommitment', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'saltedComponentHash', $pb.PbFieldType.QY)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'amountCommitment', $pb.PbFieldType.QY)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'communicationKey', $pb.PbFieldType.QY)
  ;

  InitialCommitment._() : super();
  factory InitialCommitment({
    $core.List<$core.int>? saltedComponentHash,
    $core.List<$core.int>? amountCommitment,
    $core.List<$core.int>? communicationKey,
  }) {
    final _result = create();
    if (saltedComponentHash != null) {
      _result.saltedComponentHash = saltedComponentHash;
    }
    if (amountCommitment != null) {
      _result.amountCommitment = amountCommitment;
    }
    if (communicationKey != null) {
      _result.communicationKey = communicationKey;
    }
    return _result;
  }
  factory InitialCommitment.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InitialCommitment.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InitialCommitment clone() => InitialCommitment()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InitialCommitment copyWith(void Function(InitialCommitment) updates) => super.copyWith((message) => updates(message as InitialCommitment)) as InitialCommitment; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InitialCommitment create() => InitialCommitment._();
  InitialCommitment createEmptyInstance() => create();
  static $pb.PbList<InitialCommitment> createRepeated() => $pb.PbList<InitialCommitment>();
  @$core.pragma('dart2js:noInline')
  static InitialCommitment getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InitialCommitment>(create);
  static InitialCommitment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get saltedComponentHash => $_getN(0);
  @$pb.TagNumber(1)
  set saltedComponentHash($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSaltedComponentHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearSaltedComponentHash() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get amountCommitment => $_getN(1);
  @$pb.TagNumber(2)
  set amountCommitment($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAmountCommitment() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmountCommitment() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get communicationKey => $_getN(2);
  @$pb.TagNumber(3)
  set communicationKey($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCommunicationKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommunicationKey() => clearField(3);
}

class Proof extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Proof', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'componentIdx', $pb.PbFieldType.QF3)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'salt', $pb.PbFieldType.QY)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pedersenNonce', $pb.PbFieldType.QY)
  ;

  Proof._() : super();
  factory Proof({
    $core.int? componentIdx,
    $core.List<$core.int>? salt,
    $core.List<$core.int>? pedersenNonce,
  }) {
    final _result = create();
    if (componentIdx != null) {
      _result.componentIdx = componentIdx;
    }
    if (salt != null) {
      _result.salt = salt;
    }
    if (pedersenNonce != null) {
      _result.pedersenNonce = pedersenNonce;
    }
    return _result;
  }
  factory Proof.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Proof.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Proof clone() => Proof()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Proof copyWith(void Function(Proof) updates) => super.copyWith((message) => updates(message as Proof)) as Proof; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Proof create() => Proof._();
  Proof createEmptyInstance() => create();
  static $pb.PbList<Proof> createRepeated() => $pb.PbList<Proof>();
  @$core.pragma('dart2js:noInline')
  static Proof getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Proof>(create);
  static Proof? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get componentIdx => $_getIZ(0);
  @$pb.TagNumber(1)
  set componentIdx($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasComponentIdx() => $_has(0);
  @$pb.TagNumber(1)
  void clearComponentIdx() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get salt => $_getN(1);
  @$pb.TagNumber(2)
  set salt($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSalt() => $_has(1);
  @$pb.TagNumber(2)
  void clearSalt() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get pedersenNonce => $_getN(2);
  @$pb.TagNumber(3)
  set pedersenNonce($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPedersenNonce() => $_has(2);
  @$pb.TagNumber(3)
  void clearPedersenNonce() => clearField(3);
}

class ClientHello extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ClientHello', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version', $pb.PbFieldType.QY)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'genesisHash', $pb.PbFieldType.OY)
  ;

  ClientHello._() : super();
  factory ClientHello({
    $core.List<$core.int>? version,
    $core.List<$core.int>? genesisHash,
  }) {
    final _result = create();
    if (version != null) {
      _result.version = version;
    }
    if (genesisHash != null) {
      _result.genesisHash = genesisHash;
    }
    return _result;
  }
  factory ClientHello.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClientHello.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ClientHello clone() => ClientHello()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ClientHello copyWith(void Function(ClientHello) updates) => super.copyWith((message) => updates(message as ClientHello)) as ClientHello; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ClientHello create() => ClientHello._();
  ClientHello createEmptyInstance() => create();
  static $pb.PbList<ClientHello> createRepeated() => $pb.PbList<ClientHello>();
  @$core.pragma('dart2js:noInline')
  static ClientHello getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientHello>(create);
  static ClientHello? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get version => $_getN(0);
  @$pb.TagNumber(1)
  set version($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get genesisHash => $_getN(1);
  @$pb.TagNumber(2)
  set genesisHash($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasGenesisHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearGenesisHash() => clearField(2);
}

class ServerHello extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ServerHello', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tiers', $pb.PbFieldType.PU6)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'numComponents', $pb.PbFieldType.QU3)
    ..a<$fixnum.Int64>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'componentFeerate', $pb.PbFieldType.QU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'minExcessFee', $pb.PbFieldType.QU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'maxExcessFee', $pb.PbFieldType.QU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(15, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'donationAddress')
  ;

  ServerHello._() : super();
  factory ServerHello({
    $core.Iterable<$fixnum.Int64>? tiers,
    $core.int? numComponents,
    $fixnum.Int64? componentFeerate,
    $fixnum.Int64? minExcessFee,
    $fixnum.Int64? maxExcessFee,
    $core.String? donationAddress,
  }) {
    final _result = create();
    if (tiers != null) {
      _result.tiers.addAll(tiers);
    }
    if (numComponents != null) {
      _result.numComponents = numComponents;
    }
    if (componentFeerate != null) {
      _result.componentFeerate = componentFeerate;
    }
    if (minExcessFee != null) {
      _result.minExcessFee = minExcessFee;
    }
    if (maxExcessFee != null) {
      _result.maxExcessFee = maxExcessFee;
    }
    if (donationAddress != null) {
      _result.donationAddress = donationAddress;
    }
    return _result;
  }
  factory ServerHello.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerHello.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerHello clone() => ServerHello()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerHello copyWith(void Function(ServerHello) updates) => super.copyWith((message) => updates(message as ServerHello)) as ServerHello; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ServerHello create() => ServerHello._();
  ServerHello createEmptyInstance() => create();
  static $pb.PbList<ServerHello> createRepeated() => $pb.PbList<ServerHello>();
  @$core.pragma('dart2js:noInline')
  static ServerHello getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerHello>(create);
  static ServerHello? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get tiers => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get numComponents => $_getIZ(1);
  @$pb.TagNumber(2)
  set numComponents($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNumComponents() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumComponents() => clearField(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get componentFeerate => $_getI64(2);
  @$pb.TagNumber(4)
  set componentFeerate($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(4)
  $core.bool hasComponentFeerate() => $_has(2);
  @$pb.TagNumber(4)
  void clearComponentFeerate() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get minExcessFee => $_getI64(3);
  @$pb.TagNumber(5)
  set minExcessFee($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(5)
  $core.bool hasMinExcessFee() => $_has(3);
  @$pb.TagNumber(5)
  void clearMinExcessFee() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get maxExcessFee => $_getI64(4);
  @$pb.TagNumber(6)
  set maxExcessFee($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(6)
  $core.bool hasMaxExcessFee() => $_has(4);
  @$pb.TagNumber(6)
  void clearMaxExcessFee() => clearField(6);

  @$pb.TagNumber(15)
  $core.String get donationAddress => $_getSZ(5);
  @$pb.TagNumber(15)
  set donationAddress($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(15)
  $core.bool hasDonationAddress() => $_has(5);
  @$pb.TagNumber(15)
  void clearDonationAddress() => clearField(15);
}

class JoinPools_PoolTag extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'JoinPools.PoolTag', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id', $pb.PbFieldType.QY)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'limit', $pb.PbFieldType.QU3)
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'noIp')
  ;

  JoinPools_PoolTag._() : super();
  factory JoinPools_PoolTag({
    $core.List<$core.int>? id,
    $core.int? limit,
    $core.bool? noIp,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (limit != null) {
      _result.limit = limit;
    }
    if (noIp != null) {
      _result.noIp = noIp;
    }
    return _result;
  }
  factory JoinPools_PoolTag.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory JoinPools_PoolTag.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  JoinPools_PoolTag clone() => JoinPools_PoolTag()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  JoinPools_PoolTag copyWith(void Function(JoinPools_PoolTag) updates) => super.copyWith((message) => updates(message as JoinPools_PoolTag)) as JoinPools_PoolTag; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static JoinPools_PoolTag create() => JoinPools_PoolTag._();
  JoinPools_PoolTag createEmptyInstance() => create();
  static $pb.PbList<JoinPools_PoolTag> createRepeated() => $pb.PbList<JoinPools_PoolTag>();
  @$core.pragma('dart2js:noInline')
  static JoinPools_PoolTag getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JoinPools_PoolTag>(create);
  static JoinPools_PoolTag? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get noIp => $_getBF(2);
  @$pb.TagNumber(3)
  set noIp($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNoIp() => $_has(2);
  @$pb.TagNumber(3)
  void clearNoIp() => clearField(3);
}

class JoinPools extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'JoinPools', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tiers', $pb.PbFieldType.PU6)
    ..pc<JoinPools_PoolTag>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: JoinPools_PoolTag.create)
  ;

  JoinPools._() : super();
  factory JoinPools({
    $core.Iterable<$fixnum.Int64>? tiers,
    $core.Iterable<JoinPools_PoolTag>? tags,
  }) {
    final _result = create();
    if (tiers != null) {
      _result.tiers.addAll(tiers);
    }
    if (tags != null) {
      _result.tags.addAll(tags);
    }
    return _result;
  }
  factory JoinPools.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory JoinPools.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  JoinPools clone() => JoinPools()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  JoinPools copyWith(void Function(JoinPools) updates) => super.copyWith((message) => updates(message as JoinPools)) as JoinPools; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static JoinPools create() => JoinPools._();
  JoinPools createEmptyInstance() => create();
  static $pb.PbList<JoinPools> createRepeated() => $pb.PbList<JoinPools>();
  @$core.pragma('dart2js:noInline')
  static JoinPools getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JoinPools>(create);
  static JoinPools? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get tiers => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<JoinPools_PoolTag> get tags => $_getList(1);
}

class TierStatusUpdate_TierStatus extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TierStatusUpdate.TierStatus', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'players', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'minPlayers', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'maxPlayers', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timeRemaining', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  TierStatusUpdate_TierStatus._() : super();
  factory TierStatusUpdate_TierStatus({
    $core.int? players,
    $core.int? minPlayers,
    $core.int? maxPlayers,
    $core.int? timeRemaining,
  }) {
    final _result = create();
    if (players != null) {
      _result.players = players;
    }
    if (minPlayers != null) {
      _result.minPlayers = minPlayers;
    }
    if (maxPlayers != null) {
      _result.maxPlayers = maxPlayers;
    }
    if (timeRemaining != null) {
      _result.timeRemaining = timeRemaining;
    }
    return _result;
  }
  factory TierStatusUpdate_TierStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TierStatusUpdate_TierStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TierStatusUpdate_TierStatus clone() => TierStatusUpdate_TierStatus()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TierStatusUpdate_TierStatus copyWith(void Function(TierStatusUpdate_TierStatus) updates) => super.copyWith((message) => updates(message as TierStatusUpdate_TierStatus)) as TierStatusUpdate_TierStatus; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TierStatusUpdate_TierStatus create() => TierStatusUpdate_TierStatus._();
  TierStatusUpdate_TierStatus createEmptyInstance() => create();
  static $pb.PbList<TierStatusUpdate_TierStatus> createRepeated() => $pb.PbList<TierStatusUpdate_TierStatus>();
  @$core.pragma('dart2js:noInline')
  static TierStatusUpdate_TierStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TierStatusUpdate_TierStatus>(create);
  static TierStatusUpdate_TierStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get players => $_getIZ(0);
  @$pb.TagNumber(1)
  set players($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPlayers() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayers() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get minPlayers => $_getIZ(1);
  @$pb.TagNumber(2)
  set minPlayers($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMinPlayers() => $_has(1);
  @$pb.TagNumber(2)
  void clearMinPlayers() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get maxPlayers => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxPlayers($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMaxPlayers() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxPlayers() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get timeRemaining => $_getIZ(3);
  @$pb.TagNumber(4)
  set timeRemaining($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTimeRemaining() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimeRemaining() => clearField(4);
}

class TierStatusUpdate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TierStatusUpdate', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..m<$fixnum.Int64, TierStatusUpdate_TierStatus>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statuses', entryClassName: 'TierStatusUpdate.StatusesEntry', keyFieldType: $pb.PbFieldType.OU6, valueFieldType: $pb.PbFieldType.OM, valueCreator: TierStatusUpdate_TierStatus.create, packageName: const $pb.PackageName('fusion'))
    ..hasRequiredFields = false
  ;

  TierStatusUpdate._() : super();
  factory TierStatusUpdate({
    $core.Map<$fixnum.Int64, TierStatusUpdate_TierStatus>? statuses,
  }) {
    final _result = create();
    if (statuses != null) {
      _result.statuses.addAll(statuses);
    }
    return _result;
  }
  factory TierStatusUpdate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TierStatusUpdate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TierStatusUpdate clone() => TierStatusUpdate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TierStatusUpdate copyWith(void Function(TierStatusUpdate) updates) => super.copyWith((message) => updates(message as TierStatusUpdate)) as TierStatusUpdate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TierStatusUpdate create() => TierStatusUpdate._();
  TierStatusUpdate createEmptyInstance() => create();
  static $pb.PbList<TierStatusUpdate> createRepeated() => $pb.PbList<TierStatusUpdate>();
  @$core.pragma('dart2js:noInline')
  static TierStatusUpdate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TierStatusUpdate>(create);
  static TierStatusUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$fixnum.Int64, TierStatusUpdate_TierStatus> get statuses => $_getMap(0);
}

class FusionBegin extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FusionBegin', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tier', $pb.PbFieldType.QU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'covertDomain', $pb.PbFieldType.QY)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'covertPort', $pb.PbFieldType.QU3)
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'covertSsl')
    ..a<$fixnum.Int64>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serverTime', $pb.PbFieldType.QF6, defaultOrMaker: $fixnum.Int64.ZERO)
  ;

  FusionBegin._() : super();
  factory FusionBegin({
    $fixnum.Int64? tier,
    $core.List<$core.int>? covertDomain,
    $core.int? covertPort,
    $core.bool? covertSsl,
    $fixnum.Int64? serverTime,
  }) {
    final _result = create();
    if (tier != null) {
      _result.tier = tier;
    }
    if (covertDomain != null) {
      _result.covertDomain = covertDomain;
    }
    if (covertPort != null) {
      _result.covertPort = covertPort;
    }
    if (covertSsl != null) {
      _result.covertSsl = covertSsl;
    }
    if (serverTime != null) {
      _result.serverTime = serverTime;
    }
    return _result;
  }
  factory FusionBegin.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FusionBegin.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FusionBegin clone() => FusionBegin()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FusionBegin copyWith(void Function(FusionBegin) updates) => super.copyWith((message) => updates(message as FusionBegin)) as FusionBegin; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FusionBegin create() => FusionBegin._();
  FusionBegin createEmptyInstance() => create();
  static $pb.PbList<FusionBegin> createRepeated() => $pb.PbList<FusionBegin>();
  @$core.pragma('dart2js:noInline')
  static FusionBegin getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FusionBegin>(create);
  static FusionBegin? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get tier => $_getI64(0);
  @$pb.TagNumber(1)
  set tier($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTier() => $_has(0);
  @$pb.TagNumber(1)
  void clearTier() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get covertDomain => $_getN(1);
  @$pb.TagNumber(2)
  set covertDomain($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCovertDomain() => $_has(1);
  @$pb.TagNumber(2)
  void clearCovertDomain() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get covertPort => $_getIZ(2);
  @$pb.TagNumber(3)
  set covertPort($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCovertPort() => $_has(2);
  @$pb.TagNumber(3)
  void clearCovertPort() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get covertSsl => $_getBF(3);
  @$pb.TagNumber(4)
  set covertSsl($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCovertSsl() => $_has(3);
  @$pb.TagNumber(4)
  void clearCovertSsl() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get serverTime => $_getI64(4);
  @$pb.TagNumber(5)
  set serverTime($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasServerTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearServerTime() => clearField(5);
}

class StartRound extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'StartRound', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'roundPubkey', $pb.PbFieldType.QY)
    ..p<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blindNoncePoints', $pb.PbFieldType.PY)
    ..a<$fixnum.Int64>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serverTime', $pb.PbFieldType.QF6, defaultOrMaker: $fixnum.Int64.ZERO)
  ;

  StartRound._() : super();
  factory StartRound({
    $core.List<$core.int>? roundPubkey,
    $core.Iterable<$core.List<$core.int>>? blindNoncePoints,
    $fixnum.Int64? serverTime,
  }) {
    final _result = create();
    if (roundPubkey != null) {
      _result.roundPubkey = roundPubkey;
    }
    if (blindNoncePoints != null) {
      _result.blindNoncePoints.addAll(blindNoncePoints);
    }
    if (serverTime != null) {
      _result.serverTime = serverTime;
    }
    return _result;
  }
  factory StartRound.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StartRound.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StartRound clone() => StartRound()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StartRound copyWith(void Function(StartRound) updates) => super.copyWith((message) => updates(message as StartRound)) as StartRound; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StartRound create() => StartRound._();
  StartRound createEmptyInstance() => create();
  static $pb.PbList<StartRound> createRepeated() => $pb.PbList<StartRound>();
  @$core.pragma('dart2js:noInline')
  static StartRound getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartRound>(create);
  static StartRound? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get roundPubkey => $_getN(0);
  @$pb.TagNumber(1)
  set roundPubkey($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRoundPubkey() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoundPubkey() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.List<$core.int>> get blindNoncePoints => $_getList(1);

  @$pb.TagNumber(5)
  $fixnum.Int64 get serverTime => $_getI64(2);
  @$pb.TagNumber(5)
  set serverTime($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(5)
  $core.bool hasServerTime() => $_has(2);
  @$pb.TagNumber(5)
  void clearServerTime() => clearField(5);
}

class PlayerCommit extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PlayerCommit', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..p<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'initialCommitments', $pb.PbFieldType.PY)
    ..a<$fixnum.Int64>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'excessFee', $pb.PbFieldType.QU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pedersenTotalNonce', $pb.PbFieldType.QY)
    ..a<$core.List<$core.int>>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'randomNumberCommitment', $pb.PbFieldType.QY)
    ..p<$core.List<$core.int>>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blindSigRequests', $pb.PbFieldType.PY)
  ;

  PlayerCommit._() : super();
  factory PlayerCommit({
    $core.Iterable<$core.List<$core.int>>? initialCommitments,
    $fixnum.Int64? excessFee,
    $core.List<$core.int>? pedersenTotalNonce,
    $core.List<$core.int>? randomNumberCommitment,
    $core.Iterable<$core.List<$core.int>>? blindSigRequests,
  }) {
    final _result = create();
    if (initialCommitments != null) {
      _result.initialCommitments.addAll(initialCommitments);
    }
    if (excessFee != null) {
      _result.excessFee = excessFee;
    }
    if (pedersenTotalNonce != null) {
      _result.pedersenTotalNonce = pedersenTotalNonce;
    }
    if (randomNumberCommitment != null) {
      _result.randomNumberCommitment = randomNumberCommitment;
    }
    if (blindSigRequests != null) {
      _result.blindSigRequests.addAll(blindSigRequests);
    }
    return _result;
  }
  factory PlayerCommit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PlayerCommit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PlayerCommit clone() => PlayerCommit()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PlayerCommit copyWith(void Function(PlayerCommit) updates) => super.copyWith((message) => updates(message as PlayerCommit)) as PlayerCommit; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PlayerCommit create() => PlayerCommit._();
  PlayerCommit createEmptyInstance() => create();
  static $pb.PbList<PlayerCommit> createRepeated() => $pb.PbList<PlayerCommit>();
  @$core.pragma('dart2js:noInline')
  static PlayerCommit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlayerCommit>(create);
  static PlayerCommit? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.List<$core.int>> get initialCommitments => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get excessFee => $_getI64(1);
  @$pb.TagNumber(2)
  set excessFee($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasExcessFee() => $_has(1);
  @$pb.TagNumber(2)
  void clearExcessFee() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get pedersenTotalNonce => $_getN(2);
  @$pb.TagNumber(3)
  set pedersenTotalNonce($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPedersenTotalNonce() => $_has(2);
  @$pb.TagNumber(3)
  void clearPedersenTotalNonce() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get randomNumberCommitment => $_getN(3);
  @$pb.TagNumber(4)
  set randomNumberCommitment($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRandomNumberCommitment() => $_has(3);
  @$pb.TagNumber(4)
  void clearRandomNumberCommitment() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.List<$core.int>> get blindSigRequests => $_getList(4);
}

class BlindSigResponses extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BlindSigResponses', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..p<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scalars', $pb.PbFieldType.PY)
    ..hasRequiredFields = false
  ;

  BlindSigResponses._() : super();
  factory BlindSigResponses({
    $core.Iterable<$core.List<$core.int>>? scalars,
  }) {
    final _result = create();
    if (scalars != null) {
      _result.scalars.addAll(scalars);
    }
    return _result;
  }
  factory BlindSigResponses.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlindSigResponses.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlindSigResponses clone() => BlindSigResponses()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlindSigResponses copyWith(void Function(BlindSigResponses) updates) => super.copyWith((message) => updates(message as BlindSigResponses)) as BlindSigResponses; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BlindSigResponses create() => BlindSigResponses._();
  BlindSigResponses createEmptyInstance() => create();
  static $pb.PbList<BlindSigResponses> createRepeated() => $pb.PbList<BlindSigResponses>();
  @$core.pragma('dart2js:noInline')
  static BlindSigResponses getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlindSigResponses>(create);
  static BlindSigResponses? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.List<$core.int>> get scalars => $_getList(0);
}

class AllCommitments extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AllCommitments', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..p<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'initialCommitments', $pb.PbFieldType.PY)
    ..hasRequiredFields = false
  ;

  AllCommitments._() : super();
  factory AllCommitments({
    $core.Iterable<$core.List<$core.int>>? initialCommitments,
  }) {
    final _result = create();
    if (initialCommitments != null) {
      _result.initialCommitments.addAll(initialCommitments);
    }
    return _result;
  }
  factory AllCommitments.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AllCommitments.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AllCommitments clone() => AllCommitments()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AllCommitments copyWith(void Function(AllCommitments) updates) => super.copyWith((message) => updates(message as AllCommitments)) as AllCommitments; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AllCommitments create() => AllCommitments._();
  AllCommitments createEmptyInstance() => create();
  static $pb.PbList<AllCommitments> createRepeated() => $pb.PbList<AllCommitments>();
  @$core.pragma('dart2js:noInline')
  static AllCommitments getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AllCommitments>(create);
  static AllCommitments? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.List<$core.int>> get initialCommitments => $_getList(0);
}

class CovertComponent extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CovertComponent', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'roundPubkey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signature', $pb.PbFieldType.QY)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'component', $pb.PbFieldType.QY)
  ;

  CovertComponent._() : super();
  factory CovertComponent({
    $core.List<$core.int>? roundPubkey,
    $core.List<$core.int>? signature,
    $core.List<$core.int>? component,
  }) {
    final _result = create();
    if (roundPubkey != null) {
      _result.roundPubkey = roundPubkey;
    }
    if (signature != null) {
      _result.signature = signature;
    }
    if (component != null) {
      _result.component = component;
    }
    return _result;
  }
  factory CovertComponent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CovertComponent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CovertComponent clone() => CovertComponent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CovertComponent copyWith(void Function(CovertComponent) updates) => super.copyWith((message) => updates(message as CovertComponent)) as CovertComponent; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CovertComponent create() => CovertComponent._();
  CovertComponent createEmptyInstance() => create();
  static $pb.PbList<CovertComponent> createRepeated() => $pb.PbList<CovertComponent>();
  @$core.pragma('dart2js:noInline')
  static CovertComponent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CovertComponent>(create);
  static CovertComponent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get roundPubkey => $_getN(0);
  @$pb.TagNumber(1)
  set roundPubkey($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRoundPubkey() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoundPubkey() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get signature => $_getN(1);
  @$pb.TagNumber(2)
  set signature($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get component => $_getN(2);
  @$pb.TagNumber(3)
  set component($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasComponent() => $_has(2);
  @$pb.TagNumber(3)
  void clearComponent() => clearField(3);
}

class ShareCovertComponents extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ShareCovertComponents', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..p<$core.List<$core.int>>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'components', $pb.PbFieldType.PY)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'skipSignatures')
    ..a<$core.List<$core.int>>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sessionHash', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  ShareCovertComponents._() : super();
  factory ShareCovertComponents({
    $core.Iterable<$core.List<$core.int>>? components,
    $core.bool? skipSignatures,
    $core.List<$core.int>? sessionHash,
  }) {
    final _result = create();
    if (components != null) {
      _result.components.addAll(components);
    }
    if (skipSignatures != null) {
      _result.skipSignatures = skipSignatures;
    }
    if (sessionHash != null) {
      _result.sessionHash = sessionHash;
    }
    return _result;
  }
  factory ShareCovertComponents.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ShareCovertComponents.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ShareCovertComponents clone() => ShareCovertComponents()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ShareCovertComponents copyWith(void Function(ShareCovertComponents) updates) => super.copyWith((message) => updates(message as ShareCovertComponents)) as ShareCovertComponents; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ShareCovertComponents create() => ShareCovertComponents._();
  ShareCovertComponents createEmptyInstance() => create();
  static $pb.PbList<ShareCovertComponents> createRepeated() => $pb.PbList<ShareCovertComponents>();
  @$core.pragma('dart2js:noInline')
  static ShareCovertComponents getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ShareCovertComponents>(create);
  static ShareCovertComponents? _defaultInstance;

  @$pb.TagNumber(4)
  $core.List<$core.List<$core.int>> get components => $_getList(0);

  @$pb.TagNumber(5)
  $core.bool get skipSignatures => $_getBF(1);
  @$pb.TagNumber(5)
  set skipSignatures($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(5)
  $core.bool hasSkipSignatures() => $_has(1);
  @$pb.TagNumber(5)
  void clearSkipSignatures() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get sessionHash => $_getN(2);
  @$pb.TagNumber(6)
  set sessionHash($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(6)
  $core.bool hasSessionHash() => $_has(2);
  @$pb.TagNumber(6)
  void clearSessionHash() => clearField(6);
}

class CovertTransactionSignature extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CovertTransactionSignature', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'roundPubkey', $pb.PbFieldType.OY)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'whichInput', $pb.PbFieldType.QU3)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'txsignature', $pb.PbFieldType.QY)
  ;

  CovertTransactionSignature._() : super();
  factory CovertTransactionSignature({
    $core.List<$core.int>? roundPubkey,
    $core.int? whichInput,
    $core.List<$core.int>? txsignature,
  }) {
    final _result = create();
    if (roundPubkey != null) {
      _result.roundPubkey = roundPubkey;
    }
    if (whichInput != null) {
      _result.whichInput = whichInput;
    }
    if (txsignature != null) {
      _result.txsignature = txsignature;
    }
    return _result;
  }
  factory CovertTransactionSignature.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CovertTransactionSignature.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CovertTransactionSignature clone() => CovertTransactionSignature()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CovertTransactionSignature copyWith(void Function(CovertTransactionSignature) updates) => super.copyWith((message) => updates(message as CovertTransactionSignature)) as CovertTransactionSignature; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CovertTransactionSignature create() => CovertTransactionSignature._();
  CovertTransactionSignature createEmptyInstance() => create();
  static $pb.PbList<CovertTransactionSignature> createRepeated() => $pb.PbList<CovertTransactionSignature>();
  @$core.pragma('dart2js:noInline')
  static CovertTransactionSignature getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CovertTransactionSignature>(create);
  static CovertTransactionSignature? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get roundPubkey => $_getN(0);
  @$pb.TagNumber(1)
  set roundPubkey($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRoundPubkey() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoundPubkey() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get whichInput => $_getIZ(1);
  @$pb.TagNumber(2)
  set whichInput($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWhichInput() => $_has(1);
  @$pb.TagNumber(2)
  void clearWhichInput() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get txsignature => $_getN(2);
  @$pb.TagNumber(3)
  set txsignature($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTxsignature() => $_has(2);
  @$pb.TagNumber(3)
  void clearTxsignature() => clearField(3);
}

class FusionResult extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FusionResult', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.bool>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ok', $pb.PbFieldType.QB)
    ..p<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'txsignatures', $pb.PbFieldType.PY)
    ..p<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'badComponents', $pb.PbFieldType.PU3)
  ;

  FusionResult._() : super();
  factory FusionResult({
    $core.bool? ok,
    $core.Iterable<$core.List<$core.int>>? txsignatures,
    $core.Iterable<$core.int>? badComponents,
  }) {
    final _result = create();
    if (ok != null) {
      _result.ok = ok;
    }
    if (txsignatures != null) {
      _result.txsignatures.addAll(txsignatures);
    }
    if (badComponents != null) {
      _result.badComponents.addAll(badComponents);
    }
    return _result;
  }
  factory FusionResult.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FusionResult.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FusionResult clone() => FusionResult()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FusionResult copyWith(void Function(FusionResult) updates) => super.copyWith((message) => updates(message as FusionResult)) as FusionResult; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FusionResult create() => FusionResult._();
  FusionResult createEmptyInstance() => create();
  static $pb.PbList<FusionResult> createRepeated() => $pb.PbList<FusionResult>();
  @$core.pragma('dart2js:noInline')
  static FusionResult getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FusionResult>(create);
  static FusionResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.List<$core.int>> get txsignatures => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get badComponents => $_getList(2);
}

class MyProofsList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MyProofsList', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..p<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'encryptedProofs', $pb.PbFieldType.PY)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'randomNumber', $pb.PbFieldType.QY)
  ;

  MyProofsList._() : super();
  factory MyProofsList({
    $core.Iterable<$core.List<$core.int>>? encryptedProofs,
    $core.List<$core.int>? randomNumber,
  }) {
    final _result = create();
    if (encryptedProofs != null) {
      _result.encryptedProofs.addAll(encryptedProofs);
    }
    if (randomNumber != null) {
      _result.randomNumber = randomNumber;
    }
    return _result;
  }
  factory MyProofsList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MyProofsList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MyProofsList clone() => MyProofsList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MyProofsList copyWith(void Function(MyProofsList) updates) => super.copyWith((message) => updates(message as MyProofsList)) as MyProofsList; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MyProofsList create() => MyProofsList._();
  MyProofsList createEmptyInstance() => create();
  static $pb.PbList<MyProofsList> createRepeated() => $pb.PbList<MyProofsList>();
  @$core.pragma('dart2js:noInline')
  static MyProofsList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MyProofsList>(create);
  static MyProofsList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.List<$core.int>> get encryptedProofs => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get randomNumber => $_getN(1);
  @$pb.TagNumber(2)
  set randomNumber($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRandomNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearRandomNumber() => clearField(2);
}

class TheirProofsList_RelayedProof extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TheirProofsList.RelayedProof', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'encryptedProof', $pb.PbFieldType.QY)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'srcCommitmentIdx', $pb.PbFieldType.QU3)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dstKeyIdx', $pb.PbFieldType.QU3)
  ;

  TheirProofsList_RelayedProof._() : super();
  factory TheirProofsList_RelayedProof({
    $core.List<$core.int>? encryptedProof,
    $core.int? srcCommitmentIdx,
    $core.int? dstKeyIdx,
  }) {
    final _result = create();
    if (encryptedProof != null) {
      _result.encryptedProof = encryptedProof;
    }
    if (srcCommitmentIdx != null) {
      _result.srcCommitmentIdx = srcCommitmentIdx;
    }
    if (dstKeyIdx != null) {
      _result.dstKeyIdx = dstKeyIdx;
    }
    return _result;
  }
  factory TheirProofsList_RelayedProof.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TheirProofsList_RelayedProof.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TheirProofsList_RelayedProof clone() => TheirProofsList_RelayedProof()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TheirProofsList_RelayedProof copyWith(void Function(TheirProofsList_RelayedProof) updates) => super.copyWith((message) => updates(message as TheirProofsList_RelayedProof)) as TheirProofsList_RelayedProof; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TheirProofsList_RelayedProof create() => TheirProofsList_RelayedProof._();
  TheirProofsList_RelayedProof createEmptyInstance() => create();
  static $pb.PbList<TheirProofsList_RelayedProof> createRepeated() => $pb.PbList<TheirProofsList_RelayedProof>();
  @$core.pragma('dart2js:noInline')
  static TheirProofsList_RelayedProof getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TheirProofsList_RelayedProof>(create);
  static TheirProofsList_RelayedProof? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get encryptedProof => $_getN(0);
  @$pb.TagNumber(1)
  set encryptedProof($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEncryptedProof() => $_has(0);
  @$pb.TagNumber(1)
  void clearEncryptedProof() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get srcCommitmentIdx => $_getIZ(1);
  @$pb.TagNumber(2)
  set srcCommitmentIdx($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSrcCommitmentIdx() => $_has(1);
  @$pb.TagNumber(2)
  void clearSrcCommitmentIdx() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get dstKeyIdx => $_getIZ(2);
  @$pb.TagNumber(3)
  set dstKeyIdx($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDstKeyIdx() => $_has(2);
  @$pb.TagNumber(3)
  void clearDstKeyIdx() => clearField(3);
}

class TheirProofsList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TheirProofsList', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..pc<TheirProofsList_RelayedProof>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'proofs', $pb.PbFieldType.PM, subBuilder: TheirProofsList_RelayedProof.create)
  ;

  TheirProofsList._() : super();
  factory TheirProofsList({
    $core.Iterable<TheirProofsList_RelayedProof>? proofs,
  }) {
    final _result = create();
    if (proofs != null) {
      _result.proofs.addAll(proofs);
    }
    return _result;
  }
  factory TheirProofsList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TheirProofsList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TheirProofsList clone() => TheirProofsList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TheirProofsList copyWith(void Function(TheirProofsList) updates) => super.copyWith((message) => updates(message as TheirProofsList)) as TheirProofsList; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TheirProofsList create() => TheirProofsList._();
  TheirProofsList createEmptyInstance() => create();
  static $pb.PbList<TheirProofsList> createRepeated() => $pb.PbList<TheirProofsList>();
  @$core.pragma('dart2js:noInline')
  static TheirProofsList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TheirProofsList>(create);
  static TheirProofsList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<TheirProofsList_RelayedProof> get proofs => $_getList(0);
}

enum Blames_BlameProof_Decrypter {
  sessionKey, 
  privkey, 
  notSet
}

class Blames_BlameProof extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, Blames_BlameProof_Decrypter> _Blames_BlameProof_DecrypterByTag = {
    2 : Blames_BlameProof_Decrypter.sessionKey,
    3 : Blames_BlameProof_Decrypter.privkey,
    0 : Blames_BlameProof_Decrypter.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Blames.BlameProof', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..a<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'whichProof', $pb.PbFieldType.QU3)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sessionKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'privkey', $pb.PbFieldType.OY)
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'needLookupBlockchain')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blameReason')
  ;

  Blames_BlameProof._() : super();
  factory Blames_BlameProof({
    $core.int? whichProof,
    $core.List<$core.int>? sessionKey,
    $core.List<$core.int>? privkey,
    $core.bool? needLookupBlockchain,
    $core.String? blameReason,
  }) {
    final _result = create();
    if (whichProof != null) {
      _result.whichProof = whichProof;
    }
    if (sessionKey != null) {
      _result.sessionKey = sessionKey;
    }
    if (privkey != null) {
      _result.privkey = privkey;
    }
    if (needLookupBlockchain != null) {
      _result.needLookupBlockchain = needLookupBlockchain;
    }
    if (blameReason != null) {
      _result.blameReason = blameReason;
    }
    return _result;
  }
  factory Blames_BlameProof.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Blames_BlameProof.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Blames_BlameProof clone() => Blames_BlameProof()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Blames_BlameProof copyWith(void Function(Blames_BlameProof) updates) => super.copyWith((message) => updates(message as Blames_BlameProof)) as Blames_BlameProof; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Blames_BlameProof create() => Blames_BlameProof._();
  Blames_BlameProof createEmptyInstance() => create();
  static $pb.PbList<Blames_BlameProof> createRepeated() => $pb.PbList<Blames_BlameProof>();
  @$core.pragma('dart2js:noInline')
  static Blames_BlameProof getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Blames_BlameProof>(create);
  static Blames_BlameProof? _defaultInstance;

  Blames_BlameProof_Decrypter whichDecrypter() => _Blames_BlameProof_DecrypterByTag[$_whichOneof(0)]!;
  void clearDecrypter() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.int get whichProof => $_getIZ(0);
  @$pb.TagNumber(1)
  set whichProof($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasWhichProof() => $_has(0);
  @$pb.TagNumber(1)
  void clearWhichProof() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get sessionKey => $_getN(1);
  @$pb.TagNumber(2)
  set sessionKey($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSessionKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionKey() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get privkey => $_getN(2);
  @$pb.TagNumber(3)
  set privkey($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPrivkey() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrivkey() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get needLookupBlockchain => $_getBF(3);
  @$pb.TagNumber(4)
  set needLookupBlockchain($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasNeedLookupBlockchain() => $_has(3);
  @$pb.TagNumber(4)
  void clearNeedLookupBlockchain() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get blameReason => $_getSZ(4);
  @$pb.TagNumber(5)
  set blameReason($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasBlameReason() => $_has(4);
  @$pb.TagNumber(5)
  void clearBlameReason() => clearField(5);
}

class Blames extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Blames', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..pc<Blames_BlameProof>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blames', $pb.PbFieldType.PM, subBuilder: Blames_BlameProof.create)
  ;

  Blames._() : super();
  factory Blames({
    $core.Iterable<Blames_BlameProof>? blames,
  }) {
    final _result = create();
    if (blames != null) {
      _result.blames.addAll(blames);
    }
    return _result;
  }
  factory Blames.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Blames.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Blames clone() => Blames()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Blames copyWith(void Function(Blames) updates) => super.copyWith((message) => updates(message as Blames)) as Blames; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Blames create() => Blames._();
  Blames createEmptyInstance() => create();
  static $pb.PbList<Blames> createRepeated() => $pb.PbList<Blames>();
  @$core.pragma('dart2js:noInline')
  static Blames getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Blames>(create);
  static Blames? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Blames_BlameProof> get blames => $_getList(0);
}

class RestartRound extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RestartRound', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  RestartRound._() : super();
  factory RestartRound() => create();
  factory RestartRound.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RestartRound.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RestartRound clone() => RestartRound()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RestartRound copyWith(void Function(RestartRound) updates) => super.copyWith((message) => updates(message as RestartRound)) as RestartRound; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RestartRound create() => RestartRound._();
  RestartRound createEmptyInstance() => create();
  static $pb.PbList<RestartRound> createRepeated() => $pb.PbList<RestartRound>();
  @$core.pragma('dart2js:noInline')
  static RestartRound getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RestartRound>(create);
  static RestartRound? _defaultInstance;
}

class Error extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Error', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'message')
    ..hasRequiredFields = false
  ;

  Error._() : super();
  factory Error({
    $core.String? message,
  }) {
    final _result = create();
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory Error.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Error.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Error clone() => Error()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Error copyWith(void Function(Error) updates) => super.copyWith((message) => updates(message as Error)) as Error; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Error create() => Error._();
  Error createEmptyInstance() => create();
  static $pb.PbList<Error> createRepeated() => $pb.PbList<Error>();
  @$core.pragma('dart2js:noInline')
  static Error getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Error>(create);
  static Error? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => clearField(1);
}

class Ping extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Ping', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  Ping._() : super();
  factory Ping() => create();
  factory Ping.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Ping.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Ping clone() => Ping()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Ping copyWith(void Function(Ping) updates) => super.copyWith((message) => updates(message as Ping)) as Ping; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Ping create() => Ping._();
  Ping createEmptyInstance() => create();
  static $pb.PbList<Ping> createRepeated() => $pb.PbList<Ping>();
  @$core.pragma('dart2js:noInline')
  static Ping getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ping>(create);
  static Ping? _defaultInstance;
}

class OK extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'OK', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  OK._() : super();
  factory OK() => create();
  factory OK.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OK.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OK clone() => OK()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OK copyWith(void Function(OK) updates) => super.copyWith((message) => updates(message as OK)) as OK; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static OK create() => OK._();
  OK createEmptyInstance() => create();
  static $pb.PbList<OK> createRepeated() => $pb.PbList<OK>();
  @$core.pragma('dart2js:noInline')
  static OK getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OK>(create);
  static OK? _defaultInstance;
}

enum ClientMessage_Msg {
  clienthello, 
  joinpools, 
  playercommit, 
  myproofslist, 
  blames, 
  notSet
}

class ClientMessage extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, ClientMessage_Msg> _ClientMessage_MsgByTag = {
    1 : ClientMessage_Msg.clienthello,
    2 : ClientMessage_Msg.joinpools,
    3 : ClientMessage_Msg.playercommit,
    5 : ClientMessage_Msg.myproofslist,
    6 : ClientMessage_Msg.blames,
    0 : ClientMessage_Msg.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ClientMessage', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 5, 6])
    ..aOM<ClientHello>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'clienthello', subBuilder: ClientHello.create)
    ..aOM<JoinPools>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'joinpools', subBuilder: JoinPools.create)
    ..aOM<PlayerCommit>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'playercommit', subBuilder: PlayerCommit.create)
    ..aOM<MyProofsList>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'myproofslist', subBuilder: MyProofsList.create)
    ..aOM<Blames>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blames', subBuilder: Blames.create)
  ;

  ClientMessage._() : super();
  factory ClientMessage({
    ClientHello? clienthello,
    JoinPools? joinpools,
    PlayerCommit? playercommit,
    MyProofsList? myproofslist,
    Blames? blames,
  }) {
    final _result = create();
    if (clienthello != null) {
      _result.clienthello = clienthello;
    }
    if (joinpools != null) {
      _result.joinpools = joinpools;
    }
    if (playercommit != null) {
      _result.playercommit = playercommit;
    }
    if (myproofslist != null) {
      _result.myproofslist = myproofslist;
    }
    if (blames != null) {
      _result.blames = blames;
    }
    return _result;
  }
  factory ClientMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClientMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ClientMessage clone() => ClientMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ClientMessage copyWith(void Function(ClientMessage) updates) => super.copyWith((message) => updates(message as ClientMessage)) as ClientMessage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ClientMessage create() => ClientMessage._();
  ClientMessage createEmptyInstance() => create();
  static $pb.PbList<ClientMessage> createRepeated() => $pb.PbList<ClientMessage>();
  @$core.pragma('dart2js:noInline')
  static ClientMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientMessage>(create);
  static ClientMessage? _defaultInstance;

  ClientMessage_Msg whichMsg() => _ClientMessage_MsgByTag[$_whichOneof(0)]!;
  void clearMsg() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ClientHello get clienthello => $_getN(0);
  @$pb.TagNumber(1)
  set clienthello(ClientHello v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasClienthello() => $_has(0);
  @$pb.TagNumber(1)
  void clearClienthello() => clearField(1);
  @$pb.TagNumber(1)
  ClientHello ensureClienthello() => $_ensure(0);

  @$pb.TagNumber(2)
  JoinPools get joinpools => $_getN(1);
  @$pb.TagNumber(2)
  set joinpools(JoinPools v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasJoinpools() => $_has(1);
  @$pb.TagNumber(2)
  void clearJoinpools() => clearField(2);
  @$pb.TagNumber(2)
  JoinPools ensureJoinpools() => $_ensure(1);

  @$pb.TagNumber(3)
  PlayerCommit get playercommit => $_getN(2);
  @$pb.TagNumber(3)
  set playercommit(PlayerCommit v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasPlayercommit() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlayercommit() => clearField(3);
  @$pb.TagNumber(3)
  PlayerCommit ensurePlayercommit() => $_ensure(2);

  @$pb.TagNumber(5)
  MyProofsList get myproofslist => $_getN(3);
  @$pb.TagNumber(5)
  set myproofslist(MyProofsList v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasMyproofslist() => $_has(3);
  @$pb.TagNumber(5)
  void clearMyproofslist() => clearField(5);
  @$pb.TagNumber(5)
  MyProofsList ensureMyproofslist() => $_ensure(3);

  @$pb.TagNumber(6)
  Blames get blames => $_getN(4);
  @$pb.TagNumber(6)
  set blames(Blames v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasBlames() => $_has(4);
  @$pb.TagNumber(6)
  void clearBlames() => clearField(6);
  @$pb.TagNumber(6)
  Blames ensureBlames() => $_ensure(4);
}

enum ServerMessage_Msg {
  serverhello, 
  tierstatusupdate, 
  fusionbegin, 
  startround, 
  blindsigresponses, 
  allcommitments, 
  sharecovertcomponents, 
  fusionresult, 
  theirproofslist, 
  restartround, 
  error, 
  notSet
}

class ServerMessage extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, ServerMessage_Msg> _ServerMessage_MsgByTag = {
    1 : ServerMessage_Msg.serverhello,
    2 : ServerMessage_Msg.tierstatusupdate,
    3 : ServerMessage_Msg.fusionbegin,
    4 : ServerMessage_Msg.startround,
    5 : ServerMessage_Msg.blindsigresponses,
    6 : ServerMessage_Msg.allcommitments,
    7 : ServerMessage_Msg.sharecovertcomponents,
    8 : ServerMessage_Msg.fusionresult,
    9 : ServerMessage_Msg.theirproofslist,
    14 : ServerMessage_Msg.restartround,
    15 : ServerMessage_Msg.error,
    0 : ServerMessage_Msg.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ServerMessage', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 14, 15])
    ..aOM<ServerHello>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serverhello', subBuilder: ServerHello.create)
    ..aOM<TierStatusUpdate>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tierstatusupdate', subBuilder: TierStatusUpdate.create)
    ..aOM<FusionBegin>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fusionbegin', subBuilder: FusionBegin.create)
    ..aOM<StartRound>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startround', subBuilder: StartRound.create)
    ..aOM<BlindSigResponses>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blindsigresponses', subBuilder: BlindSigResponses.create)
    ..aOM<AllCommitments>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'allcommitments', subBuilder: AllCommitments.create)
    ..aOM<ShareCovertComponents>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sharecovertcomponents', subBuilder: ShareCovertComponents.create)
    ..aOM<FusionResult>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fusionresult', subBuilder: FusionResult.create)
    ..aOM<TheirProofsList>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'theirproofslist', subBuilder: TheirProofsList.create)
    ..aOM<RestartRound>(14, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'restartround', subBuilder: RestartRound.create)
    ..aOM<Error>(15, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'error', subBuilder: Error.create)
  ;

  ServerMessage._() : super();
  factory ServerMessage({
    ServerHello? serverhello,
    TierStatusUpdate? tierstatusupdate,
    FusionBegin? fusionbegin,
    StartRound? startround,
    BlindSigResponses? blindsigresponses,
    AllCommitments? allcommitments,
    ShareCovertComponents? sharecovertcomponents,
    FusionResult? fusionresult,
    TheirProofsList? theirproofslist,
    RestartRound? restartround,
    Error? error,
  }) {
    final _result = create();
    if (serverhello != null) {
      _result.serverhello = serverhello;
    }
    if (tierstatusupdate != null) {
      _result.tierstatusupdate = tierstatusupdate;
    }
    if (fusionbegin != null) {
      _result.fusionbegin = fusionbegin;
    }
    if (startround != null) {
      _result.startround = startround;
    }
    if (blindsigresponses != null) {
      _result.blindsigresponses = blindsigresponses;
    }
    if (allcommitments != null) {
      _result.allcommitments = allcommitments;
    }
    if (sharecovertcomponents != null) {
      _result.sharecovertcomponents = sharecovertcomponents;
    }
    if (fusionresult != null) {
      _result.fusionresult = fusionresult;
    }
    if (theirproofslist != null) {
      _result.theirproofslist = theirproofslist;
    }
    if (restartround != null) {
      _result.restartround = restartround;
    }
    if (error != null) {
      _result.error = error;
    }
    return _result;
  }
  factory ServerMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerMessage clone() => ServerMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerMessage copyWith(void Function(ServerMessage) updates) => super.copyWith((message) => updates(message as ServerMessage)) as ServerMessage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ServerMessage create() => ServerMessage._();
  ServerMessage createEmptyInstance() => create();
  static $pb.PbList<ServerMessage> createRepeated() => $pb.PbList<ServerMessage>();
  @$core.pragma('dart2js:noInline')
  static ServerMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerMessage>(create);
  static ServerMessage? _defaultInstance;

  ServerMessage_Msg whichMsg() => _ServerMessage_MsgByTag[$_whichOneof(0)]!;
  void clearMsg() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ServerHello get serverhello => $_getN(0);
  @$pb.TagNumber(1)
  set serverhello(ServerHello v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasServerhello() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerhello() => clearField(1);
  @$pb.TagNumber(1)
  ServerHello ensureServerhello() => $_ensure(0);

  @$pb.TagNumber(2)
  TierStatusUpdate get tierstatusupdate => $_getN(1);
  @$pb.TagNumber(2)
  set tierstatusupdate(TierStatusUpdate v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTierstatusupdate() => $_has(1);
  @$pb.TagNumber(2)
  void clearTierstatusupdate() => clearField(2);
  @$pb.TagNumber(2)
  TierStatusUpdate ensureTierstatusupdate() => $_ensure(1);

  @$pb.TagNumber(3)
  FusionBegin get fusionbegin => $_getN(2);
  @$pb.TagNumber(3)
  set fusionbegin(FusionBegin v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFusionbegin() => $_has(2);
  @$pb.TagNumber(3)
  void clearFusionbegin() => clearField(3);
  @$pb.TagNumber(3)
  FusionBegin ensureFusionbegin() => $_ensure(2);

  @$pb.TagNumber(4)
  StartRound get startround => $_getN(3);
  @$pb.TagNumber(4)
  set startround(StartRound v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasStartround() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartround() => clearField(4);
  @$pb.TagNumber(4)
  StartRound ensureStartround() => $_ensure(3);

  @$pb.TagNumber(5)
  BlindSigResponses get blindsigresponses => $_getN(4);
  @$pb.TagNumber(5)
  set blindsigresponses(BlindSigResponses v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasBlindsigresponses() => $_has(4);
  @$pb.TagNumber(5)
  void clearBlindsigresponses() => clearField(5);
  @$pb.TagNumber(5)
  BlindSigResponses ensureBlindsigresponses() => $_ensure(4);

  @$pb.TagNumber(6)
  AllCommitments get allcommitments => $_getN(5);
  @$pb.TagNumber(6)
  set allcommitments(AllCommitments v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasAllcommitments() => $_has(5);
  @$pb.TagNumber(6)
  void clearAllcommitments() => clearField(6);
  @$pb.TagNumber(6)
  AllCommitments ensureAllcommitments() => $_ensure(5);

  @$pb.TagNumber(7)
  ShareCovertComponents get sharecovertcomponents => $_getN(6);
  @$pb.TagNumber(7)
  set sharecovertcomponents(ShareCovertComponents v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasSharecovertcomponents() => $_has(6);
  @$pb.TagNumber(7)
  void clearSharecovertcomponents() => clearField(7);
  @$pb.TagNumber(7)
  ShareCovertComponents ensureSharecovertcomponents() => $_ensure(6);

  @$pb.TagNumber(8)
  FusionResult get fusionresult => $_getN(7);
  @$pb.TagNumber(8)
  set fusionresult(FusionResult v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasFusionresult() => $_has(7);
  @$pb.TagNumber(8)
  void clearFusionresult() => clearField(8);
  @$pb.TagNumber(8)
  FusionResult ensureFusionresult() => $_ensure(7);

  @$pb.TagNumber(9)
  TheirProofsList get theirproofslist => $_getN(8);
  @$pb.TagNumber(9)
  set theirproofslist(TheirProofsList v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasTheirproofslist() => $_has(8);
  @$pb.TagNumber(9)
  void clearTheirproofslist() => clearField(9);
  @$pb.TagNumber(9)
  TheirProofsList ensureTheirproofslist() => $_ensure(8);

  @$pb.TagNumber(14)
  RestartRound get restartround => $_getN(9);
  @$pb.TagNumber(14)
  set restartround(RestartRound v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasRestartround() => $_has(9);
  @$pb.TagNumber(14)
  void clearRestartround() => clearField(14);
  @$pb.TagNumber(14)
  RestartRound ensureRestartround() => $_ensure(9);

  @$pb.TagNumber(15)
  Error get error => $_getN(10);
  @$pb.TagNumber(15)
  set error(Error v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasError() => $_has(10);
  @$pb.TagNumber(15)
  void clearError() => clearField(15);
  @$pb.TagNumber(15)
  Error ensureError() => $_ensure(10);
}

enum CovertMessage_Msg {
  component, 
  signature, 
  ping, 
  notSet
}

class CovertMessage extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CovertMessage_Msg> _CovertMessage_MsgByTag = {
    1 : CovertMessage_Msg.component,
    2 : CovertMessage_Msg.signature,
    3 : CovertMessage_Msg.ping,
    0 : CovertMessage_Msg.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CovertMessage', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<CovertComponent>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'component', subBuilder: CovertComponent.create)
    ..aOM<CovertTransactionSignature>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signature', subBuilder: CovertTransactionSignature.create)
    ..aOM<Ping>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ping', subBuilder: Ping.create)
  ;

  CovertMessage._() : super();
  factory CovertMessage({
    CovertComponent? component,
    CovertTransactionSignature? signature,
    Ping? ping,
  }) {
    final _result = create();
    if (component != null) {
      _result.component = component;
    }
    if (signature != null) {
      _result.signature = signature;
    }
    if (ping != null) {
      _result.ping = ping;
    }
    return _result;
  }
  factory CovertMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CovertMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CovertMessage clone() => CovertMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CovertMessage copyWith(void Function(CovertMessage) updates) => super.copyWith((message) => updates(message as CovertMessage)) as CovertMessage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CovertMessage create() => CovertMessage._();
  CovertMessage createEmptyInstance() => create();
  static $pb.PbList<CovertMessage> createRepeated() => $pb.PbList<CovertMessage>();
  @$core.pragma('dart2js:noInline')
  static CovertMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CovertMessage>(create);
  static CovertMessage? _defaultInstance;

  CovertMessage_Msg whichMsg() => _CovertMessage_MsgByTag[$_whichOneof(0)]!;
  void clearMsg() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  CovertComponent get component => $_getN(0);
  @$pb.TagNumber(1)
  set component(CovertComponent v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasComponent() => $_has(0);
  @$pb.TagNumber(1)
  void clearComponent() => clearField(1);
  @$pb.TagNumber(1)
  CovertComponent ensureComponent() => $_ensure(0);

  @$pb.TagNumber(2)
  CovertTransactionSignature get signature => $_getN(1);
  @$pb.TagNumber(2)
  set signature(CovertTransactionSignature v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => clearField(2);
  @$pb.TagNumber(2)
  CovertTransactionSignature ensureSignature() => $_ensure(1);

  @$pb.TagNumber(3)
  Ping get ping => $_getN(2);
  @$pb.TagNumber(3)
  set ping(Ping v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasPing() => $_has(2);
  @$pb.TagNumber(3)
  void clearPing() => clearField(3);
  @$pb.TagNumber(3)
  Ping ensurePing() => $_ensure(2);
}

enum CovertResponse_Msg {
  ok, 
  error, 
  notSet
}

class CovertResponse extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, CovertResponse_Msg> _CovertResponse_MsgByTag = {
    1 : CovertResponse_Msg.ok,
    15 : CovertResponse_Msg.error,
    0 : CovertResponse_Msg.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CovertResponse', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'fusion'), createEmptyInstance: create)
    ..oo(0, [1, 15])
    ..aOM<OK>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ok', subBuilder: OK.create)
    ..aOM<Error>(15, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'error', subBuilder: Error.create)
    ..hasRequiredFields = false
  ;

  CovertResponse._() : super();
  factory CovertResponse({
    OK? ok,
    Error? error,
  }) {
    final _result = create();
    if (ok != null) {
      _result.ok = ok;
    }
    if (error != null) {
      _result.error = error;
    }
    return _result;
  }
  factory CovertResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CovertResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CovertResponse clone() => CovertResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CovertResponse copyWith(void Function(CovertResponse) updates) => super.copyWith((message) => updates(message as CovertResponse)) as CovertResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CovertResponse create() => CovertResponse._();
  CovertResponse createEmptyInstance() => create();
  static $pb.PbList<CovertResponse> createRepeated() => $pb.PbList<CovertResponse>();
  @$core.pragma('dart2js:noInline')
  static CovertResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CovertResponse>(create);
  static CovertResponse? _defaultInstance;

  CovertResponse_Msg whichMsg() => _CovertResponse_MsgByTag[$_whichOneof(0)]!;
  void clearMsg() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OK get ok => $_getN(0);
  @$pb.TagNumber(1)
  set ok(OK v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => clearField(1);
  @$pb.TagNumber(1)
  OK ensureOk() => $_ensure(0);

  @$pb.TagNumber(15)
  Error get error => $_getN(1);
  @$pb.TagNumber(15)
  set error(Error v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(15)
  void clearError() => clearField(15);
  @$pb.TagNumber(15)
  Error ensureError() => $_ensure(1);
}

