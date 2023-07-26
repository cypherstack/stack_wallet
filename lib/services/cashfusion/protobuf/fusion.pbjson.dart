///
//  Generated code. Do not modify.
//  source: fusion.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use inputComponentDescriptor instead')
const InputComponent$json = const {
  '1': 'InputComponent',
  '2': const [
    const {'1': 'prev_txid', '3': 1, '4': 2, '5': 12, '10': 'prevTxid'},
    const {'1': 'prev_index', '3': 2, '4': 2, '5': 13, '10': 'prevIndex'},
    const {'1': 'pubkey', '3': 3, '4': 2, '5': 12, '10': 'pubkey'},
    const {'1': 'amount', '3': 4, '4': 2, '5': 4, '10': 'amount'},
  ],
};

/// Descriptor for `InputComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputComponentDescriptor = $convert.base64Decode('Cg5JbnB1dENvbXBvbmVudBIbCglwcmV2X3R4aWQYASACKAxSCHByZXZUeGlkEh0KCnByZXZfaW5kZXgYAiACKA1SCXByZXZJbmRleBIWCgZwdWJrZXkYAyACKAxSBnB1YmtleRIWCgZhbW91bnQYBCACKARSBmFtb3VudA==');
@$core.Deprecated('Use outputComponentDescriptor instead')
const OutputComponent$json = const {
  '1': 'OutputComponent',
  '2': const [
    const {'1': 'scriptpubkey', '3': 1, '4': 2, '5': 12, '10': 'scriptpubkey'},
    const {'1': 'amount', '3': 2, '4': 2, '5': 4, '10': 'amount'},
  ],
};

/// Descriptor for `OutputComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputComponentDescriptor = $convert.base64Decode('Cg9PdXRwdXRDb21wb25lbnQSIgoMc2NyaXB0cHVia2V5GAEgAigMUgxzY3JpcHRwdWJrZXkSFgoGYW1vdW50GAIgAigEUgZhbW91bnQ=');
@$core.Deprecated('Use blankComponentDescriptor instead')
const BlankComponent$json = const {
  '1': 'BlankComponent',
};

/// Descriptor for `BlankComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blankComponentDescriptor = $convert.base64Decode('Cg5CbGFua0NvbXBvbmVudA==');
@$core.Deprecated('Use componentDescriptor instead')
const Component$json = const {
  '1': 'Component',
  '2': const [
    const {'1': 'salt_commitment', '3': 1, '4': 2, '5': 12, '10': 'saltCommitment'},
    const {'1': 'input', '3': 2, '4': 1, '5': 11, '6': '.fusion.InputComponent', '9': 0, '10': 'input'},
    const {'1': 'output', '3': 3, '4': 1, '5': 11, '6': '.fusion.OutputComponent', '9': 0, '10': 'output'},
    const {'1': 'blank', '3': 4, '4': 1, '5': 11, '6': '.fusion.BlankComponent', '9': 0, '10': 'blank'},
  ],
  '8': const [
    const {'1': 'component'},
  ],
};

/// Descriptor for `Component`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List componentDescriptor = $convert.base64Decode('CglDb21wb25lbnQSJwoPc2FsdF9jb21taXRtZW50GAEgAigMUg5zYWx0Q29tbWl0bWVudBIuCgVpbnB1dBgCIAEoCzIWLmZ1c2lvbi5JbnB1dENvbXBvbmVudEgAUgVpbnB1dBIxCgZvdXRwdXQYAyABKAsyFy5mdXNpb24uT3V0cHV0Q29tcG9uZW50SABSBm91dHB1dBIuCgVibGFuaxgEIAEoCzIWLmZ1c2lvbi5CbGFua0NvbXBvbmVudEgAUgVibGFua0ILCgljb21wb25lbnQ=');
@$core.Deprecated('Use initialCommitmentDescriptor instead')
const InitialCommitment$json = const {
  '1': 'InitialCommitment',
  '2': const [
    const {'1': 'salted_component_hash', '3': 1, '4': 2, '5': 12, '10': 'saltedComponentHash'},
    const {'1': 'amount_commitment', '3': 2, '4': 2, '5': 12, '10': 'amountCommitment'},
    const {'1': 'communication_key', '3': 3, '4': 2, '5': 12, '10': 'communicationKey'},
  ],
};

