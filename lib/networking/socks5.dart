// https://github.com/v0l/socks5 https://pub.dev/packages/socks5 for Dart 3

// library socks;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stackwallet/utilities/logger.dart';

/// https://tools.ietf.org/html/rfc1928
/// https://tools.ietf.org/html/rfc1929

const SOCKSVersion = 0x05;
const RFC1929Version = 0x01;

class AuthMethods {
  static const NoAuth = AuthMethods._(0x00);
  static const GSSApi = AuthMethods._(0x01);
  static const UsernamePassword = AuthMethods._(0x02);
  static const NoAcceptableMethods = AuthMethods._(0xFF);

  final int _value;

  const AuthMethods._(this._value);

  @override
  String toString() {
    return const {
          0x00: 'AuthMethods.NoAuth',
          0x01: 'AuthMethods.GSSApi',
          0x02: 'AuthMethods.UsernamePassword',
          0xFF: 'AuthMethods.NoAcceptableMethods'
        }[_value] ??
        'Unknown AuthMethod';
  }
}

class SOCKSState {
  static const Starting = SOCKSState._(0x00);
  static const Auth = SOCKSState._(0x01);
  static const RequestReady = SOCKSState._(0x02);
  static const Connected = SOCKSState._(0x03);
  static const AuthStarted = SOCKSState._(0x04);

  final int _value;

  const SOCKSState._(this._value);

  @override
  String toString() {
    return const [
      'SOCKSState.Starting',
      'SOCKSState.Auth',
      'SOCKSState.RequestReady',
      'SOCKSState.Connected',
      'SOCKSState.AuthStarted'
    ][_value];
  }
}

class SOCKSAddressType {
  static const IPv4 = SOCKSAddressType._(0x01);
  static const Domain = SOCKSAddressType._(0x03);
  static const IPv6 = SOCKSAddressType._(0x04);

  final int _value;

  const SOCKSAddressType._(this._value);

  @override
  String toString() {
    return const [
          null,
          'SOCKSAddressType.IPv4',
          null,
          'SOCKSAddressType.Domain',
          'SOCKSAddressType.IPv6',
        ][_value] ??
        'Unknown SOCKSAddressType';
  }
}

class SOCKSCommand {
  static const Connect = SOCKSCommand._(0x01);
  static const Bind = SOCKSCommand._(0x02);
  static const UDPAssociate = SOCKSCommand._(0x03);

  final int _value;

  const SOCKSCommand._(this._value);

  @override
  String toString() {
    return const [
          null,
          'SOCKSCommand.Connect',
          'SOCKSCommand.Bind',
          'SOCKSCommand.UDPAssociate',
        ][_value] ??
        'Unknown SOCKSCommand';
  }
}

class SOCKSReply {
  static const Success = SOCKSReply._(0x00);
  static const GeneralFailure = SOCKSReply._(0x01);
  static const ConnectionNotAllowedByRuleset = SOCKSReply._(0x02);
  static const NetworkUnreachable = SOCKSReply._(0x03);
  static const HostUnreachable = SOCKSReply._(0x04);
  static const ConnectionRefused = SOCKSReply._(0x05);
  static const TTLExpired = SOCKSReply._(0x06);
  static const CommandNotSupported = SOCKSReply._(0x07);
  static const AddressTypeNotSupported = SOCKSReply._(0x08);

  final int _value;

  const SOCKSReply._(this._value);

  @override
  String toString() {
    return const [
      'SOCKSReply.Success',
      'SOCKSReply.GeneralFailure',
      'SOCKSReply.ConnectionNotAllowedByRuleset',
      'SOCKSReply.NetworkUnreachable',
      'SOCKSReply.HostUnreachable',
      'SOCKSReply.ConnectionRefused',
      'SOCKSReply.TTLExpired',
      'SOCKSReply.CommandNotSupported',
      'SOCKSReply.AddressTypeNotSupported'
    ][_value];
  }
}

