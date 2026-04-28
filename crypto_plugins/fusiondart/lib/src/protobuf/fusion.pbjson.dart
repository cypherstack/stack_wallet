//
//  Generated code. Do not modify.
//  source: fusion.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use inputComponentDescriptor instead')
const InputComponent$json = {
  '1': 'InputComponent',
  '2': [
    {'1': 'prev_txid', '3': 1, '4': 2, '5': 12, '10': 'prevTxid'},
    {'1': 'prev_index', '3': 2, '4': 2, '5': 13, '10': 'prevIndex'},
    {'1': 'pubkey', '3': 3, '4': 2, '5': 12, '10': 'pubkey'},
    {'1': 'amount', '3': 4, '4': 2, '5': 4, '10': 'amount'},
  ],
};

/// Descriptor for `InputComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputComponentDescriptor = $convert.base64Decode(
    'Cg5JbnB1dENvbXBvbmVudBIbCglwcmV2X3R4aWQYASACKAxSCHByZXZUeGlkEh0KCnByZXZfaW'
    '5kZXgYAiACKA1SCXByZXZJbmRleBIWCgZwdWJrZXkYAyACKAxSBnB1YmtleRIWCgZhbW91bnQY'
    'BCACKARSBmFtb3VudA==');

@$core.Deprecated('Use outputComponentDescriptor instead')
const OutputComponent$json = {
  '1': 'OutputComponent',
  '2': [
    {'1': 'scriptpubkey', '3': 1, '4': 2, '5': 12, '10': 'scriptpubkey'},
    {'1': 'amount', '3': 2, '4': 2, '5': 4, '10': 'amount'},
  ],
};

/// Descriptor for `OutputComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputComponentDescriptor = $convert.base64Decode(
    'Cg9PdXRwdXRDb21wb25lbnQSIgoMc2NyaXB0cHVia2V5GAEgAigMUgxzY3JpcHRwdWJrZXkSFg'
    'oGYW1vdW50GAIgAigEUgZhbW91bnQ=');

@$core.Deprecated('Use blankComponentDescriptor instead')
const BlankComponent$json = {
  '1': 'BlankComponent',
};

/// Descriptor for `BlankComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blankComponentDescriptor = $convert.base64Decode(
    'Cg5CbGFua0NvbXBvbmVudA==');

@$core.Deprecated('Use componentDescriptor instead')
const Component$json = {
  '1': 'Component',
  '2': [
    {'1': 'salt_commitment', '3': 1, '4': 2, '5': 12, '10': 'saltCommitment'},
    {'1': 'input', '3': 2, '4': 1, '5': 11, '6': '.fusion.InputComponent', '9': 0, '10': 'input'},
    {'1': 'output', '3': 3, '4': 1, '5': 11, '6': '.fusion.OutputComponent', '9': 0, '10': 'output'},
    {'1': 'blank', '3': 4, '4': 1, '5': 11, '6': '.fusion.BlankComponent', '9': 0, '10': 'blank'},
  ],
  '8': [
    {'1': 'component'},
  ],
};

/// Descriptor for `Component`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List componentDescriptor = $convert.base64Decode(
    'CglDb21wb25lbnQSJwoPc2FsdF9jb21taXRtZW50GAEgAigMUg5zYWx0Q29tbWl0bWVudBIuCg'
    'VpbnB1dBgCIAEoCzIWLmZ1c2lvbi5JbnB1dENvbXBvbmVudEgAUgVpbnB1dBIxCgZvdXRwdXQY'
    'AyABKAsyFy5mdXNpb24uT3V0cHV0Q29tcG9uZW50SABSBm91dHB1dBIuCgVibGFuaxgEIAEoCz'
    'IWLmZ1c2lvbi5CbGFua0NvbXBvbmVudEgAUgVibGFua0ILCgljb21wb25lbnQ=');

@$core.Deprecated('Use initialCommitmentDescriptor instead')
const InitialCommitment$json = {
  '1': 'InitialCommitment',
  '2': [
    {'1': 'salted_component_hash', '3': 1, '4': 2, '5': 12, '10': 'saltedComponentHash'},
    {'1': 'amount_commitment', '3': 2, '4': 2, '5': 12, '10': 'amountCommitment'},
    {'1': 'communication_key', '3': 3, '4': 2, '5': 12, '10': 'communicationKey'},
  ],
};