/// Descriptor for `InitialCommitment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List initialCommitmentDescriptor = $convert.base64Decode('ChFJbml0aWFsQ29tbWl0bWVudBIyChVzYWx0ZWRfY29tcG9uZW50X2hhc2gYASACKAxSE3NhbHRlZENvbXBvbmVudEhhc2gSKwoRYW1vdW50X2NvbW1pdG1lbnQYAiACKAxSEGFtb3VudENvbW1pdG1lbnQSKwoRY29tbXVuaWNhdGlvbl9rZXkYAyACKAxSEGNvbW11bmljYXRpb25LZXk=');
@$core.Deprecated('Use proofDescriptor instead')
const Proof$json = const {
  '1': 'Proof',
  '2': const [
    const {'1': 'component_idx', '3': 1, '4': 2, '5': 7, '10': 'componentIdx'},
    const {'1': 'salt', '3': 2, '4': 2, '5': 12, '10': 'salt'},
    const {'1': 'pedersen_nonce', '3': 3, '4': 2, '5': 12, '10': 'pedersenNonce'},
  ],
};

/// Descriptor for `Proof`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List proofDescriptor = $convert.base64Decode('CgVQcm9vZhIjCg1jb21wb25lbnRfaWR4GAEgAigHUgxjb21wb25lbnRJZHgSEgoEc2FsdBgCIAIoDFIEc2FsdBIlCg5wZWRlcnNlbl9ub25jZRgDIAIoDFINcGVkZXJzZW5Ob25jZQ==');
@$core.Deprecated('Use clientHelloDescriptor instead')
const ClientHello$json = const {
  '1': 'ClientHello',
  '2': const [
    const {'1': 'version', '3': 1, '4': 2, '5': 12, '10': 'version'},
    const {'1': 'genesis_hash', '3': 2, '4': 1, '5': 12, '10': 'genesisHash'},
  ],
};

/// Descriptor for `ClientHello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientHelloDescriptor = $convert.base64Decode('CgtDbGllbnRIZWxsbxIYCgd2ZXJzaW9uGAEgAigMUgd2ZXJzaW9uEiEKDGdlbmVzaXNfaGFzaBgCIAEoDFILZ2VuZXNpc0hhc2g=');
@$core.Deprecated('Use serverHelloDescriptor instead')
const ServerHello$json = const {
  '1': 'ServerHello',
  '2': const [
    const {'1': 'tiers', '3': 1, '4': 3, '5': 4, '10': 'tiers'},
    const {'1': 'num_components', '3': 2, '4': 2, '5': 13, '10': 'numComponents'},
    const {'1': 'component_feerate', '3': 4, '4': 2, '5': 4, '10': 'componentFeerate'},
    const {'1': 'min_excess_fee', '3': 5, '4': 2, '5': 4, '10': 'minExcessFee'},
    const {'1': 'max_excess_fee', '3': 6, '4': 2, '5': 4, '10': 'maxExcessFee'},
    const {'1': 'donation_address', '3': 15, '4': 1, '5': 9, '10': 'donationAddress'},
  ],
};

/// Descriptor for `ServerHello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverHelloDescriptor = $convert.base64Decode('CgtTZXJ2ZXJIZWxsbxIUCgV0aWVycxgBIAMoBFIFdGllcnMSJQoObnVtX2NvbXBvbmVudHMYAiACKA1SDW51bUNvbXBvbmVudHMSKwoRY29tcG9uZW50X2ZlZXJhdGUYBCACKARSEGNvbXBvbmVudEZlZXJhdGUSJAoObWluX2V4Y2Vzc19mZWUYBSACKARSDG1pbkV4Y2Vzc0ZlZRIkCg5tYXhfZXhjZXNzX2ZlZRgGIAIoBFIMbWF4RXhjZXNzRmVlEikKEGRvbmF0aW9uX2FkZHJlc3MYDyABKAlSD2RvbmF0aW9uQWRkcmVzcw==');
@$core.Deprecated('Use joinPoolsDescriptor instead')
const JoinPools$json = const {
  '1': 'JoinPools',
  '2': const [
    const {'1': 'tiers', '3': 1, '4': 3, '5': 4, '10': 'tiers'},
    const {'1': 'tags', '3': 2, '4': 3, '5': 11, '6': '.fusion.JoinPools.PoolTag', '10': 'tags'},
  ],
  '3': const [JoinPools_PoolTag$json],
};

@$core.Deprecated('Use joinPoolsDescriptor instead')
const JoinPools_PoolTag$json = const {
  '1': 'PoolTag',
  '2': const [
    const {'1': 'id', '3': 1, '4': 2, '5': 12, '10': 'id'},
    const {'1': 'limit', '3': 2, '4': 2, '5': 13, '10': 'limit'},
    const {'1': 'no_ip', '3': 3, '4': 1, '5': 8, '10': 'noIp'},
  ],
};