class SOCKSRequest {
  final int version = SOCKSVersion;
  final SOCKSCommand command;
  final SOCKSAddressType addressType;
  final Uint8List address;
  final int port;

  String? getAddressString() {
    if (addressType == SOCKSAddressType.Domain) {
      return const AsciiDecoder().convert(address);
    } else if (addressType == SOCKSAddressType.IPv4) {
      return address.join(".");
    } else if (addressType == SOCKSAddressType.IPv6) {
      var ret = <String>[];
      for (var x = 0; x < address.length; x += 2) {
        ret.add(
            "${address[x].toRadixString(16).padLeft(2, "0")}${address[x + 1].toRadixString(16).padLeft(2, "0")}");
      }
      return ret.join(":");
    }
    return null;
  }

  SOCKSRequest({
    required this.command,
    required this.addressType,
    required this.address,
    required this.port,
  });
}

class SOCKSSocket {
  late List<AuthMethods> _auth;
  late RawSocket _sock;
  late SOCKSRequest _request;

  late StreamSubscription<RawSocketEvent> _sockSub;
  StreamSubscription<RawSocketEvent> get subscription => _sockSub;

  late SOCKSState _state;
  final StreamController<SOCKSState> _stateStream =
      StreamController<SOCKSState>();
  SOCKSState get state => _state;
  Stream<SOCKSState> get stateStream => _stateStream.stream;

  /// For username:password auth
  final String? username;
  final String? password;

  /// Waits for state to change to [SOCKSState.Connected]
  /// If the connection request returns an error from the
  /// socks server it will be thrown as an exception in the stream
  ///
  ///
  Future<SOCKSState> get _waitForConnect =>
      stateStream.firstWhere((a) => a == SOCKSState.Connected);

  SOCKSSocket(
    RawSocket socket, {
    List<AuthMethods> auth = const [AuthMethods.NoAuth],
    this.username,
    this.password,
  }) {
    _sock = socket;
    _auth = auth;
    _setState(SOCKSState.Starting);
  }

  void _setState(SOCKSState ns) {
    _state = ns;
    _stateStream.add(ns);
  }

  /// Issue connect command to proxy
  ///
  Future<void> connect(String domain) async {
    final ds = domain.split(':');
    assert(ds.length == 2, "Domain must contain port, example.com:80");

    _request = SOCKSRequest(
      command: SOCKSCommand.Connect,
      addressType: SOCKSAddressType.Domain,
      address: const AsciiEncoder().convert(ds[0]).sublist(0, ds[0].length),
      port: int.tryParse(ds[1]) ?? 80,
    );
    await _start();
    await _waitForConnect;
  }

  Future<void> connectIp(InternetAddress ip, int port) async {
    _request = SOCKSRequest(
      command: SOCKSCommand.Connect,
      addressType: ip.type == InternetAddressType.IPv4
          ? SOCKSAddressType.IPv4
          : SOCKSAddressType.IPv6,
      address: ip.rawAddress,
      port: port,
    );
    await _start();
    await _waitForConnect;
  }

  Future<void> close({bool keepOpen = true}) async {
    await _stateStream.close();
    if (!keepOpen) {
      await _sock.close();
    }
  }

  Future<void> _start() async {
    // send auth methods
    _setState(SOCKSState.Auth);
    //print(">> Version: 5, AuthMethods: $_auth");
    _sock.write([
      0x05,
      _auth.length,
      ..._auth.map((v) => v._value),
    ]);

    _sockSub = _sock.listen((RawSocketEvent ev) {
      switch (ev) {
        case RawSocketEvent.read:
          {
            final have = _sock.available();
            final data = _sock.read(have);
            if (data != null) _handleRead(data);
            break;
          }
        case RawSocketEvent.closed:
          {
            _sockSub.cancel();
            break;
          }
        case RawSocketEvent.readClosed:
          // TODO: Handle this case.
          Logging.instance.log(
              "SOCKSSocket._start(): unhandled event RawSocketEvent.readClosed",
              level: LogLevel.Warning);
          break;
        case RawSocketEvent.write:
          // TODO: Handle this case.
          Logging.instance.log(
              "SOCKSSocket._start(): unhandled event RawSocketEvent.write",
              level: LogLevel.Warning);
          break;
      }
    });
  }

