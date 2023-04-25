import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/models/paynym/created_paynym.dart';
import 'package:stackwallet/models/paynym/paynym_account.dart';
import 'package:stackwallet/models/paynym/paynym_claim.dart';
import 'package:stackwallet/models/paynym/paynym_follow.dart';
import 'package:stackwallet/models/paynym/paynym_response.dart';
import 'package:stackwallet/models/paynym/paynym_unfollow.dart';
import 'package:tuple/tuple.dart';

// todo: better error message parsing (from response itself?)

class PaynymIsApi {
  static const String baseURL = "https://paynym.is/api";
  static const String version = "/v1";

  Future<Tuple2<Map<String, dynamic>, int>> _post(
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

    debugPrint("Paynym response code: ${response.statusCode}");
    debugPrint("Paynym response body: ${response.body}");

    return Tuple2(
      jsonDecode(response.body) as Map<String, dynamic>,
      response.statusCode,
    );
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
  Future<PaynymResponse<CreatedPaynym>> create(String code) async {
    final result = await _post("/create", {"code": code});

    String message;
    CreatedPaynym? value;

    switch (result.item2) {
      case 201:
        message = "PayNym created successfully";
        value = CreatedPaynym.fromMap(result.item1);
        break;
      case 200:
        message = "PayNym already exists";
        value = CreatedPaynym.fromMap(result.item1);
        break;
      case 400:
        message = "Bad request";
        break;
      default:
        message = result.item1["message"] as String? ?? "Unknown error";
    }
    return PaynymResponse(value, result.item2, message);
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
  Future<PaynymResponse<String>> token(String code) async {
    final result = await _post("/token", {"code": code});

    String message;
    String? value;

    switch (result.item2) {
      case 200:
        message = "Token was successfully updated";
        value = result.item1["token"] as String;
        break;
      case 404:
        message = "Payment code was not found";
        break;
      case 400:
        message = "Bad request";
        break;
      default:
        message = result.item1["message"] as String? ?? "Unknown error";
    }
    return PaynymResponse(value, result.item2, message);
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
  Future<PaynymResponse<PaynymAccount>> nym(String code,
      [bool compact = false]) async {
    final Map<String, dynamic> requestBody = {"nym": code};
    if (compact) {
      requestBody["compact"] = true;
    }

    String message;
    PaynymAccount? value;
    int statusCode;

    try {
      final result = await _post("/nym", requestBody);

      statusCode = result.item2;

      switch (result.item2) {
        case 200:
          message = "Nym found and returned";
          value = PaynymAccount.fromMap(result.item1);
          break;
        case 404:
          message = "Nym not found";
          break;
        case 400:
          message = "Bad request";
          break;
        default:
          message = result.item1["message"] as String? ?? "Unknown error";
      }
    } catch (e) {
      value = null;
      message = e.toString();
      statusCode = -1;
    }
    return PaynymResponse(value, statusCode, message);
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
  Future<PaynymResponse<PaynymClaim>> claim(
    String token,
    String signature,
  ) async {
    final result = await _post(
      "/claim",
      {"signature": signature},
      {"auth-token": token},
    );

    String message;
    PaynymClaim? value;

    switch (result.item2) {
      case 200:
        message = "Payment code successfully claimed";
        value = PaynymClaim.fromMap(result.item1);
        break;
      case 400:
        message = "Bad request";
        break;
      default:
        message = result.item1["message"] as String? ?? "Unknown error";
    }
    return PaynymResponse(value, result.item2, message);
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
  Future<PaynymResponse<PaynymFollow>> follow(
    String token,
    String signature,
    String target,
  ) async {
    final result = await _post(
      "/follow",
      {
        "target": target,
        "signature": signature,
      },
      {
        "auth-token": token,
      },
    );

    String message;
    PaynymFollow? value;

    switch (result.item2) {
      case 200:
        message = "Added to followers";
        value = PaynymFollow.fromMap(result.item1);
        break;
      case 404:
        message = "Payment code not found";
        break;
      case 400:
        message = "Bad request";
        break;
      case 401:
        message = "Unauthorized token or signature or Unclaimed payment code";
        break;
      default:
        message = result.item1["message"] as String? ?? "Unknown error";
    }
    return PaynymResponse(value, result.item2, message);
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
  Future<PaynymResponse<PaynymUnfollow>> unfollow(
    String token,
    String signature,
    String target,
  ) async {
    final result = await _post(
      "/unfollow",
      {
        "target": target,
        "signature": signature,
      },
      {
        "auth-token": token,
      },
    );

    String message;
    PaynymUnfollow? value;

    switch (result.item2) {
      case 200:
        message = "Unfollowed successfully";
        value = PaynymUnfollow.fromMap(result.item1);
        break;
      case 404:
        message = "Payment code not found";
        break;
      case 400:
        message = "Bad request";
        break;
      case 401:
        message = "Unauthorized token or signature or Unclaimed payment code";
        break;
      default:
        message = result.item1["message"] as String? ?? "Unknown error";
    }
    return PaynymResponse(value, result.item2, message);
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
  Future<PaynymResponse<bool>> add(
    String token,
    String signature,
    String nym,
    String code,
  ) async {
    final result = await _post(
      "/nym/add",
      {
        "nym": nym,
        "code": code,
        "signature": signature,
      },
      {
        "auth-token": token,
      },
    );

    String message;
    bool value = false;

    switch (result.item2) {
      case 200:
        message = "Code added successfully";
        value = true;
        break;
      case 400:
        message = "Bad request";
        break;
      case 401:
        message = "Unauthorized token or signature or Unclaimed payment code";
        break;
      case 404:
        message = "Nym not found";
        break;
      default:
        message = result.item1["message"] as String? ?? "Unknown error";
    }
    return PaynymResponse(value, result.item2, message);
  }
}