/// Descriptor for `InitialCommitment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List initialCommitmentDescriptor = $convert.base64Decode(
    'ChFJbml0aWFsQ29tbWl0bWVudBIyChVzYWx0ZWRfY29tcG9uZW50X2hhc2gYASACKAxSE3NhbH'
    'RlZENvbXBvbmVudEhhc2gSKwoRYW1vdW50X2NvbW1pdG1lbnQYAiACKAxSEGFtb3VudENvbW1p'
    'dG1lbnQSKwoRY29tbXVuaWNhdGlvbl9rZXkYAyACKAxSEGNvbW11bmljYXRpb25LZXk=');

@$core.Deprecated('Use proofDescriptor instead')
const Proof$json = {
  '1': 'Proof',
  '2': [
    {'1': 'component_idx', '3': 1, '4': 2, '5': 7, '10': 'componentIdx'},
    {'1': 'salt', '3': 2, '4': 2, '5': 12, '10': 'salt'},
    {'1': 'pedersen_nonce', '3': 3, '4': 2, '5': 12, '10': 'pedersenNonce'},
  ],
};

/// Descriptor for `Proof`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List proofDescriptor = $convert.base64Decode(
    'CgVQcm9vZhIjCg1jb21wb25lbnRfaWR4GAEgAigHUgxjb21wb25lbnRJZHgSEgoEc2FsdBgCIA'
    'IoDFIEc2FsdBIlCg5wZWRlcnNlbl9ub25jZRgDIAIoDFINcGVkZXJzZW5Ob25jZQ==');

@$core.Deprecated('Use clientHelloDescriptor instead')
const ClientHello$json = {
  '1': 'ClientHello',
  '2': [
    {'1': 'version', '3': 1, '4': 2, '5': 12, '10': 'version'},
    {'1': 'genesis_hash', '3': 2, '4': 1, '5': 12, '10': 'genesisHash'},
  ],
};

/// Descriptor for `ClientHello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientHelloDescriptor = $convert.base64Decode(
    'CgtDbGllbnRIZWxsbxIYCgd2ZXJzaW9uGAEgAigMUgd2ZXJzaW9uEiEKDGdlbmVzaXNfaGFzaB'
    'gCIAEoDFILZ2VuZXNpc0hhc2g=');

@$core.Deprecated('Use serverHelloDescriptor instead')
const ServerHello$json = {
  '1': 'ServerHello',
  '2': [
    {'1': 'tiers', '3': 1, '4': 3, '5': 4, '10': 'tiers'},
    {'1': 'num_components', '3': 2, '4': 2, '5': 13, '10': 'numComponents'},
    {'1': 'component_feerate', '3': 4, '4': 2, '5': 4, '10': 'componentFeerate'},
    {'1': 'min_excess_fee', '3': 5, '4': 2, '5': 4, '10': 'minExcessFee'},
    {'1': 'max_excess_fee', '3': 6, '4': 2, '5': 4, '10': 'maxExcessFee'},
    {'1': 'donation_address', '3': 15, '4': 1, '5': 9, '10': 'donationAddress'},
  ],
};

/// Descriptor for `ServerHello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverHelloDescriptor = $convert.base64Decode(
    'CgtTZXJ2ZXJIZWxsbxIUCgV0aWVycxgBIAMoBFIFdGllcnMSJQoObnVtX2NvbXBvbmVudHMYAi'
    'ACKA1SDW51bUNvbXBvbmVudHMSKwoRY29tcG9uZW50X2ZlZXJhdGUYBCACKARSEGNvbXBvbmVu'
    'dEZlZXJhdGUSJAoObWluX2V4Y2Vzc19mZWUYBSACKARSDG1pbkV4Y2Vzc0ZlZRIkCg5tYXhfZX'
    'hjZXNzX2ZlZRgGIAIoBFIMbWF4RXhjZXNzRmVlEikKEGRvbmF0aW9uX2FkZHJlc3MYDyABKAlS'
    'D2RvbmF0aW9uQWRkcmVzcw==');

@$core.Deprecated('Use joinPoolsDescriptor instead')
const JoinPools$json = {
  '1': 'JoinPools',
  '2': [
    {'1': 'tiers', '3': 1, '4': 3, '5': 4, '10': 'tiers'},
    {'1': 'tags', '3': 2, '4': 3, '5': 11, '6': '.fusion.JoinPools.PoolTag', '10': 'tags'},
  ],
  '3': [JoinPools_PoolTag$json],
};

