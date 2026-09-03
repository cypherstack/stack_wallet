import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/node_uri_util.dart';

void main() {
  test("Valid xmrrpc scheme node uri", () {
    expect(
      NodeQrUtil.decodeUri(
        "xmrrpc://nodo:password@bob.onion:18083?label=Nodo Tor Node",
      ),
      isA<MoneroNodeQrData>(),
    );
  });

  test("Valid wowrpc scheme node uri", () {
    expect(
      NodeQrUtil.decodeUri("wowrpc://nodo:password@10.0.0.10:18083"),
      isA<WowneroNodeQrData>(),
    );
  });

  test("Node uri requires an explicit port", () {
    expect(() => NodeQrUtil.decodeUri("xmrrpc://bob.onion:0"), throwsException);
    expect(() => NodeQrUtil.decodeUri("xmrrpc://bob.onion"), throwsException);
    expect(() => NodeQrUtil.decodeUri("wowrpc://bob.onion"), throwsException);
    expect(NodeQrUtil.decodeUri("xmrrpc://bob.onion:18083").port, 18083);
  });

  test("Invalid authority node uri", () {
    String? message;
    try {
      NodeQrUtil.decodeUri("nodo:password@bob.onion:18083?label=Nodo Tor Node");
    } catch (e) {
      message = e.toString();
    }
    expect(message, "Exception: Uri has no authority.");
  });

  test("Empty uri string", () {
    String? message;
    try {
      NodeQrUtil.decodeUri("");
    } catch (e) {
      message = e.toString();
    }
    expect(message, "Exception: Uri has no authority.");
  });

  test("Invalid uri string", () {
    String? message;
    try {
      NodeQrUtil.decodeUri("::invalid@@@.ok");
    } catch (e) {
      message = e.toString();
    }
    expect(message, "Exception: Invalid uri string.");
  });

  test("Unknown uri string", () {
    String? message;
    try {
      NodeQrUtil.decodeUri("http://u:p@host.com:80/lol?hmm=42");
    } catch (e) {
      message = e.toString();
    }
    expect(message, "Exception: Unknown node uri scheme \"http\" found.");
  });

  test("decoding to model", () {
    final data = NodeQrUtil.decodeUri(
      "xmrrpc://nodo:password@bob.onion:18083?label=Nodo+Tor+Node",
    );
    expect(data.scheme, "xmrrpc");
    expect(data.host, "bob.onion");
    expect(data.port, 18083);
    expect(data.label, "Nodo Tor Node");
    expect((data as MoneroNodeQrData?)?.user, "nodo");
    expect((data as MoneroNodeQrData?)?.password, "password");
  });

  test("encoding to string", () {
    const validString =
        "xmrrpc://nodo:password@bob.onion:18083?label=Nodo+Tor+Node";
    final data = NodeQrUtil.decodeUri(validString);
    expect(data.encode(), validString);
  });

  test("normal to string", () {
    const validString =
        "xmrrpc://nodo:password@bob.onion:18083?label=Nodo+Tor+Node";
    final data = NodeQrUtil.decodeUri(validString);
    expect(
      data.toString(),
      "MoneroNodeQrData {"
      "scheme: xmrrpc, "
      "host: bob.onion, "
      "port: 18083, "
      "user: nodo, "
      "password: password, "
      "label: Nodo Tor Node"
      "}",
    );
  });

  test("node port validation", () {
    expect(isValidNodePort(null), false);
    expect(isValidNodePort(0), false);
    expect(isValidNodePort(-1), false);
    expect(isValidNodePort(65536), false);
    expect(isValidNodePort(1), true);
    expect(isValidNodePort(18081), true);
    expect(isValidNodePort(65535), true);
  });
}
