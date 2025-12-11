import 'package:coinlib_flutter/coinlib_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/electrum_seed_utils.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';

class _TestCase {
  final String words, bip32Seed, seedVersion;
  final String? lang, wordsHex, passphrase, passphraseHex;

  const _TestCase({
    required this.words,
    required this.bip32Seed,
    this.seedVersion = ElectrumSeedUtils.kSeedPrefix,
    this.lang,
    this.wordsHex,
    this.passphrase,
    this.passphraseHex,
  });
}

// horror data sourced from https://github.com/spesmilo/electrum/blob/master/tests/test_wallet_vertical.py#L31-L33
const kUnicodeHorror =
    "₿ 😀 😈     う けたま わる w͢͢͝h͡o͢͡ ̸͢k̵͟n̴͘ǫw̸̛s͘ ̀́w͘͢ḩ̵a҉̡͢t ̧̕h́o̵r͏̵rors̡ ̶͡͠lį̶e͟͟ ̶͝in͢ ͏t̕h̷̡͟e ͟͟d̛a͜r̕͡k̢̨ ͡h̴e͏a̷̢̡rt́͏ ̴̷͠ò̵̶f̸ u̧͘ní̛͜c͢͏o̷͏d̸͢e̡͝?͞";
const kUnicodeHorrorHex =
    "e282bf20f09f988020f09f98882020202020e3818620e38191e3819fe381be20e3828fe382"
    "8b2077cda2cda2cd9d68cda16fcda2cda120ccb8cda26bccb5cd9f6eccb4cd98c7ab77ccb8"
    "cc9b73cd9820cc80cc8177cd98cda2e1b8a9ccb561d289cca1cda27420cca7cc9568cc816f"
    "ccb572cd8fccb5726f7273cca120ccb6cda1cda06cc4afccb665cd9fcd9f20ccb6cd9d696e"
    "cda220cd8f74cc9568ccb7cca1cd9f6520cd9fcd9f64cc9b61cd9c72cc95cda16bcca2cca8"
    "20cda168ccb465cd8f61ccb7cca2cca17274cc81cd8f20ccb4ccb7cda0c3b2ccb5ccb666cc"
    "b82075cca7cd986ec3adcc9bcd9c63cda2cd8f6fccb7cd8f64ccb8cda265cca1cd9d3fcd9e";