@$core.Deprecated('Use joinPoolsDescriptor instead')
const JoinPools_PoolTag$json = {
  '1': 'PoolTag',
  '2': [
    {'1': 'id', '3': 1, '4': 2, '5': 12, '10': 'id'},
    {'1': 'limit', '3': 2, '4': 2, '5': 13, '10': 'limit'},
    {'1': 'no_ip', '3': 3, '4': 1, '5': 8, '10': 'noIp'},
  ],
};

/// Descriptor for `JoinPools`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinPoolsDescriptor = $convert.base64Decode(
    'CglKb2luUG9vbHMSFAoFdGllcnMYASADKARSBXRpZXJzEi0KBHRhZ3MYAiADKAsyGS5mdXNpb2'
    '4uSm9pblBvb2xzLlBvb2xUYWdSBHRhZ3MaRAoHUG9vbFRhZxIOCgJpZBgBIAIoDFICaWQSFAoF'
    'bGltaXQYAiACKA1SBWxpbWl0EhMKBW5vX2lwGAMgASgIUgRub0lw');

@$core.Deprecated('Use tierStatusUpdateDescriptor instead')
const TierStatusUpdate$json = {
  '1': 'TierStatusUpdate',
  '2': [
    {'1': 'statuses', '3': 1, '4': 3, '5': 11, '6': '.fusion.TierStatusUpdate.StatusesEntry', '10': 'statuses'},
  ],
  '3': [TierStatusUpdate_TierStatus$json, TierStatusUpdate_StatusesEntry$json],
};

@$core.Deprecated('Use tierStatusUpdateDescriptor instead')
const TierStatusUpdate_TierStatus$json = {
  '1': 'TierStatus',
  '2': [
    {'1': 'players', '3': 1, '4': 1, '5': 13, '10': 'players'},
    {'1': 'min_players', '3': 2, '4': 1, '5': 13, '10': 'minPlayers'},
    {'1': 'max_players', '3': 3, '4': 1, '5': 13, '10': 'maxPlayers'},
    {'1': 'time_remaining', '3': 4, '4': 1, '5': 13, '10': 'timeRemaining'},
  ],
};

@$core.Deprecated('Use tierStatusUpdateDescriptor instead')
const TierStatusUpdate_StatusesEntry$json = {
  '1': 'StatusesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 4, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.fusion.TierStatusUpdate.TierStatus', '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `TierStatusUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tierStatusUpdateDescriptor = $convert.base64Decode(
    'ChBUaWVyU3RhdHVzVXBkYXRlEkIKCHN0YXR1c2VzGAEgAygLMiYuZnVzaW9uLlRpZXJTdGF0dX'
    'NVcGRhdGUuU3RhdHVzZXNFbnRyeVIIc3RhdHVzZXMajwEKClRpZXJTdGF0dXMSGAoHcGxheWVy'
    'cxgBIAEoDVIHcGxheWVycxIfCgttaW5fcGxheWVycxgCIAEoDVIKbWluUGxheWVycxIfCgttYX'
    'hfcGxheWVycxgDIAEoDVIKbWF4UGxheWVycxIlCg50aW1lX3JlbWFpbmluZxgEIAEoDVINdGlt'
    'ZVJlbWFpbmluZxpgCg1TdGF0dXNlc0VudHJ5EhAKA2tleRgBIAEoBFIDa2V5EjkKBXZhbHVlGA'
    'IgASgLMiMuZnVzaW9uLlRpZXJTdGF0dXNVcGRhdGUuVGllclN0YXR1c1IFdmFsdWU6AjgB');

@$core.Deprecated('Use fusionBeginDescriptor instead')
const FusionBegin$json = {
  '1': 'FusionBegin',
  '2': [
    {'1': 'tier', '3': 1, '4': 2, '5': 4, '10': 'tier'},
    {'1': 'covert_domain', '3': 2, '4': 2, '5': 12, '10': 'covertDomain'},
    {'1': 'covert_port', '3': 3, '4': 2, '5': 13, '10': 'covertPort'},
    {'1': 'covert_ssl', '3': 4, '4': 1, '5': 8, '10': 'covertSsl'},
    {'1': 'server_time', '3': 5, '4': 2, '5': 6, '10': 'serverTime'},
  ],
};

/// Descriptor for `FusionBegin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fusionBeginDescriptor = $convert.base64Decode(
    'CgtGdXNpb25CZWdpbhISCgR0aWVyGAEgAigEUgR0aWVyEiMKDWNvdmVydF9kb21haW4YAiACKA'
    'xSDGNvdmVydERvbWFpbhIfCgtjb3ZlcnRfcG9ydBgDIAIoDVIKY292ZXJ0UG9ydBIdCgpjb3Zl'
    'cnRfc3NsGAQgASgIUgljb3ZlcnRTc2wSHwoLc2VydmVyX3RpbWUYBSACKAZSCnNlcnZlclRpbW'
    'U=');