/// Descriptor for `JoinPools`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinPoolsDescriptor = $convert.base64Decode('CglKb2luUG9vbHMSFAoFdGllcnMYASADKARSBXRpZXJzEi0KBHRhZ3MYAiADKAsyGS5mdXNpb24uSm9pblBvb2xzLlBvb2xUYWdSBHRhZ3MaRAoHUG9vbFRhZxIOCgJpZBgBIAIoDFICaWQSFAoFbGltaXQYAiACKA1SBWxpbWl0EhMKBW5vX2lwGAMgASgIUgRub0lw');
@$core.Deprecated('Use tierStatusUpdateDescriptor instead')
const TierStatusUpdate$json = const {
  '1': 'TierStatusUpdate',
  '2': const [
    const {'1': 'statuses', '3': 1, '4': 3, '5': 11, '6': '.fusion.TierStatusUpdate.StatusesEntry', '10': 'statuses'},
  ],
  '3': const [TierStatusUpdate_TierStatus$json, TierStatusUpdate_StatusesEntry$json],
};

@$core.Deprecated('Use tierStatusUpdateDescriptor instead')
const TierStatusUpdate_TierStatus$json = const {
  '1': 'TierStatus',
  '2': const [
    const {'1': 'players', '3': 1, '4': 1, '5': 13, '10': 'players'},
    const {'1': 'min_players', '3': 2, '4': 1, '5': 13, '10': 'minPlayers'},
    const {'1': 'max_players', '3': 3, '4': 1, '5': 13, '10': 'maxPlayers'},
    const {'1': 'time_remaining', '3': 4, '4': 1, '5': 13, '10': 'timeRemaining'},
  ],
};

