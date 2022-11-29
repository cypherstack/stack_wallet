import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:epicmobile/utilities/format.dart';
import 'package:epicmobile/utilities/logger.dart';
import 'package:epicmobile/widgets/desktop/primary_button.dart';
import 'package:epicmobile/widgets/desktop/secondary_button.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';

class MoneroNodeConnectionResponse {
  final X509Certificate? cert;
  final String? url;
  final int? port;
  final bool success;

  MoneroNodeConnectionResponse(this.cert, this.url, this.port, this.success);
}

Future<MoneroNodeConnectionResponse> testMoneroNodeConnection(
  Uri uri,
  bool allowBadX509Certificate,
) async {
  final client = HttpClient();
  MoneroNodeConnectionResponse? badCertResponse;
  try {
    client.badCertificateCallback = (cert, url, port) {
      if (allowBadX509Certificate) {
        return true;
      }

      if (badCertResponse == null) {
        badCertResponse = MoneroNodeConnectionResponse(cert, url, port, false);
      } else {
        return false;
      }

      return false;
    };

    final request = await client.postUrl(uri);

    final body = utf8.encode(
      jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        "method": "get_info",
      }),
    );

    request.headers.add(
      'Content-Length',
      body.length.toString(),
      preserveHeaderCase: true,
    );
    request.headers.set(
      'Content-Type',
      'application/json',
      preserveHeaderCase: true,
    );

    request.add(body);

    final response = await request.close();
    final result = await response.transform(utf8.decoder).join();
    // TODO: json decoded without error so assume connection exists?
    // or we can check for certain values in the response to decide
    return MoneroNodeConnectionResponse(null, null, null, true);
  } catch (e, s) {
    if (badCertResponse != null) {
      return badCertResponse!;
    } else {
      Logging.instance.log("$e\n$s", level: LogLevel.Warning);
      return MoneroNodeConnectionResponse(null, null, null, false);
    }
  } finally {
    client.close(force: true);
  }
}

Future<bool> showBadX509CertificateDialog(
  X509Certificate cert,
  String url,
  int port,
  BuildContext context,
) async {
  final chars = Format.uint8listToString(cert.sha1)
      .toUpperCase()
      .characters
      .toList(growable: false);

  String sha1 = chars.sublist(0, 2).join();
  for (int i = 2; i < chars.length; i += 2) {
    sha1 += ":${chars.sublist(i, i + 2).join()}";
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StackDialog(
        title: "Untrusted X509Certificate",
        message: "SHA1:\n$sha1",
        leftButton: SecondaryButton(
          label: "Cancel",
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        rightButton: PrimaryButton(
          label: "Trust",
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      );
    },
  );

  return result ?? false;
}