@$core.Deprecated('Use startRoundDescriptor instead')
const StartRound$json = {
  '1': 'StartRound',
  '2': [
    {'1': 'round_pubkey', '3': 1, '4': 2, '5': 12, '10': 'roundPubkey'},
    {'1': 'blind_nonce_points', '3': 2, '4': 3, '5': 12, '10': 'blindNoncePoints'},
    {'1': 'server_time', '3': 5, '4': 2, '5': 6, '10': 'serverTime'},
  ],
};

/// Descriptor for `StartRound`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startRoundDescriptor = $convert.base64Decode(
    'CgpTdGFydFJvdW5kEiEKDHJvdW5kX3B1YmtleRgBIAIoDFILcm91bmRQdWJrZXkSLAoSYmxpbm'
    'Rfbm9uY2VfcG9pbnRzGAIgAygMUhBibGluZE5vbmNlUG9pbnRzEh8KC3NlcnZlcl90aW1lGAUg'
    'AigGUgpzZXJ2ZXJUaW1l');

@$core.Deprecated('Use playerCommitDescriptor instead')
const PlayerCommit$json = {
  '1': 'PlayerCommit',
  '2': [
    {'1': 'initial_commitments', '3': 1, '4': 3, '5': 12, '10': 'initialCommitments'},
    {'1': 'excess_fee', '3': 2, '4': 2, '5': 4, '10': 'excessFee'},
    {'1': 'pedersen_total_nonce', '3': 3, '4': 2, '5': 12, '10': 'pedersenTotalNonce'},
    {'1': 'random_number_commitment', '3': 4, '4': 2, '5': 12, '10': 'randomNumberCommitment'},
    {'1': 'blind_sig_requests', '3': 5, '4': 3, '5': 12, '10': 'blindSigRequests'},
  ],
};

/// Descriptor for `PlayerCommit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playerCommitDescriptor = $convert.base64Decode(
    'CgxQbGF5ZXJDb21taXQSLwoTaW5pdGlhbF9jb21taXRtZW50cxgBIAMoDFISaW5pdGlhbENvbW'
    '1pdG1lbnRzEh0KCmV4Y2Vzc19mZWUYAiACKARSCWV4Y2Vzc0ZlZRIwChRwZWRlcnNlbl90b3Rh'
    'bF9ub25jZRgDIAIoDFIScGVkZXJzZW5Ub3RhbE5vbmNlEjgKGHJhbmRvbV9udW1iZXJfY29tbW'
    'l0bWVudBgEIAIoDFIWcmFuZG9tTnVtYmVyQ29tbWl0bWVudBIsChJibGluZF9zaWdfcmVxdWVz'
    'dHMYBSADKAxSEGJsaW5kU2lnUmVxdWVzdHM=');

@$core.Deprecated('Use blindSigResponsesDescriptor instead')
const BlindSigResponses$json = {
  '1': 'BlindSigResponses',
  '2': [
    {'1': 'scalars', '3': 1, '4': 3, '5': 12, '10': 'scalars'},
  ],
};

/// Descriptor for `BlindSigResponses`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blindSigResponsesDescriptor = $convert.base64Decode(
    'ChFCbGluZFNpZ1Jlc3BvbnNlcxIYCgdzY2FsYXJzGAEgAygMUgdzY2FsYXJz');

@$core.Deprecated('Use allCommitmentsDescriptor instead')
const AllCommitments$json = {
  '1': 'AllCommitments',
  '2': [
    {'1': 'initial_commitments', '3': 1, '4': 3, '5': 12, '10': 'initialCommitments'},
  ],
};

/// Descriptor for `AllCommitments`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List allCommitmentsDescriptor = $convert.base64Decode(
    'Cg5BbGxDb21taXRtZW50cxIvChNpbml0aWFsX2NvbW1pdG1lbnRzGAEgAygMUhJpbml0aWFsQ2'
    '9tbWl0bWVudHM=');

@$core.Deprecated('Use covertComponentDescriptor instead')
const CovertComponent$json = {
  '1': 'CovertComponent',
  '2': [
    {'1': 'round_pubkey', '3': 1, '4': 1, '5': 12, '10': 'roundPubkey'},
    {'1': 'signature', '3': 2, '4': 2, '5': 12, '10': 'signature'},
    {'1': 'component', '3': 3, '4': 2, '5': 12, '10': 'component'},
  ],
};