@$core.Deprecated('Use tierStatusUpdateDescriptor instead')
const TierStatusUpdate_StatusesEntry$json = const {
  '1': 'StatusesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 4, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.fusion.TierStatusUpdate.TierStatus', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `TierStatusUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tierStatusUpdateDescriptor = $convert.base64Decode('ChBUaWVyU3RhdHVzVXBkYXRlEkIKCHN0YXR1c2VzGAEgAygLMiYuZnVzaW9uLlRpZXJTdGF0dXNVcGRhdGUuU3RhdHVzZXNFbnRyeVIIc3RhdHVzZXMajwEKClRpZXJTdGF0dXMSGAoHcGxheWVycxgBIAEoDVIHcGxheWVycxIfCgttaW5fcGxheWVycxgCIAEoDVIKbWluUGxheWVycxIfCgttYXhfcGxheWVycxgDIAEoDVIKbWF4UGxheWVycxIlCg50aW1lX3JlbWFpbmluZxgEIAEoDVINdGltZVJlbWFpbmluZxpgCg1TdGF0dXNlc0VudHJ5EhAKA2tleRgBIAEoBFIDa2V5EjkKBXZhbHVlGAIgASgLMiMuZnVzaW9uLlRpZXJTdGF0dXNVcGRhdGUuVGllclN0YXR1c1IFdmFsdWU6AjgB');
@$core.Deprecated('Use fusionBeginDescriptor instead')
const FusionBegin$json = const {
  '1': 'FusionBegin',
  '2': const [
    const {'1': 'tier', '3': 1, '4': 2, '5': 4, '10': 'tier'},
    const {'1': 'covert_domain', '3': 2, '4': 2, '5': 12, '10': 'covertDomain'},
    const {'1': 'covert_port', '3': 3, '4': 2, '5': 13, '10': 'covertPort'},
    const {'1': 'covert_ssl', '3': 4, '4': 1, '5': 8, '10': 'covertSsl'},
    const {'1': 'server_time', '3': 5, '4': 2, '5': 6, '10': 'serverTime'},
  ],
};

/// Descriptor for `FusionBegin`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fusionBeginDescriptor = $convert.base64Decode('CgtGdXNpb25CZWdpbhISCgR0aWVyGAEgAigEUgR0aWVyEiMKDWNvdmVydF9kb21haW4YAiACKAxSDGNvdmVydERvbWFpbhIfCgtjb3ZlcnRfcG9ydBgDIAIoDVIKY292ZXJ0UG9ydBIdCgpjb3ZlcnRfc3NsGAQgASgIUgljb3ZlcnRTc2wSHwoLc2VydmVyX3RpbWUYBSACKAZSCnNlcnZlclRpbWU=');
@$core.Deprecated('Use startRoundDescriptor instead')
const StartRound$json = const {
  '1': 'StartRound',
  '2': const [
    const {'1': 'round_pubkey', '3': 1, '4': 2, '5': 12, '10': 'roundPubkey'},
    const {'1': 'blind_nonce_points', '3': 2, '4': 3, '5': 12, '10': 'blindNoncePoints'},
    const {'1': 'server_time', '3': 5, '4': 2, '5': 6, '10': 'serverTime'},
  ],
};

/// Descriptor for `StartRound`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startRoundDescriptor = $convert.base64Decode('CgpTdGFydFJvdW5kEiEKDHJvdW5kX3B1YmtleRgBIAIoDFILcm91bmRQdWJrZXkSLAoSYmxpbmRfbm9uY2VfcG9pbnRzGAIgAygMUhBibGluZE5vbmNlUG9pbnRzEh8KC3NlcnZlcl90aW1lGAUgAigGUgpzZXJ2ZXJUaW1l');
@$core.Deprecated('Use playerCommitDescriptor instead')
const PlayerCommit$json = const {
  '1': 'PlayerCommit',
  '2': const [
    const {'1': 'initial_commitments', '3': 1, '4': 3, '5': 12, '10': 'initialCommitments'},
    const {'1': 'excess_fee', '3': 2, '4': 2, '5': 4, '10': 'excessFee'},
    const {'1': 'pedersen_total_nonce', '3': 3, '4': 2, '5': 12, '10': 'pedersenTotalNonce'},
    const {'1': 'random_number_commitment', '3': 4, '4': 2, '5': 12, '10': 'randomNumberCommitment'},
    const {'1': 'blind_sig_requests', '3': 5, '4': 3, '5': 12, '10': 'blindSigRequests'},
  ],
};

/// Descriptor for `PlayerCommit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playerCommitDescriptor = $convert.base64Decode('CgxQbGF5ZXJDb21taXQSLwoTaW5pdGlhbF9jb21taXRtZW50cxgBIAMoDFISaW5pdGlhbENvbW1pdG1lbnRzEh0KCmV4Y2Vzc19mZWUYAiACKARSCWV4Y2Vzc0ZlZRIwChRwZWRlcnNlbl90b3RhbF9ub25jZRgDIAIoDFIScGVkZXJzZW5Ub3RhbE5vbmNlEjgKGHJhbmRvbV9udW1iZXJfY29tbWl0bWVudBgEIAIoDFIWcmFuZG9tTnVtYmVyQ29tbWl0bWVudBIsChJibGluZF9zaWdfcmVxdWVzdHMYBSADKAxSEGJsaW5kU2lnUmVxdWVzdHM=');
@$core.Deprecated('Use blindSigResponsesDescriptor instead')
const BlindSigResponses$json = const {
  '1': 'BlindSigResponses',
  '2': const [
    const {'1': 'scalars', '3': 1, '4': 3, '5': 12, '10': 'scalars'},
  ],
};

/// Descriptor for `BlindSigResponses`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blindSigResponsesDescriptor = $convert.base64Decode('ChFCbGluZFNpZ1Jlc3BvbnNlcxIYCgdzY2FsYXJzGAEgAygMUgdzY2FsYXJz');
@$core.Deprecated('Use allCommitmentsDescriptor instead')
const AllCommitments$json = const {
  '1': 'AllCommitments',
  '2': const [
    const {'1': 'initial_commitments', '3': 1, '4': 3, '5': 12, '10': 'initialCommitments'},
  ],
};

/// Descriptor for `AllCommitments`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List allCommitmentsDescriptor = $convert.base64Decode('Cg5BbGxDb21taXRtZW50cxIvChNpbml0aWFsX2NvbW1pdG1lbnRzGAEgAygMUhJpbml0aWFsQ29tbWl0bWVudHM=');
@$core.Deprecated('Use covertComponentDescriptor instead')
const CovertComponent$json = const {
  '1': 'CovertComponent',
  '2': const [
    const {'1': 'round_pubkey', '3': 1, '4': 1, '5': 12, '10': 'roundPubkey'},
    const {'1': 'signature', '3': 2, '4': 2, '5': 12, '10': 'signature'},
    const {'1': 'component', '3': 3, '4': 2, '5': 12, '10': 'component'},
  ],
};

/// Descriptor for `CovertComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List covertComponentDescriptor = $convert.base64Decode('Cg9Db3ZlcnRDb21wb25lbnQSIQoMcm91bmRfcHVia2V5GAEgASgMUgtyb3VuZFB1YmtleRIcCglzaWduYXR1cmUYAiACKAxSCXNpZ25hdHVyZRIcCgljb21wb25lbnQYAyACKAxSCWNvbXBvbmVudA==');
@$core.Deprecated('Use shareCovertComponentsDescriptor instead')
const ShareCovertComponents$json = const {
  '1': 'ShareCovertComponents',
  '2': const [
    const {'1': 'components', '3': 4, '4': 3, '5': 12, '10': 'components'},
    const {'1': 'skip_signatures', '3': 5, '4': 1, '5': 8, '10': 'skipSignatures'},
    const {'1': 'session_hash', '3': 6, '4': 1, '5': 12, '10': 'sessionHash'},
  ],
};

/// Descriptor for `ShareCovertComponents`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List shareCovertComponentsDescriptor = $convert.base64Decode('ChVTaGFyZUNvdmVydENvbXBvbmVudHMSHgoKY29tcG9uZW50cxgEIAMoDFIKY29tcG9uZW50cxInCg9za2lwX3NpZ25hdHVyZXMYBSABKAhSDnNraXBTaWduYXR1cmVzEiEKDHNlc3Npb25faGFzaBgGIAEoDFILc2Vzc2lvbkhhc2g=');
@$core.Deprecated('Use covertTransactionSignatureDescriptor instead')
const CovertTransactionSignature$json = const {
  '1': 'CovertTransactionSignature',
  '2': const [
    const {'1': 'round_pubkey', '3': 1, '4': 1, '5': 12, '10': 'roundPubkey'},
    const {'1': 'which_input', '3': 2, '4': 2, '5': 13, '10': 'whichInput'},
    const {'1': 'txsignature', '3': 3, '4': 2, '5': 12, '10': 'txsignature'},
  ],
};

/// Descriptor for `CovertTransactionSignature`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List covertTransactionSignatureDescriptor = $convert.base64Decode('ChpDb3ZlcnRUcmFuc2FjdGlvblNpZ25hdHVyZRIhCgxyb3VuZF9wdWJrZXkYASABKAxSC3JvdW5kUHVia2V5Eh8KC3doaWNoX2lucHV0GAIgAigNUgp3aGljaElucHV0EiAKC3R4c2lnbmF0dXJlGAMgAigMUgt0eHNpZ25hdHVyZQ==');
@$core.Deprecated('Use fusionResultDescriptor instead')
const FusionResult$json = const {
  '1': 'FusionResult',
  '2': const [
    const {'1': 'ok', '3': 1, '4': 2, '5': 8, '10': 'ok'},
    const {'1': 'txsignatures', '3': 2, '4': 3, '5': 12, '10': 'txsignatures'},
    const {'1': 'bad_components', '3': 3, '4': 3, '5': 13, '10': 'badComponents'},
  ],
};

/// Descriptor for `FusionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fusionResultDescriptor = $convert.base64Decode('CgxGdXNpb25SZXN1bHQSDgoCb2sYASACKAhSAm9rEiIKDHR4c2lnbmF0dXJlcxgCIAMoDFIMdHhzaWduYXR1cmVzEiUKDmJhZF9jb21wb25lbnRzGAMgAygNUg1iYWRDb21wb25lbnRz');
@$core.Deprecated('Use myProofsListDescriptor instead')
const MyProofsList$json = const {
  '1': 'MyProofsList',
  '2': const [
    const {'1': 'encrypted_proofs', '3': 1, '4': 3, '5': 12, '10': 'encryptedProofs'},
    const {'1': 'random_number', '3': 2, '4': 2, '5': 12, '10': 'randomNumber'},
  ],
};

/// Descriptor for `MyProofsList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List myProofsListDescriptor = $convert.base64Decode('CgxNeVByb29mc0xpc3QSKQoQZW5jcnlwdGVkX3Byb29mcxgBIAMoDFIPZW5jcnlwdGVkUHJvb2ZzEiMKDXJhbmRvbV9udW1iZXIYAiACKAxSDHJhbmRvbU51bWJlcg==');
@$core.Deprecated('Use theirProofsListDescriptor instead')
const TheirProofsList$json = const {
  '1': 'TheirProofsList',
  '2': const [
    const {'1': 'proofs', '3': 1, '4': 3, '5': 11, '6': '.fusion.TheirProofsList.RelayedProof', '10': 'proofs'},
  ],
  '3': const [TheirProofsList_RelayedProof$json],
};

@$core.Deprecated('Use theirProofsListDescriptor instead')
const TheirProofsList_RelayedProof$json = const {
  '1': 'RelayedProof',
  '2': const [
    const {'1': 'encrypted_proof', '3': 1, '4': 2, '5': 12, '10': 'encryptedProof'},
    const {'1': 'src_commitment_idx', '3': 2, '4': 2, '5': 13, '10': 'srcCommitmentIdx'},
    const {'1': 'dst_key_idx', '3': 3, '4': 2, '5': 13, '10': 'dstKeyIdx'},
  ],
};

/// Descriptor for `TheirProofsList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List theirProofsListDescriptor = $convert.base64Decode('Cg9UaGVpclByb29mc0xpc3QSPAoGcHJvb2ZzGAEgAygLMiQuZnVzaW9uLlRoZWlyUHJvb2ZzTGlzdC5SZWxheWVkUHJvb2ZSBnByb29mcxqFAQoMUmVsYXllZFByb29mEicKD2VuY3J5cHRlZF9wcm9vZhgBIAIoDFIOZW5jcnlwdGVkUHJvb2YSLAoSc3JjX2NvbW1pdG1lbnRfaWR4GAIgAigNUhBzcmNDb21taXRtZW50SWR4Eh4KC2RzdF9rZXlfaWR4GAMgAigNUglkc3RLZXlJZHg=');
@$core.Deprecated('Use blamesDescriptor instead')
const Blames$json = const {
  '1': 'Blames',
  '2': const [
    const {'1': 'blames', '3': 1, '4': 3, '5': 11, '6': '.fusion.Blames.BlameProof', '10': 'blames'},
  ],
  '3': const [Blames_BlameProof$json],
};

@$core.Deprecated('Use blamesDescriptor instead')
const Blames_BlameProof$json = const {
  '1': 'BlameProof',
  '2': const [
    const {'1': 'which_proof', '3': 1, '4': 2, '5': 13, '10': 'whichProof'},
    const {'1': 'session_key', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'sessionKey'},
    const {'1': 'privkey', '3': 3, '4': 1, '5': 12, '9': 0, '10': 'privkey'},
    const {'1': 'need_lookup_blockchain', '3': 4, '4': 1, '5': 8, '10': 'needLookupBlockchain'},
    const {'1': 'blame_reason', '3': 5, '4': 1, '5': 9, '10': 'blameReason'},
  ],
  '8': const [
    const {'1': 'decrypter'},
  ],
};

/// Descriptor for `Blames`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blamesDescriptor = $convert.base64Decode('CgZCbGFtZXMSMQoGYmxhbWVzGAEgAygLMhkuZnVzaW9uLkJsYW1lcy5CbGFtZVByb29mUgZibGFtZXMa0gEKCkJsYW1lUHJvb2YSHwoLd2hpY2hfcHJvb2YYASACKA1SCndoaWNoUHJvb2YSIQoLc2Vzc2lvbl9rZXkYAiABKAxIAFIKc2Vzc2lvbktleRIaCgdwcml2a2V5GAMgASgMSABSB3ByaXZrZXkSNAoWbmVlZF9sb29rdXBfYmxvY2tjaGFpbhgEIAEoCFIUbmVlZExvb2t1cEJsb2NrY2hhaW4SIQoMYmxhbWVfcmVhc29uGAUgASgJUgtibGFtZVJlYXNvbkILCglkZWNyeXB0ZXI=');
@$core.Deprecated('Use restartRoundDescriptor instead')
const RestartRound$json = const {
  '1': 'RestartRound',
};

/// Descriptor for `RestartRound`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restartRoundDescriptor = $convert.base64Decode('CgxSZXN0YXJ0Um91bmQ=');
@$core.Deprecated('Use errorDescriptor instead')
const Error$json = const {
  '1': 'Error',
  '2': const [
    const {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `Error`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List errorDescriptor = $convert.base64Decode('CgVFcnJvchIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdl');
@$core.Deprecated('Use pingDescriptor instead')
const Ping$json = const {
  '1': 'Ping',
};

/// Descriptor for `Ping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingDescriptor = $convert.base64Decode('CgRQaW5n');
@$core.Deprecated('Use oKDescriptor instead')
const OK$json = const {
  '1': 'OK',
};

/// Descriptor for `OK`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List oKDescriptor = $convert.base64Decode('CgJPSw==');
@$core.Deprecated('Use clientMessageDescriptor instead')
const ClientMessage$json = const {
  '1': 'ClientMessage',
  '2': const [
    const {'1': 'clienthello', '3': 1, '4': 1, '5': 11, '6': '.fusion.ClientHello', '9': 0, '10': 'clienthello'},
    const {'1': 'joinpools', '3': 2, '4': 1, '5': 11, '6': '.fusion.JoinPools', '9': 0, '10': 'joinpools'},
    const {'1': 'playercommit', '3': 3, '4': 1, '5': 11, '6': '.fusion.PlayerCommit', '9': 0, '10': 'playercommit'},
    const {'1': 'myproofslist', '3': 5, '4': 1, '5': 11, '6': '.fusion.MyProofsList', '9': 0, '10': 'myproofslist'},
    const {'1': 'blames', '3': 6, '4': 1, '5': 11, '6': '.fusion.Blames', '9': 0, '10': 'blames'},
  ],
  '8': const [
    const {'1': 'msg'},
  ],
};

/// Descriptor for `ClientMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientMessageDescriptor = $convert.base64Decode('Cg1DbGllbnRNZXNzYWdlEjcKC2NsaWVudGhlbGxvGAEgASgLMhMuZnVzaW9uLkNsaWVudEhlbGxvSABSC2NsaWVudGhlbGxvEjEKCWpvaW5wb29scxgCIAEoCzIRLmZ1c2lvbi5Kb2luUG9vbHNIAFIJam9pbnBvb2xzEjoKDHBsYXllcmNvbW1pdBgDIAEoCzIULmZ1c2lvbi5QbGF5ZXJDb21taXRIAFIMcGxheWVyY29tbWl0EjoKDG15cHJvb2ZzbGlzdBgFIAEoCzIULmZ1c2lvbi5NeVByb29mc0xpc3RIAFIMbXlwcm9vZnNsaXN0EigKBmJsYW1lcxgGIAEoCzIOLmZ1c2lvbi5CbGFtZXNIAFIGYmxhbWVzQgUKA21zZw==');
@$core.Deprecated('Use serverMessageDescriptor instead')
const ServerMessage$json = const {
  '1': 'ServerMessage',
  '2': const [
    const {'1': 'serverhello', '3': 1, '4': 1, '5': 11, '6': '.fusion.ServerHello', '9': 0, '10': 'serverhello'},
    const {'1': 'tierstatusupdate', '3': 2, '4': 1, '5': 11, '6': '.fusion.TierStatusUpdate', '9': 0, '10': 'tierstatusupdate'},
    const {'1': 'fusionbegin', '3': 3, '4': 1, '5': 11, '6': '.fusion.FusionBegin', '9': 0, '10': 'fusionbegin'},
    const {'1': 'startround', '3': 4, '4': 1, '5': 11, '6': '.fusion.StartRound', '9': 0, '10': 'startround'},
    const {'1': 'blindsigresponses', '3': 5, '4': 1, '5': 11, '6': '.fusion.BlindSigResponses', '9': 0, '10': 'blindsigresponses'},
    const {'1': 'allcommitments', '3': 6, '4': 1, '5': 11, '6': '.fusion.AllCommitments', '9': 0, '10': 'allcommitments'},
    const {'1': 'sharecovertcomponents', '3': 7, '4': 1, '5': 11, '6': '.fusion.ShareCovertComponents', '9': 0, '10': 'sharecovertcomponents'},
    const {'1': 'fusionresult', '3': 8, '4': 1, '5': 11, '6': '.fusion.FusionResult', '9': 0, '10': 'fusionresult'},
    const {'1': 'theirproofslist', '3': 9, '4': 1, '5': 11, '6': '.fusion.TheirProofsList', '9': 0, '10': 'theirproofslist'},
    const {'1': 'restartround', '3': 14, '4': 1, '5': 11, '6': '.fusion.RestartRound', '9': 0, '10': 'restartround'},
    const {'1': 'error', '3': 15, '4': 1, '5': 11, '6': '.fusion.Error', '9': 0, '10': 'error'},
  ],
  '8': const [
    const {'1': 'msg'},
  ],
};

/// Descriptor for `ServerMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverMessageDescriptor = $convert.base64Decode('Cg1TZXJ2ZXJNZXNzYWdlEjcKC3NlcnZlcmhlbGxvGAEgASgLMhMuZnVzaW9uLlNlcnZlckhlbGxvSABSC3NlcnZlcmhlbGxvEkYKEHRpZXJzdGF0dXN1cGRhdGUYAiABKAsyGC5mdXNpb24uVGllclN0YXR1c1VwZGF0ZUgAUhB0aWVyc3RhdHVzdXBkYXRlEjcKC2Z1c2lvbmJlZ2luGAMgASgLMhMuZnVzaW9uLkZ1c2lvbkJlZ2luSABSC2Z1c2lvbmJlZ2luEjQKCnN0YXJ0cm91bmQYBCABKAsyEi5mdXNpb24uU3RhcnRSb3VuZEgAUgpzdGFydHJvdW5kEkkKEWJsaW5kc2lncmVzcG9uc2VzGAUgASgLMhkuZnVzaW9uLkJsaW5kU2lnUmVzcG9uc2VzSABSEWJsaW5kc2lncmVzcG9uc2VzEkAKDmFsbGNvbW1pdG1lbnRzGAYgASgLMhYuZnVzaW9uLkFsbENvbW1pdG1lbnRzSABSDmFsbGNvbW1pdG1lbnRzElUKFXNoYXJlY292ZXJ0Y29tcG9uZW50cxgHIAEoCzIdLmZ1c2lvbi5TaGFyZUNvdmVydENvbXBvbmVudHNIAFIVc2hhcmVjb3ZlcnRjb21wb25lbnRzEjoKDGZ1c2lvbnJlc3VsdBgIIAEoCzIULmZ1c2lvbi5GdXNpb25SZXN1bHRIAFIMZnVzaW9ucmVzdWx0EkMKD3RoZWlycHJvb2ZzbGlzdBgJIAEoCzIXLmZ1c2lvbi5UaGVpclByb29mc0xpc3RIAFIPdGhlaXJwcm9vZnNsaXN0EjoKDHJlc3RhcnRyb3VuZBgOIAEoCzIULmZ1c2lvbi5SZXN0YXJ0Um91bmRIAFIMcmVzdGFydHJvdW5kEiUKBWVycm9yGA8gASgLMg0uZnVzaW9uLkVycm9ySABSBWVycm9yQgUKA21zZw==');
@$core.Deprecated('Use covertMessageDescriptor instead')
const CovertMessage$json = const {
  '1': 'CovertMessage',
  '2': const [
    const {'1': 'component', '3': 1, '4': 1, '5': 11, '6': '.fusion.CovertComponent', '9': 0, '10': 'component'},
    const {'1': 'signature', '3': 2, '4': 1, '5': 11, '6': '.fusion.CovertTransactionSignature', '9': 0, '10': 'signature'},
    const {'1': 'ping', '3': 3, '4': 1, '5': 11, '6': '.fusion.Ping', '9': 0, '10': 'ping'},
  ],
  '8': const [
    const {'1': 'msg'},
  ],
};

/// Descriptor for `CovertMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List covertMessageDescriptor = $convert.base64Decode('Cg1Db3ZlcnRNZXNzYWdlEjcKCWNvbXBvbmVudBgBIAEoCzIXLmZ1c2lvbi5Db3ZlcnRDb21wb25lbnRIAFIJY29tcG9uZW50EkIKCXNpZ25hdHVyZRgCIAEoCzIiLmZ1c2lvbi5Db3ZlcnRUcmFuc2FjdGlvblNpZ25hdHVyZUgAUglzaWduYXR1cmUSIgoEcGluZxgDIAEoCzIMLmZ1c2lvbi5QaW5nSABSBHBpbmdCBQoDbXNn');
@$core.Deprecated('Use covertResponseDescriptor instead')
const CovertResponse$json = const {
  '1': 'CovertResponse',
  '2': const [
    const {'1': 'ok', '3': 1, '4': 1, '5': 11, '6': '.fusion.OK', '9': 0, '10': 'ok'},
    const {'1': 'error', '3': 15, '4': 1, '5': 11, '6': '.fusion.Error', '9': 0, '10': 'error'},
  ],
  '8': const [
    const {'1': 'msg'},
  ],
};

/// Descriptor for `CovertResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List covertResponseDescriptor = $convert.base64Decode('Cg5Db3ZlcnRSZXNwb25zZRIcCgJvaxgBIAEoCzIKLmZ1c2lvbi5PS0gAUgJvaxIlCgVlcnJvchgPIAEoCzINLmZ1c2lvbi5FcnJvckgAUgVlcnJvckIFCgNtc2c=');
