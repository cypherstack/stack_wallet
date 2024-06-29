import 'dart:typed_data';

// The Structure enum
enum Structure {
  HasAmount,
  HasNFT,
  HasCommitmentLength,
}

// The Capability enum
enum Capability {
  NoCapability,
  Mutable,
  Minting,
}

// Used as a "custom tuple" for the supporting functions of readCompactSize to return
// a convenient data structure.
class CompactSizeResult {
  final int amount;
  final int bytesRead;

  CompactSizeResult({required this.amount, required this.bytesRead});
}

// This class is a data structure representing the entire output, comprised of both the
// normal Script pub key and the token data.  We get this after we parse/unwrap the raw
// output.
class ParsedOutput {
  List<int>? script_pub_key;
  TokenOutputData? token_data;
  ParsedOutput({this.script_pub_key, this.token_data});
}

// This is equivalent to the Electron Cash python's "OutputData" in token.py.
// Named here specifically as "TokenOutputData" to reflect the fact that
// it is specifically for tokens, whereas the other class ParsedOutput represents
// the entire output, comprised of both the normal Script pub key and the token data.
class TokenOutputData {
  Uint8List? id;
  int? amount;
  Uint8List? commitment;
  Uint8List? bitfield; // A byte (Uint8List of length 1)

  // Constructor
  TokenOutputData({
    this.id,
    this.amount,
    this.commitment,
    this.bitfield,
  });

  // Get the "capability", see Capability enum.
  int getCapability() {
    if (bitfield != null) {
      return bitfield![0] & 0x0f;
    }
    return 0;
  }

  // functions to return attributes of the token bitfield.
  bool hasCommitmentLength() {
    if (bitfield != null) {
      return (bitfield![0] & 0x40) != 0;
    }
    return false;
  }

  bool hasAmount() {
    if (bitfield != null) {
      return (bitfield![0] & 0x10) != 0;
    }
    return false;
  }

  bool hasNFT() {
    if (bitfield != null) {
      return (bitfield![0] & 0x20) != 0;
    }
    return false;
  }

  // Functions to return specific attributes based on the Capability.
  bool isMintingNFT() {
    return hasNFT() && getCapability() == Capability.Minting.index;
  }

  bool isMutableNFT() {
    return hasNFT() && getCapability() == Capability.Mutable.index;
  }

  bool isImmutableNFT() {
    return hasNFT() && getCapability() == Capability.NoCapability.index;
  }

  // This function validates if the bitfield makes sense or violates known rules/logic.
  bool isValidBitfield() {
    if (bitfield == null) {
      return false;
    }

    final int s = bitfield![0] & 0xf0;
    if (s >= 0x80 || s == 0x00) {
      return false;
    }
    if (bitfield![0] & 0x0f > 2) {
      return false;
    }
    if (!hasNFT() && !hasAmount()) {
      return false;
    }
    if (!hasNFT() && (bitfield![0] & 0x0f) != 0) {
      return false;
    }
    if (!hasNFT() && hasCommitmentLength()) {
      return false;
    }
    return true;
  }

  // The serialze and deserialize functions are the nuts and bolts of how we unpack
  // and pack outputs.  These are called by the wrap and unwrap functions.
  int deserialize(Uint8List buffer, {int cursor = 0, bool strict = false}) {
    try {
      id = buffer.sublist(cursor, cursor + 32);
      cursor += 32;

      bitfield = Uint8List.fromList([buffer[cursor]]);
      cursor += 1;

      if (hasCommitmentLength()) {
        // Read the first byte to determine the length of the commitment data
        final int commitmentLength = buffer[cursor];

        // Move cursor to the next byte
        cursor += 1;

        // Read 'commitmentLength' bytes for the commitment data
        commitment = buffer.sublist(cursor, cursor + commitmentLength);

        // Adjust the cursor by the length of the commitment data
        cursor += commitmentLength;
      } else {
        commitment = null;
      }

      if (hasAmount()) {
        // Use readCompactSize that returns CompactSizeResult
        final CompactSizeResult result =
            readCompactSize(buffer, cursor, strict: strict);
        amount = result.amount;
        cursor += result.bytesRead;
      } else {
        amount = 0;
      }

      if (!isValidBitfield() ||
          (hasAmount() && amount == 0) ||
          (amount! < 0 || amount! > (1 << 63) - 1) ||
          (hasCommitmentLength() && commitment!.isEmpty) ||
          (amount! == 0 && !hasNFT())) {
        throw Exception('Unable to parse token data or token data is invalid');
      }

      return cursor; // Return the number of bytes read
    } catch (e) {
      throw Exception('Deserialization failed: $e');
    }
  }