/// Descriptor for `CovertComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List covertComponentDescriptor = $convert.base64Decode(
    'Cg9Db3ZlcnRDb21wb25lbnQSIQoMcm91bmRfcHVia2V5GAEgASgMUgtyb3VuZFB1YmtleRIcCg'
    'lzaWduYXR1cmUYAiACKAxSCXNpZ25hdHVyZRIcCgljb21wb25lbnQYAyACKAxSCWNvbXBvbmVu'
    'dA==');

@$core.Deprecated('Use shareCovertComponentsDescriptor instead')
const ShareCovertComponents$json = {
  '1': 'ShareCovertComponents',
  '2': [
    {'1': 'components', '3': 4, '4': 3, '5': 12, '10': 'components'},
    {'1': 'skip_signatures', '3': 5, '4': 1, '5': 8, '10': 'skipSignatures'},
    {'1': 'session_hash', '3': 6, '4': 1, '5': 12, '10': 'sessionHash'},
  ],
};

/// Descriptor for `ShareCovertComponents`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shareCovertComponentsDescriptor = $convert.base64Decode(
    'ChVTaGFyZUNvdmVydENvbXBvbmVudHMSHgoKY29tcG9uZW50cxgEIAMoDFIKY29tcG9uZW50cx'
    'InCg9za2lwX3NpZ25hdHVyZXMYBSABKAhSDnNraXBTaWduYXR1cmVzEiEKDHNlc3Npb25faGFz'
    'aBgGIAEoDFILc2Vzc2lvbkhhc2g=');

@$core.Deprecated('Use covertTransactionSignatureDescriptor instead')
const CovertTransactionSignature$json = {
  '1': 'CovertTransactionSignature',
  '2': [
    {'1': 'round_pubkey', '3': 1, '4': 1, '5': 12, '10': 'roundPubkey'},
    {'1': 'which_input', '3': 2, '4': 2, '5': 13, '10': 'whichInput'},
    {'1': 'txsignature', '3': 3, '4': 2, '5': 12, '10': 'txsignature'},
  ],
};

/// Descriptor for `CovertTransactionSignature`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List covertTransactionSignatureDescriptor = $convert.base64Decode(
    'ChpDb3ZlcnRUcmFuc2FjdGlvblNpZ25hdHVyZRIhCgxyb3VuZF9wdWJrZXkYASABKAxSC3JvdW'
    '5kUHVia2V5Eh8KC3doaWNoX2lucHV0GAIgAigNUgp3aGljaElucHV0EiAKC3R4c2lnbmF0dXJl'
    'GAMgAigMUgt0eHNpZ25hdHVyZQ==');

@$core.Deprecated('Use fusionResultDescriptor instead')
const FusionResult$json = {
  '1': 'FusionResult',
  '2': [
    {'1': 'ok', '3': 1, '4': 2, '5': 8, '10': 'ok'},
    {'1': 'txsignatures', '3': 2, '4': 3, '5': 12, '10': 'txsignatures'},
    {'1': 'bad_components', '3': 3, '4': 3, '5': 13, '10': 'badComponents'},
  ],
};

/// Descriptor for `FusionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fusionResultDescriptor = $convert.base64Decode(
    'CgxGdXNpb25SZXN1bHQSDgoCb2sYASACKAhSAm9rEiIKDHR4c2lnbmF0dXJlcxgCIAMoDFIMdH'
    'hzaWduYXR1cmVzEiUKDmJhZF9jb21wb25lbnRzGAMgAygNUg1iYWRDb21wb25lbnRz');

@$core.Deprecated('Use myProofsListDescriptor instead')
const MyProofsList$json = {
  '1': 'MyProofsList',
  '2': [
    {'1': 'encrypted_proofs', '3': 1, '4': 3, '5': 12, '10': 'encryptedProofs'},
    {'1': 'random_number', '3': 2, '4': 2, '5': 12, '10': 'randomNumber'},
  ],
};

/// Descriptor for `MyProofsList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List myProofsListDescriptor = $convert.base64Decode(
    'CgxNeVByb29mc0xpc3QSKQoQZW5jcnlwdGVkX3Byb29mcxgBIAMoDFIPZW5jcnlwdGVkUHJvb2'
    'ZzEiMKDXJhbmRvbV9udW1iZXIYAiACKAxSDHJhbmRvbU51bWJlcg==');

