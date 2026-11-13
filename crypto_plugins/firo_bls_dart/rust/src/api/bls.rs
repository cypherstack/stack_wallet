
use blst::min_pk::{AggregateSignature, PublicKey, Signature};
use blst::BLST_ERROR;
use dash_pkc::bls::{BlsScChia, BlsSecretKey};
use zeroize::Zeroize;

#[flutter_rust_bridge::frb(sync)]
pub fn firo_legacy_bls_public_key(mut secret_key: Vec<u8>) -> Result<Vec<u8>, String> {
    let mut key_bytes: [u8; 32] = secret_key
        .as_slice()
        .try_into()
        .map_err(|_| "Operator BLS private key must be 32 bytes".to_string())?;
    secret_key.zeroize();
    let key = BlsSecretKey::<BlsScChia>::from_bytes(&key_bytes);
    key_bytes.zeroize();
    let key = key.map_err(|_| "Invalid Firo legacy BLS private key".to_string())?;
    Ok(key.public_key().to_bytes().to_vec())
}

#[flutter_rust_bridge::frb(sync)]
pub fn firo_legacy_bls_sign_digest(
    mut secret_key: Vec<u8>,
    digest: Vec<u8>,
) -> Result<Vec<u8>, String> {
    let mut key_bytes: [u8; 32] = secret_key
        .as_slice()
        .try_into()
        .map_err(|_| "Operator BLS private key must be 32 bytes".to_string())?;
    secret_key.zeroize();
    let digest: [u8; 32] = digest
        .as_slice()
        .try_into()
        .map_err(|_| "Firo BLS signing digest must be 32 bytes".to_string())?;
    let key = BlsSecretKey::<BlsScChia>::from_bytes(&key_bytes);
    key_bytes.zeroize();
    let key = key.map_err(|_| "Invalid Firo legacy BLS private key".to_string())?;
    Ok(key.sign_digest(&digest).to_bytes().to_vec())
}

const DST: &[u8] = b"BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_";

#[flutter_rust_bridge::frb(sync)]
pub fn bls12381_min_pk_verify(sig_bytes: Vec<u8>, pk_bytes: Vec<u8>, msg: Vec<u8>) -> bool {
    let pk = match PublicKey::from_bytes(&pk_bytes) {
        Ok(pk) => pk,
        Err(_) => return false,
    };
    let sig = match Signature::from_bytes(&sig_bytes) {
        Ok(sig) => sig,
        Err(_) => return false,
    };
    sig.verify(true, &msg, DST, &[], &pk, true) == BLST_ERROR::BLST_SUCCESS
}