// test cases sourced from https://github.com/spesmilo/electrum/blob/master/tests/test_mnemonic.py
const kTestCases = {
  "english": _TestCase(
    words:
        "wild father tree among universe such"
        " mobile favorite target dynamic credit identify",
    seedVersion: ElectrumSeedUtils.kSeedPrefixSegwit,
    bip32Seed:
        "aac2a6302e48577ab4b46f23dbae0774e2e62c796f797d0a1b5faeb528301e3064342d"
        "afb79069e7c4c6b8c38ae11d7a973bec0d4f70626f8cc5184a8d0b0756",
  ),
  "english_with_passphrase": _TestCase(
    words:
        "wild father tree among universe such"
        " mobile favorite target dynamic credit identify",
    seedVersion: ElectrumSeedUtils.kSeedPrefixSegwit,
    passphrase: "Did you ever hear the tragedy of Darth Plagueis the Wise?",
    bip32Seed:
        "4aa29f2aeb0127efb55138ab9e7be83b36750358751906f86c662b21a1ea1370f949e6"
        "d1a12fa56d3d93cadda93038c76ac8118597364e46f5156fde6183c82f",
  ),
  "japanese": _TestCase(
    lang: "ja",
    words: "なのか ひろい しなん まなぶ つぶす さがす おしゃれ かわく おいかける けさき かいとう さたん",
    wordsHex:
        "e381aae381aee3818b20e381b2e3828de3818420e38197e381aae3829320e381bee381"
        "aae381b5e3829920e381a4e381b5e38299e3819920e38195e3818be38299e38199"
        "20e3818ae38197e38283e3828c20e3818be3828fe3818f20e3818ae38184e3818b"
        "e38191e3828b20e38191e38195e3818d20e3818be38184e381a8e3818620e38195"
        "e3819fe38293",
    bip32Seed:
        "d3eaf0e44ddae3a5769cb08a26918e8b308258bcb057bb704c6f69713245c0b35cb92c"
        "03df9c9ece5eff826091b4e74041e010b701d44d610976ce8bfb66a8ad",
  ),
  "japanese_with_passphrase": _TestCase(
    lang: "ja",
    words: "なのか ひろい しなん まなぶ つぶす さがす おしゃれ かわく おいかける けさき かいとう さたん",
    wordsHex:
        "e381aae381aee3818b20e381b2e3828de3818420e38197e381aae3829320e381bee381"
        "aae381b5e3829920e381a4e381b5e38299e3819920e38195e3818be38299e38199"
        "20e3818ae38197e38283e3828c20e3818be3828fe3818f20e3818ae38184e3818b"
        "e38191e3828b20e38191e38195e3818d20e3818be38184e381a8e3818620e38195"
        "e3819fe38293",
    passphrase: kUnicodeHorror,
    passphraseHex: kUnicodeHorrorHex,
    bip32Seed:
        "251ee6b45b38ba0849e8f40794540f7e2c6d9d604c31d68d3ac50c034f8b64e4bc037c"
        "5e1e985a2fed8aad23560e690b03b120daf2e84dceb1d7857dda042457",
  ),
  "chinese": _TestCase(
    lang: "zh",
    words: "眼 悲 叛 改 节 跃 衡 响 疆 股 遂 冬",
    wordsHex:
        "e79cbc20e682b220e58f9b20e694b920e88a8220e8b78320e8a1a120e5938d20e79686"
        "20e882a120e9818220e586ac",
    seedVersion: ElectrumSeedUtils.kSeedPrefixSegwit,
    bip32Seed:
        "0b9077db7b5a50dbb6f61821e2d35e255068a5847e221138048a20e12d80b673ce306b"
        "6fe7ac174ebc6751e11b7037be6ee9f17db8040bb44f8466d519ce2abf",
  ),
  "chinese_with_passphrase": _TestCase(
    lang: "zh",
    words: "眼 悲 叛 改 节 跃 衡 响 疆 股 遂 冬",
    wordsHex:
        "e79cbc20e682b220e58f9b20e694b920e88a8220e8b78320e8a1a120e5938d20e79686"
        "20e882a120e9818220e586ac",
    seedVersion: ElectrumSeedUtils.kSeedPrefixSegwit,
    passphrase: "给我一些测试向量谷歌",
    passphraseHex:
        "e7bb99e68891e4b880e4ba9be6b58be8af95e59091e9878fe8b0b7e6ad8c",
    bip32Seed:
        "6c03dd0615cf59963620c0af6840b52e867468cc64f20a1f4c8155705738e87b8edb0f"
        "c8a6cee4085776cb3a629ff88bb1a38f37085efdbf11ce9ec5a7fa5f71",
  ),
  "spanish": _TestCase(
    lang: "es",
    words:
        "almíbar tibio superar vencer hacha peatón"
        " príncipe matar consejo polen vehículo odisea",
    wordsHex:
        "616c6d69cc8162617220746962696f20737570657261722076656e6365722068616368"
        "6120706561746fcc816e20707269cc816e63697065206d6174617220636f6e7365"
        "6a6f20706f6c656e2076656869cc8163756c6f206f6469736561",
    bip32Seed:
        "18bffd573a960cc775bbd80ed60b7dc00bc8796a186edebe7fc7cf1f316da0fe937852"
        "a969c5c79ded8255cdf54409537a16339fbe33fb9161af793ea47faa7a",
  ),
  "spanish_with_passphrase": _TestCase(
    lang: "es",
    words:
        "almíbar tibio superar vencer hacha peatón "
        "príncipe matar consejo polen vehículo odisea",
    wordsHex:
        "616c6d69cc8162617220746962696f20737570657261722076656e6365722068616368"
        "6120706561746fcc816e20707269cc816e63697065206d6174617220636f6e73656a6f"
        "20706f6c656e2076656869cc8163756c6f206f6469736561",
    passphrase: "araña difícil solución término cárcel",
    passphraseHex:
        "6172616ecc83612064696669cc8163696c20736f6c7563696fcc816e207465cc81726d"
        "696e6f206361cc817263656c",
    bip32Seed:
        "363dec0e575b887cfccebee4c84fca5a3a6bed9d0e099c061fa6b85020b031f8fe3636"
        "d9af187bf432d451273c625e20f24f651ada41aae2c4ea62d87e9fa44c",
  ),
  "spanish2": _TestCase(
    lang: "es",
    words:
        "equipo fiar auge langosta hacha calor "
        "trance cubrir carro pulmón oro áspero",
    wordsHex:
        "65717569706f20666961722061756765206c616e676f7374612068616368612063616c"
        "6f72207472616e63652063756272697220636172726f2070756c6d6fcc816e206f"
        "726f2061cc81737065726f",
    seedVersion: ElectrumSeedUtils.kSeedPrefixSegwit,
    bip32Seed:
        "001ebce6bfde5851f28a0d44aae5ae0c762b600daf3b33fc8fc630aee0d207646b6f98"
        "b18e17dfe3be0a5efe2753c7cdad95860adbbb62cecad4dedb88e02a64",
  ),
  "spanish3": _TestCase(
    lang: "es",
    words:
        "vidrio jabón muestra pájaro capucha"
        " eludir feliz rotar fogata pez rezar oír",
    wordsHex:
        "76696472696f206a61626fcc816e206d756573747261207061cc816a61726f20636170"
        "7563686120656c756469722066656c697a20726f74617220666f67617461207065"
        "7a2072657a6172206f69cc8172",
    seedVersion: ElectrumSeedUtils.kSeedPrefixSegwit,
    passphrase:
        "¡Viva España! repiten veinte pueblos y al hablar dan fe "
        "del ánimo español... ¡Marquen arado martillo y clarín",
    passphraseHex:
        "c2a1566976612045737061c3b16121207265706974656e207665696e74652070756562"
        "6c6f73207920616c206861626c61722064616e2066652064656c20c3a16e696d6f"
        "2065737061c3b16f6c2e2e2e20c2a14d61727175656e20617261646f206d617274"
        "696c6c6f207920636c6172c3ad6e",
    bip32Seed:
        "c274665e5453c72f82b8444e293e048d700c59bf000cacfba597629d202dcf3aab1cf9"
        "c00ba8d3456b7943428541fed714d01d8a0a4028fc3a9bb33d981cb49f",
  ),
};