@$core.Deprecated('Use theirProofsListDescriptor instead')
const TheirProofsList$json = {
  '1': 'TheirProofsList',
  '2': [
    {'1': 'proofs', '3': 1, '4': 3, '5': 11, '6': '.fusion.TheirProofsList.RelayedProof', '10': 'proofs'},
  ],
  '3': [TheirProofsList_RelayedProof$json],
};

@$core.Deprecated('Use theirProofsListDescriptor instead')
const TheirProofsList_RelayedProof$json = {
  '1': 'RelayedProof',
  '2': [
    {'1': 'encrypted_proof', '3': 1, '4': 2, '5': 12, '10': 'encryptedProof'},
    {'1': 'src_commitment_idx', '3': 2, '4': 2, '5': 13, '10': 'srcCommitmentIdx'},
    {'1': 'dst_key_idx', '3': 3, '4': 2, '5': 13, '10': 'dstKeyIdx'},
  ],
};

/// Descriptor for `TheirProofsList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List theirProofsListDescriptor = $convert.base64Decode(
    'Cg9UaGVpclByb29mc0xpc3QSPAoGcHJvb2ZzGAEgAygLMiQuZnVzaW9uLlRoZWlyUHJvb2ZzTG'
    'lzdC5SZWxheWVkUHJvb2ZSBnByb29mcxqFAQoMUmVsYXllZFByb29mEicKD2VuY3J5cHRlZF9w'
    'cm9vZhgBIAIoDFIOZW5jcnlwdGVkUHJvb2YSLAoSc3JjX2NvbW1pdG1lbnRfaWR4GAIgAigNUh'
    'BzcmNDb21taXRtZW50SWR4Eh4KC2RzdF9rZXlfaWR4GAMgAigNUglkc3RLZXlJZHg=');

@$core.Deprecated('Use blamesDescriptor instead')
const Blames$json = {
  '1': 'Blames',
  '2': [
    {'1': 'blames', '3': 1, '4': 3, '5': 11, '6': '.fusion.Blames.BlameProof', '10': 'blames'},
  ],
  '3': [Blames_BlameProof$json],
};

@$core.Deprecated('Use blamesDescriptor instead')
const Blames_BlameProof$json = {
  '1': 'BlameProof',
  '2': [
    {'1': 'which_proof', '3': 1, '4': 2, '5': 13, '10': 'whichProof'},
    {'1': 'session_key', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'sessionKey'},
    {'1': 'privkey', '3': 3, '4': 1, '5': 12, '9': 0, '10': 'privkey'},
    {'1': 'need_lookup_blockchain', '3': 4, '4': 1, '5': 8, '10': 'needLookupBlockchain'},
    {'1': 'blame_reason', '3': 5, '4': 1, '5': 9, '10': 'blameReason'},
  ],
  '8': [
    {'1': 'decrypter'},
  ],
};

/// Descriptor for `Blames`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blamesDescriptor = $convert.base64Decode(
    'CgZCbGFtZXMSMQoGYmxhbWVzGAEgAygLMhkuZnVzaW9uLkJsYW1lcy5CbGFtZVByb29mUgZibG'
    'FtZXMa0gEKCkJsYW1lUHJvb2YSHwoLd2hpY2hfcHJvb2YYASACKA1SCndoaWNoUHJvb2YSIQoL'
    'c2Vzc2lvbl9rZXkYAiABKAxIAFIKc2Vzc2lvbktleRIaCgdwcml2a2V5GAMgASgMSABSB3ByaX'
    'ZrZXkSNAoWbmVlZF9sb29rdXBfYmxvY2tjaGFpbhgEIAEoCFIUbmVlZExvb2t1cEJsb2NrY2hh'
    'aW4SIQoMYmxhbWVfcmVhc29uGAUgASgJUgtibGFtZVJlYXNvbkILCglkZWNyeXB0ZXI=');

@$core.Deprecated('Use restartRoundDescriptor instead')
const RestartRound$json = {
  '1': 'RestartRound',
};

/// Descriptor for `RestartRound`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restartRoundDescriptor = $convert.base64Decode(
    'CgxSZXN0YXJ0Um91bmQ=');

@$core.Deprecated('Use errorDescriptor instead')
const Error$json = {
  '1': 'Error',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `Error`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List errorDescriptor = $convert.base64Decode(
    'CgVFcnJvchIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use pingDescriptor instead')
const Ping$json = {
  '1': 'Ping',
};

/// Descriptor for `Ping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingDescriptor = $convert.base64Decode(
    'CgRQaW5n');

@$core.Deprecated('Use oKDescriptor instead')
const OK$json = {
  '1': 'OK',
};

