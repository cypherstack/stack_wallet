import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';
import 'package:stackwallet/services/coins/bitcoincash/cashtokens.dart';

void main() {
  // Just a testing function which can be called in standalone fashion.
  // Replace "var1" with a hex string containing an output (script pub key)
  test("testUnwrapSPK", () {
    // Example Hex format string
    final String var1 = "76a91463456150b05a67084d795fbce22c8fbbca37697288ac";
    // Convert the Hex string to Uint8List
    final Uint8List wrapped_spk = Uint8List.fromList(HEX.decode(var1));

    // Call unwrap_spk
    final ParsedOutput parsedOutput = unwrap_spk(wrapped_spk);

    print("Parsed Output: $parsedOutput");

    // Access token_data inside parsedOutput
    final TokenOutputData? tokenData = parsedOutput.token_data;

    // Check if tokenData is null
    if (tokenData != null) {
      // Print specific fields
      if (tokenData.id != null) {
        print("ID: ${hex.encode(tokenData.id!)}"); // hex is imported
      } else {
        print("ID: null");
      }
      print("amount of tokens");
      print(tokenData.amount);
      print("Is it an NFT?: ${tokenData.hasNFT()}");
    } else {
      print("Token data is null.");
    }
  });
}
