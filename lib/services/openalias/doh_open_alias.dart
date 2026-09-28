import 'dart:convert';
import 'dart:io';

import 'dns_proxy_connection.dart';
import 'open_alias.dart';

class DohOpenAlias {
  Future<List<String>> lookup(
    String domain, {
    required ({InternetAddress host, int port})? proxyInfo,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final tunnels = <DnsProxyConnection>[];
    try {
      if (proxyInfo != null) {
        client.connectionFactory = (uri, _, _) async {
          final task = DnsProxyConnection(proxyInfo.host, proxyInfo.port);
          tunnels.add(task);
          return ConnectionTask.fromSocket(task.socket, task.cancel);
        };
      }
      return await _request(
        client,
        domain,
      ).timeout(const Duration(seconds: 12));
    } on OpenAliasException {
      rethrow;
    } catch (_) {
      throw const OpenAliasException(
        'OpenAlias lookup failed. Check your connection and try again.',
      );
    } finally {
      client.close(force: true);
      for (final task in tunnels) {
        task.cancel();
      }
    }
  }

  Future<List<String>> _request(HttpClient client, String domain) async {
    final uri = Uri.https('dns.google', '/resolve', {
      'name': '$domain.',
      'type': 'TXT',
      'do': 'true',
      'cd': 'false',
      'edns_client_subnet': '0.0.0.0/0',
    });
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    request.headers.set('Accept', 'application/dns-json');
    final response = await request.close();
    if (response.statusCode != 200) {
      throw const OpenAliasException(
        'The DNS resolver is unavailable. Try again later.',
      );
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > 65536) {
        throw const OpenAliasException('The DNS response is too large.');
      }
      bytes.addAll(chunk);
    }
    return decodeAuthenticatedDns(jsonDecode(utf8.decode(bytes)), domain);
  }
}

String _dnsName(Object? value) {
  if (value is! String || value.contains('@')) {
    throw const OpenAliasException('Invalid DNS response.');
  }
  return normalizeOpenAlias(value);
}

List<String> decodeAuthenticatedDns(Object? body, String domain) {
  if (body is! Map<String, dynamic>) {
    throw const OpenAliasException('Invalid DNS response.');
  }
  if (body['Status'] != 0) {
    throw const OpenAliasException(
      'DNS lookup failed or no record exists. No address was accepted.',
    );
  }
  if (body['AD'] != true || body['CD'] != false || body['TC'] != false) {
    throw const OpenAliasException(
      'DNSSEC verification failed or is unavailable. '
      'Ask the recipient for a verified alias or address.',
    );
  }
  final questions = body['Question'];
  if (questions is! List ||
      questions.length != 1 ||
      questions.single is! Map ||
      questions.single['type'] != 16 ||
      _dnsName(questions.single['name']) != domain) {
    throw const OpenAliasException(
      'The DNS response does not match this alias.',
    );
  }
  final answers = body['Answer'];
  if (answers == null) return [];
  if (answers is! List ||
      answers.length > 64 ||
      answers.any((a) => a is! Map)) {
    throw const OpenAliasException('Invalid DNS response.');
  }
  final visited = <String>{};
  var owner = domain;
  for (var i = 0; i < 8; i++) {
    if (!visited.add(owner)) {
      throw const OpenAliasException('The alias has a DNS loop.');
    }
    final atOwner = answers.where((a) => _dnsName(a['name']) == owner).toList();
    final cnames = atOwner.where((a) => a['type'] == 5).toList();
    final txt = atOwner.where((a) => a['type'] == 16).toList();
    if (cnames.isEmpty) {
      return txt.map((a) {
        if (a['data'] is! String || a['TTL'] is! int || (a['TTL'] as int) < 0) {
          throw const OpenAliasException('Invalid TXT record.');
        }
        return decodeDnsTxt(a['data'] as String);
      }).toList();
    }
    if (cnames.length != 1 || txt.isNotEmpty) {
      throw const OpenAliasException('The DNS alias is ambiguous.');
    }
    owner = _dnsName(cnames.single['data']);
  }
  throw const OpenAliasException('The DNS alias chain is too long.');
}

String decodeDnsTxt(String value) {
  if (value.length > 8192) {
    throw const OpenAliasException('The TXT record is too large.');
  }
  if (!value.startsWith('"')) return value;
  final out = StringBuffer();
  var i = 0;
  while (i < value.length) {
    while (i < value.length && value[i] == ' ') {
      i++;
    }
    if (i == value.length) break;
    if (value[i++] != '"') {
      throw const OpenAliasException('Malformed DNS TXT encoding.');
    }
    var closed = false;
    while (i < value.length) {
      final char = value[i++];
      if (char == '"') {
        closed = true;
        break;
      }
      if (char != '\\') {
        out.write(char);
        continue;
      }
      if (i >= value.length) {
        throw const OpenAliasException('Malformed DNS TXT escape.');
      }
      if (RegExp(r'[0-9]').hasMatch(value[i])) {
        if (i + 3 > value.length) {
          throw const OpenAliasException('Malformed DNS TXT escape.');
        }
        final octet = int.tryParse(value.substring(i, i + 3));
        if (octet == null || octet > 255) {
          throw const OpenAliasException('Malformed DNS TXT escape.');
        }
        out.writeCharCode(octet);
        i += 3;
      } else {
        out.write(value[i++]);
      }
    }
    if (!closed) throw const OpenAliasException('Malformed DNS TXT encoding.');
  }
  return out.toString();
}