void main() {
  const kElectrumMnemonic =
      "party reward jealous build maze tunnel eternal candy recipe february kid animal";

  test(
    "standard seed prefix",
    () => expect(ElectrumSeedUtils.kSeedPrefix, "01"),
  );
  test(
    "segwit seed prefix",
    () => expect(ElectrumSeedUtils.kSeedPrefixSegwit, "100"),
  );
  test(
    "2fa standard seed prefix",
    () => expect(ElectrumSeedUtils.kSeedPrefix2fa, "101"),
  );
  test(
    "2fa segwit seed prefix",
    () => expect(ElectrumSeedUtils.kSeedPrefix2faSegwit, "102"),
  );

  group("electrum mnemonic to seed tests", () {
    for (final entry in kTestCases.entries) {
      final name = entry.key;
      final testCase = entry.value;

      if (testCase.wordsHex != null) {
        test("$name: mnemonic to bytes to hex", () {
          expect(testCase.wordsHex, testCase.words.toUint8ListFromUtf8.toHex);
        });
      }

      if (testCase.passphraseHex != null && testCase.passphrase != null) {
        test("$name: passphrase to bytes to hex", () {
          expect(
            testCase.passphraseHex,
            testCase.passphrase!.toUint8ListFromUtf8.toHex,
          );
        });
      }

      test("$name: isNewSeed", () {
        expect(
          ElectrumSeedUtils.isNewSeed(
            testCase.words,
            prefix: testCase.seedVersion,
          ),
          true,
        );
      });
      test("$name: electrumMnemonicToSeedBytes", () {
        expect(
          ElectrumSeedUtils.electrumMnemonicToSeedBytes(
            testCase.words,
            passphrase: testCase.passphrase ?? "",
          ).toHex,
          testCase.bip32Seed,
        );
      });
    }
  });

  test("test segwit version", () async {
    expect(
      ElectrumSeedUtils.electrumMnemonicVersion(kElectrumMnemonic),
      ElectrumSeedUtils.kSeedPrefixSegwit,
    );
  });

  group("test group requires coinlib", () {
    setUpAll(() => loadCoinlib());

    test("test master electrum fingerprint", () async {
      final bytes = ElectrumSeedUtils.electrumMnemonicToSeedBytes(
        kElectrumMnemonic,
      );
      final hd = HDPrivateKey.fromSeed(bytes);
      expect(BigInt.from(hd.fingerprint).toHex, "ec8d82aa");
    });

    test("test root zpub", () async {
      final bytes = ElectrumSeedUtils.electrumMnemonicToSeedBytes(
        kElectrumMnemonic,
      );
      final hd = HDPrivateKey.fromSeed(bytes);
      final master = hd.derivePath("m/0'");

      const zpubHDVersion =
          0x04b24746; // https://github.com/satoshilabs/slips/blob/master/slip-0132.md
      expect(
        master.hdPublicKey.encode(zpubHDVersion),
        "zpub6oHsSqJH7vSzDJTFB8NR4YpzFU13XRmkJaVW9jQTePrnf5BPHHAQXxBMiBot12Z7DqfuTykmyPxGowrQfNa7M8xiAdEvQG47V5jhx5Tk158",
      );
    });

    test("test first receiving address", () async {
      final bytes = ElectrumSeedUtils.electrumMnemonicToSeedBytes(
        kElectrumMnemonic,
      );
      final hd = HDPrivateKey.fromSeed(bytes);
      final master = hd.derivePath("m/0'");

      expect(
        P2WPKHAddress.fromHash(
          hash160(master.derivePath("0/0").publicKey.data),
          hrp: "bc",
        ).toString(),
        "bc1qgfjuzurxzhl9vdalmjgw68s680lj5q933k37h5",
      );
    });

    test("test 9th change address", () async {
      final bytes = ElectrumSeedUtils.electrumMnemonicToSeedBytes(
        kElectrumMnemonic,
      );
      final hd = HDPrivateKey.fromSeed(bytes);
      final master = hd.derivePath("m/0'");

      expect(
        P2WPKHAddress.fromHash(
          hash160(master.derivePath("1/8").publicKey.data),
          hrp: "bc",
        ).toString(),
        "bc1qzz0mvhza5sdd2fy77klh3w8h5z238avztvqjdx",
      );
    });
  });
}