/// Descriptor for `OK`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List oKDescriptor = $convert.base64Decode(
    'CgJPSw==');

@$core.Deprecated('Use clientMessageDescriptor instead')
const ClientMessage$json = {
  '1': 'ClientMessage',
  '2': [
    {'1': 'clienthello', '3': 1, '4': 1, '5': 11, '6': '.fusion.ClientHello', '9': 0, '10': 'clienthello'},
    {'1': 'joinpools', '3': 2, '4': 1, '5': 11, '6': '.fusion.JoinPools', '9': 0, '10': 'joinpools'},
    {'1': 'playercommit', '3': 3, '4': 1, '5': 11, '6': '.fusion.PlayerCommit', '9': 0, '10': 'playercommit'},
    {'1': 'myproofslist', '3': 5, '4': 1, '5': 11, '6': '.fusion.MyProofsList', '9': 0, '10': 'myproofslist'},
    {'1': 'blames', '3': 6, '4': 1, '5': 11, '6': '.fusion.Blames', '9': 0, '10': 'blames'},
  ],
  '8': [
    {'1': 'msg'},
  ],
};

/// Descriptor for `ClientMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientMessageDescriptor = $convert.base64Decode(
    'Cg1DbGllbnRNZXNzYWdlEjcKC2NsaWVudGhlbGxvGAEgASgLMhMuZnVzaW9uLkNsaWVudEhlbG'
    'xvSABSC2NsaWVudGhlbGxvEjEKCWpvaW5wb29scxgCIAEoCzIRLmZ1c2lvbi5Kb2luUG9vbHNI'
    'AFIJam9pbnBvb2xzEjoKDHBsYXllcmNvbW1pdBgDIAEoCzIULmZ1c2lvbi5QbGF5ZXJDb21taX'
    'RIAFIMcGxheWVyY29tbWl0EjoKDG15cHJvb2ZzbGlzdBgFIAEoCzIULmZ1c2lvbi5NeVByb29m'
    'c0xpc3RIAFIMbXlwcm9vZnNsaXN0EigKBmJsYW1lcxgGIAEoCzIOLmZ1c2lvbi5CbGFtZXNIAF'
    'IGYmxhbWVzQgUKA21zZw==');

@$core.Deprecated('Use serverMessageDescriptor instead')
const ServerMessage$json = {
  '1': 'ServerMessage',
  '2': [
    {'1': 'serverhello', '3': 1, '4': 1, '5': 11, '6': '.fusion.ServerHello', '9': 0, '10': 'serverhello'},
    {'1': 'tierstatusupdate', '3': 2, '4': 1, '5': 11, '6': '.fusion.TierStatusUpdate', '9': 0, '10': 'tierstatusupdate'},
    {'1': 'fusionbegin', '3': 3, '4': 1, '5': 11, '6': '.fusion.FusionBegin', '9': 0, '10': 'fusionbegin'},
    {'1': 'startround', '3': 4, '4': 1, '5': 11, '6': '.fusion.StartRound', '9': 0, '10': 'startround'},
    {'1': 'blindsigresponses', '3': 5, '4': 1, '5': 11, '6': '.fusion.BlindSigResponses', '9': 0, '10': 'blindsigresponses'},
    {'1': 'allcommitments', '3': 6, '4': 1, '5': 11, '6': '.fusion.AllCommitments', '9': 0, '10': 'allcommitments'},
    {'1': 'sharecovertcomponents', '3': 7, '4': 1, '5': 11, '6': '.fusion.ShareCovertComponents', '9': 0, '10': 'sharecovertcomponents'},
    {'1': 'fusionresult', '3': 8, '4': 1, '5': 11, '6': '.fusion.FusionResult', '9': 0, '10': 'fusionresult'},
    {'1': 'theirproofslist', '3': 9, '4': 1, '5': 11, '6': '.fusion.TheirProofsList', '9': 0, '10': 'theirproofslist'},
    {'1': 'restartround', '3': 14, '4': 1, '5': 11, '6': '.fusion.RestartRound', '9': 0, '10': 'restartround'},
    {'1': 'error', '3': 15, '4': 1, '5': 11, '6': '.fusion.Error', '9': 0, '10': 'error'},
  ],
  '8': [
    {'1': 'msg'},
  ],
};