  void _sendUsernamePassword(String uname, String password) {
    if (uname.length > 255 || password.length > 255) {
      throw "Username or Password is too long";
    }

    final data = [
      RFC1929Version,
      uname.length,
      ...const AsciiEncoder().convert(uname),
      password.length,
      ...const AsciiEncoder().convert(password)
    ];

    //print(">> Sending $username:$password");
    _sock.write(data);
  }

  void _handleRead(Uint8List data) async {
    if (state == SOCKSState.Auth) {
      if (data.length == 2) {
        // final version = data[0];
        //print("<< Version: $version, Auth: $auth");
        final auth = AuthMethods._(data[1]);

        if (auth._value == AuthMethods.UsernamePassword._value) {
          _setState(SOCKSState.AuthStarted);
          _sendUsernamePassword(username ?? '', password ?? '');
          // TODO check that passing an empty string is valid (vs. null previously)
        } else if (auth._value == AuthMethods.NoAuth._value) {
          _setState(SOCKSState.RequestReady);
          _writeRequest(_request);
        } else if (auth._value == AuthMethods.NoAcceptableMethods._value) {
          throw "No auth methods acceptable";
        }
      } else {
        throw "Expected 2 bytes";
      }
    } else if (_state == SOCKSState.AuthStarted) {
      if (_auth.contains(AuthMethods.UsernamePassword)) {
        final version = data[0];
        final status = data[1];

        if (version != RFC1929Version || status != 0x00) {
          throw "Invalid username or password";
        } else {
          _setState(SOCKSState.RequestReady);
          _writeRequest(_request);
        }
      }
    } else if (_state == SOCKSState.RequestReady) {
      if (data.length >= 10) {
        final reply = SOCKSReply._(data[1]);
        //data[2] reserved

        final version = data[0];
        final addrType = SOCKSAddressType._(data[3]);
        Uint8List? addr;
        var port = 0;
        if (addrType == SOCKSAddressType.Domain) {
          final len = data[4];
          addr = data.sublist(5, 5 + len);
          port = data[5 + len] << 8 | data[6 + len];
        } else if (addrType == SOCKSAddressType.IPv4) {
          addr = data.sublist(5, 9);
          port = data[9] << 8 | data[10];
        } else if (addrType == SOCKSAddressType.IPv6) {
          addr = data.sublist(5, 21);
          port = data[21] << 8 | data[22];
        }
        print(
            "<< Version: $version, Reply: $reply, AddrType: $addrType, Addr: $addr, Port: $port");

        if (reply._value == SOCKSReply.Success._value) {
          _setState(SOCKSState.Connected);
        } else {
          throw reply;
        }
      } else {
        throw "Expected 10 bytes";
      }
    }
  }

  void _writeRequest(SOCKSRequest req) {
    if (_state == SOCKSState.RequestReady) {
      final data = [
        req.version,
        req.command._value,
        0x00,
        req.addressType._value,
        if (req.addressType == SOCKSAddressType.Domain)
          req.address.lengthInBytes,
        ...req.address,
        req.port >> 8,
        req.port & 0xF0,
      ];

      //print(">> Version: ${req.version}, Command: ${req.command}, AddrType: ${req.addressType}, Addr: ${req.getAddressString()}, Port: ${req.port}");
      _sock.write(data);
    } else {
      throw "Must be in RequestReady state, current state $_state";
    }
  }

  void write(Object? object) {
    _sock.write(utf8.encode(object.toString()));
    // TODO make sure the is correct; see _writeRequest above, may need to construct a SOCKSRequest from the data coming in
  }
}
