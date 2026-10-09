import 'dart:convert';

import 'package:doh_resolver/doh_resolver.dart';

final _issuer = DnsValidationIssuer('stack-test');

final testValidators = [_issuer.validator];

AuthenticatedTxtResult authenticatedTxt(String domain, List<String> records) =>
    _issuer.issueTxt(
      question: domain,
      canonicalName: domain,
      records: records
          .map(
            (s) => DnsTxtRecord(name: domain, ttl: 60, bytes: utf8.encode(s)),
          )
          .toList(),
      resolver: Uri.parse('https://resolver.example/dns-query'),
    );
