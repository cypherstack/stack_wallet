import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stackwallet/models/paynym/created_paynym.dart';
import 'package:stackwallet/models/paynym/paynym_account.dart';

class PaynymAPI {
  static const String baseURL = "https://paynym.is/api";
  static const String version = "/v1";

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body, [
    Map<String, String> additionalHeaders = const {},
  ]) async {
    String url = baseURL +
        version +
        (endpoint.startsWith("/") ? endpoint : "/$endpoint");
    final uri = Uri.parse(url);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      }..addAll(additionalHeaders),
      body: jsonEncode(body),
    );

    // print("response code: ${response.statusCode}");

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ### `/api/v1/create`
  //
  // Create a new PayNym entry in the database.
  //
  //
  //
  // **Request**
  //
  // ```json
  // POST /api/v1/create
  // content-type: application/json
  //
  // {
  // "code":"PM8T..."
  // }
  //
  // ```
  //
  // | Value | Key                  |
  // | ----- | -------------------- |
  // | code  | A valid payment code |
  //
  //
  //
  // **Response** (201)
  //
  // ```json
  // {
  // "claimed": false,
  // "nymID": "v9pJm...",
  // "nymName": "snowysea",
  // "segwit": true,
  // "token": "IlBNOF...",
  // }
  // ```
  //
  // | Code | Meaning                     |
  // | ---- | --------------------------- |
  // | 201  | PayNym created successfully |
  // | 200  | PayNym already exists       |
  // | 400  | Bad request                 |
  //
  //
  //
  // ------
  Future<CreatedPaynym> create(String code) async {
    final map = await _post("/create", {"code": code});
    return CreatedPaynym.fromMap(map);
  }

  // ### `/api/v1/token`
  //
  // Update the verification token in the database. A token is valid for 24 hours and only for a single authenticated call. The payment code must be in the database or the request will return `404`
  //
  //
  //
  // **Request**
  //
  // ```json
  // POST /api/v1/token/
  // content-type: application/json
  //
  // {"code":"PM8T..."}
  // ```
  //
  // | Value | Key                  |
  // | ----- | -------------------- |
  // | code  | A valid payment code |
  //
  //
  //
  // **Response** (200)
  //
  // ```json
  // {
  // "token": "DP7S3w..."
  // }
  // ```
  //
  // | Code | Meaning                        |
  // | ---- | ------------------------------ |
  // | 200  | Token was successfully updated |
  // | 404  | Payment code was not found     |
  // | 400  | Bad request                    |
  //
  //
  //
  // ------
  Future<String> token(String code) async {
    final map = await _post("/token", {"code": code});
    return map["token"] as String;
  }

  // ### `/api/v1/nym`
  //
  // Returns all known information about a PayNym account including any other payment codes associated with this Nym.
  //
  //
  //
  // **Request**
  //
  // ```json
  // POST /api/v1/nym/
  // content-type: application/json
  //
  // {"nym":"PM8T..."}
  // ```
  //
  // | Value | Key                                      |
  // | ----- | ---------------------------------------- |
  // | nym   | A valid payment `code`, `nymID`, or `nymName` |
  //
  //
  //
  // **Response** (200)
  //
  // ```json
  // {
  // "codes": [
  // {
  // "claimed": true,
  // "segwit": true,
  // "code": "PM8T..."
  // }
  // ],
  // "followers": [
  // {
  // "nymId": "5iEpU..."
  // }
  // ],
  // "following": [],
  // "nymID": "wXGgdC...",
  // "nymName": "littlevoice"
  // }
  // ```
  //
  // If the `compact=true` parameter is added to the URL, follower and following will not returned. This can achieve faster requests.
  //
  // | Code | Meaning                |
  // | ---- | ---------------------- |
  // | 200  | Nym found and returned |
  // | 404  | Nym not found          |
  // | 400  | Bad request            |

  Future<PaynymAccount?> nym(String code) async {
    final map = await _post("/nym", {"nym": code});
    try {
      return PaynymAccount.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  // ## Authenticated Requests
  //
  //
  //
  // ### Making authenticated requests
  //
  // 1. Set an `auth-token` header containing the `token`
  // 2. Sign the `token` with the private key of the notification address of the primary payment code
  // 3. Add the `signature` to the body of the request.
  // 4. A token can only be used once per authenticated request. A new `token` will be returned in the response of a successful authenticated request
  //

  // ### `/api/v1/claim`
  //
  // Claim ownership of a payment code added to a newly created PayNym identity.
  //
  //
  //
  // **Request**
  //
  // ```json
  // POST /api/v1/claim
  // content-type: application/json
  // auth-token: IlBNOFRKWmt...
  //
  //
  // {"signature":"..."}
  // ```
  //
  // | Value     | Key                                      |
  // | --------- | ---------------------------------------- |
  // | signature | The `token` signed by the BIP47 notification address |
  //
  //
  //
  // **Response** (200)
  //
  // ```json
  // {
  // "claimed" : "PM8T...",
  // "token" : "IlBNOFRKSmt..."
  // }
  // ```
  //
  // | Code | Meaning                           |
  // | ---- | --------------------------------- |
  // | 200  | Payment code successfully claimed |
  // | 400  | Bad request                       |
  //
  // ------
  Future<Map<String, dynamic>> claim(String token, String signature) async {
    return _post("/claim", {"signature": signature}, {"auth-token": token});
  }

  // ### `/api/v1/follow`
  //
  // Follow another PayNym account.
  //
  //
  //
  // **Request**
  //
  // ```json
  // POST /api/v1/follow/
  // content-type: application/json
  // auth-token: IlBNOFRKWmt...
  //
  // {
  // "target": "wXGgdC...",
  // "signature":"..."
  // }
  // ```
  //
  // | Key       | Value                                    |
  // | --------- | ---------------------------------------- |
  // | target    | The payment code to follow               |
  // | signature | The `token` signed by the BIP47 notification address |
  //
  // **Response** (200)
  //
  // ```json
  // {
  // "follower": "5iEpU...",
  // "following": "wXGgdC...",
  // "token" : "IlBNOFRKSmt..."
  // }
  // ```
  //
  // | Code | Meaning                                  |
  // | ---- | ---------------------------------------- |
  // | 200  | Added to followers                       |
  // | 404  | Payment code not found                   |
  // | 400  | Bad request                              |
  // | 401  | Unauthorized token or signature or Unclaimed payment code |
  //
  // ------
  Future<Map<String, dynamic>> follow(
    String token,
    String signature,
    String target,
  ) async {
    return _post(
      "/follow",
      {
        "target": target,
        "signature": signature,
      },
      {
        "auth-token": token,
      },
    );
  }

  // ### `/api/v1/unfollow`
  //
  // Unfollow another PayNym account.
  //
  //
  //
  // **Request**
  //
  // ```json
  // POST /api/v1/unfollow/
  // content-type: application/json
  // auth-token: IlBNOFRKWmt...
  //
  // {
  // "target": "wXGgdC...",
  // "signature":"..."
  // }
  // ```
  //
  // | Key       | Value                                    |
  // | --------- | ---------------------------------------- |
  // | target    | The payment code to unfollow             |
  // | signature | The `token` signed by the BIP47 notification address |
  //
  // **Response** (200)
  //
  // ```json
  // {
  // "follower": "5iEpU...",
  // "unfollowing": "wXGgdC...",
  // "token" : "IlBNOFRKSmt..."
  // }
  // ```
  //
  // | Code | Meaning                                  |
  // | ---- | ---------------------------------------- |
  // | 200  | Unfollowed successfully                  |
  // | 404  | Payment code not found                   |
  // | 400  | Bad request                              |
  // | 401  | Unauthorized token or signature or Unclaimed payment code |
  //
  // ------
  Future<Map<String, dynamic>> unfollow(
    String token,
    String signature,
    String target,
  ) async {
    return _post(
      "/unfollow",
      {
        "target": target,
        "signature": signature,
      },
      {
        "auth-token": token,
      },
    );
  }

  // ### `/api/v1/nym/add`
  //
  // Add a new payment code to an existing Nym
  //
  //
  //
  // **Request**
  //
  // ```json
  // POST /api/v1/nym/add
  // content-type: application/json
  // auth-token: IlBNOFRKWmt...
  //
  // {
  // "nym": "wXGgdC...",
  // "code":"PM8T...",
  // "signature":"..."
  // }
  // ```
  //
  // | Key       | Value                                                        |
  // | --------- | ------------------------------------------------------------ |
  // | nym       | A valid payment `code`, `nymID`, or `nymName`                |
  // | code      | A valid payment code                                         |
  // | signature | The `token` signed by the BIP47 notification address of the primary payment code. |
  //
  // **Response** (200)
  //
  // ```json
  // {
  // "code":"PM8T...",
  // "segwit": true,
  // "token" : "IlBNOFRKSmt..."
  // }
  // ```
  //
  // | Code | Meaning                                                   |
  // | ---- | --------------------------------------------------------- |
  // | 200  | Nym updated successfully                                  |
  // | 404  | Nym not found                                             |
  // | 400  | Bad request                                               |
  // | 401  | Unauthorized token or signature or Unclaimed payment code |
  //
  // ------
  Future<Map<String, dynamic>> add(
    String token,
    String signature,
    String nym,
    String code,
  ) async {
    return _post(
      "/add",
      {
        "nym": nym,
        "code": code,
        "signature": signature,
      },
      {
        "auth-token": token,
      },
    );
  }
}