  // Serialize method
  Uint8List serialize() {
    final buffer = BytesBuilder();

    // write ID and bitfield
    buffer.add(id!);
    buffer.addByte(bitfield![0]);

    // Write optional fields
    if (hasCommitmentLength()) {
      buffer.add(commitment!);
    }

    if (hasAmount()) {
      final List<int> compactSizeBytes = writeCompactSize(amount!);
      buffer.add(compactSizeBytes);
    }

    return buffer.toBytes();
  }
} //END OF OUTPUTDATA CLASS

// The prefix byte is specified by the CashTokens spec.
final List<int> PREFIX_BYTE = [0xef];

// This function wraps a "normal" output together with token data.
ParsedOutput wrap_spk(TokenOutputData? token_data, Uint8List script_pub_key) {
  final ParsedOutput parsedOutput = ParsedOutput();

  if (token_data == null) {
    parsedOutput.script_pub_key = script_pub_key;
    return parsedOutput;
  }

  final buf = BytesBuilder();

  buf.add(PREFIX_BYTE);
  buf.add(token_data.serialize());
  buf.add(script_pub_key);

  parsedOutput.script_pub_key = buf.toBytes();
  parsedOutput.token_data = token_data;

  return parsedOutput;
}

// This function unwraps any output, either "normal" (containing no token data)
// or an output with token data.  If no token data, just the output is returned,
// and if token data exists, both the output and token data are returned.
// Note that the data returend in both cases in of ParsedOutput type, which
// holds both the script pub key and token data.
ParsedOutput unwrap_spk(Uint8List wrapped_spk) {
  final ParsedOutput parsedOutput = ParsedOutput();

  if (wrapped_spk.isEmpty || wrapped_spk[0] != PREFIX_BYTE[0]) {
    parsedOutput.script_pub_key = wrapped_spk;
    return parsedOutput;
  }

  int read_cursor = 1; // Start after the PREFIX_BYTE
  final TokenOutputData token_data = TokenOutputData();

  Uint8List wrapped_spk_without_prefix_byte;
  try {
    // Deserialize updates read_cursor by the number of bytes read

    wrapped_spk_without_prefix_byte = wrapped_spk.sublist(read_cursor);
    final int bytesRead =
        token_data.deserialize(wrapped_spk_without_prefix_byte);

    read_cursor += bytesRead;
    parsedOutput.token_data = token_data;
    parsedOutput.script_pub_key = wrapped_spk.sublist(read_cursor);
  } catch (e) {
    // If unable to deserialize, return all bytes as the full scriptPubKey
    parsedOutput.script_pub_key = wrapped_spk;
  }

  return parsedOutput;
}

// HELPER FUNCTIONS

//These are part of a "length value " scheme where the length (and endianness) are given first
// and inform the program of how many bytes to grab next.  These are in turn used by the serialize
// and deserialize functions.-
CompactSizeResult readCompactSize(
  Uint8List buffer,
  int cursor, {
  bool strict = false,
}) {
  int bytesRead = 0; // Variable to count bytes read
  int val;
  try {
    val = buffer[cursor];
    cursor += 1;
    bytesRead += 1;
    int minVal;
    if (val == 253) {
      val = buffer.buffer.asByteData().getUint16(cursor, Endian.little);
      cursor += 2;
      bytesRead += 2;
      minVal = 253;
    } else if (val == 254) {
      val = buffer.buffer.asByteData().getUint32(cursor, Endian.little);
      cursor += 4;
      bytesRead += 4;
      minVal = 1 << 16;
    } else if (val == 255) {
      val = buffer.buffer.asByteData().getInt64(cursor, Endian.little);
      cursor += 8;
      bytesRead += 8;
      minVal = 1 << 32;
    } else {
      minVal = 0;
    }
    if (strict && val < minVal) {
      throw Exception("CompactSize is not minimally encoded");
    }

    return CompactSizeResult(amount: val, bytesRead: bytesRead);
  } catch (e) {
    throw Exception("attempt to read past end of buffer");
  }
}

Uint8List writeCompactSize(int size) {
  final buffer = ByteData(9); // Maximum needed size for compact size is 9 bytes
  if (size < 0) {
    throw Exception("attempt to write size < 0");
  } else if (size < 253) {
    return Uint8List.fromList([size]);
  } else if (size < (1 << 16)) {
    buffer.setUint8(0, 253);
    buffer.setUint16(1, size, Endian.little);
    return buffer.buffer.asUint8List(0, 3);
  } else if (size < (1 << 32)) {
    buffer.setUint8(0, 254);
    buffer.setUint32(1, size, Endian.little);
    return buffer.buffer.asUint8List(0, 5);
  } else if (size < (1 << 64)) {
    buffer.setUint8(0, 255);
    buffer.setInt64(1, size, Endian.little);
    return buffer.buffer.asUint8List(0, 9);
  } else {
    throw Exception("Size too large to represent as CompactSize");
  }
}