#[flutter_rust_bridge::frb(sync)]
pub fn bls12381_min_pk_aggregate(sigs_bytes: Vec<Vec<u8>>) -> Vec<u8> {
    if sigs_bytes.is_empty() {
        return vec![];
    }

    let sigs: Result<Vec<Signature>, _> = sigs_bytes
        .iter()
        .map(|b| Signature::from_bytes(b))
        .collect();

    let sigs = match sigs {
        Ok(s) => s,
        Err(_) => return vec![],
    };

    let sig_refs: Vec<&Signature> = sigs.iter().collect();

    match AggregateSignature::aggregate(&sig_refs, true) {
        Ok(agg) => agg.to_signature().to_bytes().to_vec(),
        Err(_) => vec![],
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn bls12381_min_pk_verify_aggregate(
    pks_bytes: Vec<Vec<u8>>,
    msg: Vec<u8>,
    agg_sig_bytes: Vec<u8>,
) -> bool {
    if pks_bytes.is_empty() {
        return false;
    }

    let pks: Result<Vec<PublicKey>, _> =
        pks_bytes.iter().map(|b| PublicKey::from_bytes(b)).collect();

    let pks = match pks {
        Ok(p) => p,
        Err(_) => return false,
    };

    let sig = match Signature::from_bytes(&agg_sig_bytes) {
        Ok(s) => s,
        Err(_) => return false,
    };

    let pk_refs: Vec<&PublicKey> = pks.iter().collect();

    sig.fast_aggregate_verify(true, &msg, DST, &pk_refs) == BLST_ERROR::BLST_SUCCESS
}

#[cfg(test)]
mod tests {
    use super::*;
    use blst::min_pk::SecretKey;

    fn keygen(seed: &[u8; 32]) -> (SecretKey, PublicKey) {
        let sk = SecretKey::key_gen(seed, &[]).unwrap();
        let pk = sk.sk_to_pk();
        (sk, pk)
    }

    fn sign_msg(sk: &SecretKey, msg: &[u8]) -> Signature {
        sk.sign(msg, DST, &[])
    }


    #[test]
    fn verify_valid_signature() {
        let (sk, pk) = keygen(b"test-seed-for-bls-verification!!");
        let msg = b"hello walrus";
        let sig = sign_msg(&sk, msg);

        assert!(bls12381_min_pk_verify(
            sig.to_bytes().to_vec(),
            pk.to_bytes().to_vec(),
            msg.to_vec(),
        ));
    }

    #[test]
    fn verify_wrong_message() {
        let (sk, pk) = keygen(b"test-seed-for-bls-wrong-msg!!!!!");
        let sig = sign_msg(&sk, b"correct message");

        assert!(!bls12381_min_pk_verify(
            sig.to_bytes().to_vec(),
            pk.to_bytes().to_vec(),
            b"wrong message".to_vec(),
        ));
    }

    #[test]
    fn verify_wrong_key() {
        let (sk1, _) = keygen(b"test-seed-for-bls-wrong-key-1!!!");
        let (_, pk2) = keygen(b"test-seed-for-bls-wrong-key-2!!!");
        let msg = b"hello walrus";
        let sig = sign_msg(&sk1, msg);

        assert!(!bls12381_min_pk_verify(
            sig.to_bytes().to_vec(),
            pk2.to_bytes().to_vec(),
            msg.to_vec(),
        ));
    }

    #[test]
    fn verify_empty_inputs() {
        assert!(!bls12381_min_pk_verify(vec![], vec![], vec![]));
    }

    #[test]
    fn verify_wrong_size_signature() {
        assert!(!bls12381_min_pk_verify(
            vec![0u8; 48], // Should be 96
            vec![0u8; 48],
            vec![1, 2, 3],
        ));
    }

    #[test]
    fn verify_wrong_size_pubkey() {
        assert!(!bls12381_min_pk_verify(
            vec![0u8; 96],
            vec![0u8; 32], // Should be 48
            vec![1, 2, 3],
        ));
    }


    #[test]
    fn aggregate_single() {
        let (sk, _) = keygen(b"test-seed-for-bls-aggregate-1!!!");
        let sig = sign_msg(&sk, b"aggregate me");

        let agg = bls12381_min_pk_aggregate(vec![sig.to_bytes().to_vec()]);
        assert_eq!(agg.len(), 96);
        assert_eq!(agg, sig.to_bytes().to_vec());
    }

    #[test]
    fn aggregate_multiple() {
        let (sk1, _) = keygen(b"test-seed-for-bls-agg-multi-1!!!");
        let (sk2, _) = keygen(b"test-seed-for-bls-agg-multi-2!!!");
        let (sk3, _) = keygen(b"test-seed-for-bls-agg-multi-3!!!");
        let msg = b"shared message";

        let sig1 = sign_msg(&sk1, msg);
        let sig2 = sign_msg(&sk2, msg);
        let sig3 = sign_msg(&sk3, msg);

        let agg = bls12381_min_pk_aggregate(vec![
            sig1.to_bytes().to_vec(),
            sig2.to_bytes().to_vec(),
            sig3.to_bytes().to_vec(),
        ]);
        assert_eq!(agg.len(), 96);
        assert_ne!(agg, sig1.to_bytes().to_vec());
    }

    #[test]
    fn aggregate_empty() {
        assert!(bls12381_min_pk_aggregate(vec![]).is_empty());
    }

    #[test]
    fn aggregate_malformed() {
        assert!(bls12381_min_pk_aggregate(vec![vec![0u8; 10]]).is_empty());
    }


    #[test]
    fn verify_aggregate_valid() {
        let (sk1, pk1) = keygen(b"test-agg-verify-valid-key-1!!!!!");
        let (sk2, pk2) = keygen(b"test-agg-verify-valid-key-2!!!!!");
        let (sk3, pk3) = keygen(b"test-agg-verify-valid-key-3!!!!!");
        let msg = b"certify this blob";

        let agg = bls12381_min_pk_aggregate(vec![
            sign_msg(&sk1, msg).to_bytes().to_vec(),
            sign_msg(&sk2, msg).to_bytes().to_vec(),
            sign_msg(&sk3, msg).to_bytes().to_vec(),
        ]);

        assert!(bls12381_min_pk_verify_aggregate(
            vec![
                pk1.to_bytes().to_vec(),
                pk2.to_bytes().to_vec(),
                pk3.to_bytes().to_vec(),
            ],
            msg.to_vec(),
            agg,
        ));
    }

    #[test]
    fn verify_aggregate_wrong_message() {
        let (sk1, pk1) = keygen(b"test-agg-verify-wrong-msg-key1!!");
        let (sk2, pk2) = keygen(b"test-agg-verify-wrong-msg-key2!!");
        let msg = b"correct message";

        let agg = bls12381_min_pk_aggregate(vec![
            sign_msg(&sk1, msg).to_bytes().to_vec(),
            sign_msg(&sk2, msg).to_bytes().to_vec(),
        ]);

        assert!(!bls12381_min_pk_verify_aggregate(
            vec![pk1.to_bytes().to_vec(), pk2.to_bytes().to_vec()],
            b"wrong message".to_vec(),
            agg,
        ));
    }

    #[test]
    fn verify_aggregate_missing_signer() {
        let (sk1, pk1) = keygen(b"test-agg-verify-missing-key-1!!!");
        let (sk2, pk2) = keygen(b"test-agg-verify-missing-key-2!!!");
        let (_, pk3) = keygen(b"test-agg-verify-missing-key-3!!!");
        let msg = b"only two signed";

        let agg = bls12381_min_pk_aggregate(vec![
            sign_msg(&sk1, msg).to_bytes().to_vec(),
            sign_msg(&sk2, msg).to_bytes().to_vec(),
        ]);

        assert!(!bls12381_min_pk_verify_aggregate(
            vec![
                pk1.to_bytes().to_vec(),
                pk2.to_bytes().to_vec(),
                pk3.to_bytes().to_vec(),
            ],
            msg.to_vec(),
            agg,
        ));
    }

    #[test]
    fn verify_aggregate_empty_keys() {
        assert!(!bls12381_min_pk_verify_aggregate(
            vec![],
            b"msg".to_vec(),
            vec![0u8; 96],
        ));
    }


    #[test]
    fn end_to_end_walrus_flow() {

        let seeds: [&[u8; 32]; 5] = [
            b"walrus-node-0-secret-key-seed!!1",
            b"walrus-node-1-secret-key-seed!!2",
            b"walrus-node-2-secret-key-seed!!3",
            b"walrus-node-3-secret-key-seed!!4",
            b"walrus-node-4-secret-key-seed!!5",
        ];

        let keys: Vec<(SecretKey, PublicKey)> = seeds.iter().map(|s| keygen(s)).collect();
        let blob_cert_msg = b"blob_cert_v1:blobid=abc123:epoch=42:size=1024";

        let responding = vec![0usize, 2, 4];
        let sigs: Vec<Vec<u8>> = responding
            .iter()
            .map(|&i| sign_msg(&keys[i].0, blob_cert_msg).to_bytes().to_vec())
            .collect();

        let agg_sig = bls12381_min_pk_aggregate(sigs);
        assert_eq!(agg_sig.len(), 96);

        let responding_pks: Vec<Vec<u8>> = responding
            .iter()
            .map(|&i| keys[i].1.to_bytes().to_vec())
            .collect();

        assert!(bls12381_min_pk_verify_aggregate(
            responding_pks,
            blob_cert_msg.to_vec(),
            agg_sig,
        ));
    }

    #[test]
    fn key_and_sig_sizes() {
        let (sk, pk) = keygen(b"test-sizes-check-key-seed!!!!!!!");
        let sig = sign_msg(&sk, b"size check");
        assert_eq!(pk.to_bytes().len(), 48, "Public key should be 48 bytes");
        assert_eq!(sig.to_bytes().len(), 96, "Signature should be 96 bytes");
    }
}