/// Descriptor for `ServerMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverMessageDescriptor = $convert.base64Decode(
    'Cg1TZXJ2ZXJNZXNzYWdlEjcKC3NlcnZlcmhlbGxvGAEgASgLMhMuZnVzaW9uLlNlcnZlckhlbG'
    'xvSABSC3NlcnZlcmhlbGxvEkYKEHRpZXJzdGF0dXN1cGRhdGUYAiABKAsyGC5mdXNpb24uVGll'
    'clN0YXR1c1VwZGF0ZUgAUhB0aWVyc3RhdHVzdXBkYXRlEjcKC2Z1c2lvbmJlZ2luGAMgASgLMh'
    'MuZnVzaW9uLkZ1c2lvbkJlZ2luSABSC2Z1c2lvbmJlZ2luEjQKCnN0YXJ0cm91bmQYBCABKAsy'
    'Ei5mdXNpb24uU3RhcnRSb3VuZEgAUgpzdGFydHJvdW5kEkkKEWJsaW5kc2lncmVzcG9uc2VzGA'
    'UgASgLMhkuZnVzaW9uLkJsaW5kU2lnUmVzcG9uc2VzSABSEWJsaW5kc2lncmVzcG9uc2VzEkAK'
    'DmFsbGNvbW1pdG1lbnRzGAYgASgLMhYuZnVzaW9uLkFsbENvbW1pdG1lbnRzSABSDmFsbGNvbW'
    '1pdG1lbnRzElUKFXNoYXJlY292ZXJ0Y29tcG9uZW50cxgHIAEoCzIdLmZ1c2lvbi5TaGFyZUNv'
    'dmVydENvbXBvbmVudHNIAFIVc2hhcmVjb3ZlcnRjb21wb25lbnRzEjoKDGZ1c2lvbnJlc3VsdB'
    'gIIAEoCzIULmZ1c2lvbi5GdXNpb25SZXN1bHRIAFIMZnVzaW9ucmVzdWx0EkMKD3RoZWlycHJv'
    'b2ZzbGlzdBgJIAEoCzIXLmZ1c2lvbi5UaGVpclByb29mc0xpc3RIAFIPdGhlaXJwcm9vZnNsaX'
    'N0EjoKDHJlc3RhcnRyb3VuZBgOIAEoCzIULmZ1c2lvbi5SZXN0YXJ0Um91bmRIAFIMcmVzdGFy'
    'dHJvdW5kEiUKBWVycm9yGA8gASgLMg0uZnVzaW9uLkVycm9ySABSBWVycm9yQgUKA21zZw==');

@$core.Deprecated('Use covertMessageDescriptor instead')
const CovertMessage$json = {
  '1': 'CovertMessage',
  '2': [
    {'1': 'component', '3': 1, '4': 1, '5': 11, '6': '.fusion.CovertComponent', '9': 0, '10': 'component'},
    {'1': 'signature', '3': 2, '4': 1, '5': 11, '6': '.fusion.CovertTransactionSignature', '9': 0, '10': 'signature'},
    {'1': 'ping', '3': 3, '4': 1, '5': 11, '6': '.fusion.Ping', '9': 0, '10': 'ping'},
  ],
  '8': [
    {'1': 'msg'},
  ],
};

/// Descriptor for `CovertMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List covertMessageDescriptor = $convert.base64Decode(
    'Cg1Db3ZlcnRNZXNzYWdlEjcKCWNvbXBvbmVudBgBIAEoCzIXLmZ1c2lvbi5Db3ZlcnRDb21wb2'
    '5lbnRIAFIJY29tcG9uZW50EkIKCXNpZ25hdHVyZRgCIAEoCzIiLmZ1c2lvbi5Db3ZlcnRUcmFu'
    'c2FjdGlvblNpZ25hdHVyZUgAUglzaWduYXR1cmUSIgoEcGluZxgDIAEoCzIMLmZ1c2lvbi5QaW'
    '5nSABSBHBpbmdCBQoDbXNn');

@$core.Deprecated('Use covertResponseDescriptor instead')
const CovertResponse$json = {
  '1': 'CovertResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 11, '6': '.fusion.OK', '9': 0, '10': 'ok'},
    {'1': 'error', '3': 15, '4': 1, '5': 11, '6': '.fusion.Error', '9': 0, '10': 'error'},
  ],
  '8': [
    {'1': 'msg'},
  ],
};

/// Descriptor for `CovertResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List covertResponseDescriptor = $convert.base64Decode(
    'Cg5Db3ZlcnRSZXNwb25zZRIcCgJvaxgBIAEoCzIKLmZ1c2lvbi5PS0gAUgJvaxIlCgVlcnJvch'
    'gPIAEoCzINLmZ1c2lvbi5FcnJvckgAUgVlcnJvckIFCgNtc2c=');

