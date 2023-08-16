import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// https://tools.ietf.org/html/rfc1928
/// https://tools.ietf.org/html/rfc1929
///

const SOCKSVersion = 0x05;
const RFC1929Version = 0x01;

enum AuthMethods {
  NoAuth(0x00),
  GSSApi(0x01),
  UsernamePassword(0x02),
  NoAcceptableMethods(0xFF);

  final int rawValue;

  const AuthMethods(this.rawValue);

  factory AuthMethods.fromValue(int value) {
    for (final v in values) {
      if (v.rawValue == value) {
        return v;
      }
    }
    throw UnsupportedError("Invalid AuthMethods value");
  }

  @override
  String toString() => "$runtimeType.$name";
}

enum SOCKSState {
  Starting(0x00),
  Auth(0x01),
  RequestReady(0x02),
  Connected(0x03),
  AuthStarted(0x04);

  final int rawValue;

  const SOCKSState(this.rawValue);

  factory SOCKSState.fromValue(int value) {
    for (final v in values) {
      if (v.rawValue == value) {
        return v;
      }
    }
    throw UnsupportedError("Invalid SOCKSState value");
  }

  @override
  String toString() => "$runtimeType.$name";
}

enum SOCKSAddressType {
  IPv4(0x01),
  Domain(0x03),
  IPv6(0x04);

  final int rawValue;

  const SOCKSAddressType(this.rawValue);

  factory SOCKSAddressType.fromValue(int value) {
    for (final v in values) {
      if (v.rawValue == value) {
        return v;
      }
    }
    throw UnsupportedError("Invalid SOCKSAddressType value");
  }

  @override
  String toString() => "$runtimeType.$name";
}

enum SOCKSCommand {
  Connect(0x01),
  Bind(0x02),
  UDPAssociate(0x03);

  final int rawValue;

  const SOCKSCommand(this.rawValue);

  factory SOCKSCommand.fromValue(int value) {
    for (final v in values) {
      if (v.rawValue == value) {
        return v;
      }
    }
    throw UnsupportedError("Invalid SOCKSCommand value");
  }

  @override
  String toString() => "$runtimeType.$name";
}

enum SOCKSReply {
  Success(0x00),
  GeneralFailure(0x01),
  ConnectionNotAllowedByRuleSet(0x02),
  NetworkUnreachable(0x03),
  HostUnreachable(0x04),
  ConnectionRefused(0x05),
  TTLExpired(0x06),
  CommandNotSupported(0x07),
  AddressTypeNotSupported(0x08);

  final int rawValue;

  const SOCKSReply(this.rawValue);

  factory SOCKSReply.fromValue(int value) {
    for (final v in values) {
      if (v.rawValue == value) {
        return v;
      }
    }
    throw UnsupportedError("Invalid SOCKSReply value");
  }

  @override
  String toString() => "$runtimeType.$name";
}

class SOCKSRequest {
  final int version = SOCKSVersion;
  final SOCKSCommand command;
  final SOCKSAddressType addressType;
  final Uint8List address;
  final int port;

  String getAddressString() {
    switch (addressType) {
      case SOCKSAddressType.Domain:
        return const AsciiDecoder().convert(address);
      case SOCKSAddressType.IPv4:
        return address.join(".");
      case SOCKSAddressType.IPv6:
        final List<String> ret = [];
        for (int x = 0; x < address.length; x += 2) {
          ret.add("${address[x].toRadixString(16).padLeft(2, "0")}"
              "${address[x + 1].toRadixString(16).padLeft(2, "0")}");
        }
        return ret.join(":");
    }
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
  SOCKSRequest? _request;

  StreamSubscription<RawSocketEvent>? _sockSub;
  StreamSubscription<RawSocketEvent>? get subscription => _sockSub;

  SOCKSState _state = SOCKSState.Starting;
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
      address: AsciiEncoder().convert(ds[0]).sublist(0, ds[0].length),
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
      ..._auth.map((v) => v.rawValue),
    ]);

    _sockSub = _sock.listen((RawSocketEvent ev) {
      switch (ev) {
        case RawSocketEvent.read:
          {
            final have = _sock.available();
            final data = _sock.read(have);
            if (data != null) {
              _handleRead(data);
            } else {
              print("========= sock read DATA is NULL");
            }
            break;
          }
        case RawSocketEvent.closed:
          {
            _sockSub?.cancel();
            break;
          }
        default:
          print("AAAAAAAAAAAAA: unhandled raw socket event: $ev");
        // case RawSocketEvent.closed:
        //   // TODO: Handle this case.
        //   break;
        // case RawSocketEvent.read:
        //   // TODO: Handle this case.
        //   break;
        // case RawSocketEvent.readClosed:
        //   // TODO: Handle this case.
        //   break;
        // case RawSocketEvent.write:
        //   // TODO: Handle this case.
        //   break;
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
        final version = data[0];
        final auth = AuthMethods.fromValue(data[1]);

        print("_handleRead << Version: $version, Auth: $auth");

        switch (auth) {
          case AuthMethods.UsernamePassword:
            _setState(SOCKSState.AuthStarted);
            _sendUsernamePassword(username ?? '', password ?? '');
            break;
          case AuthMethods.NoAuth:
            _setState(SOCKSState.RequestReady);
            _writeRequest(_request!);

            break;
          default:
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
          _writeRequest(_request!);
        }
      }
    } else if (_state == SOCKSState.RequestReady) {
      if (data.length >= 10) {
        final version = data[0];
        final reply = SOCKSReply.fromValue(data[1]);
        //data[2] reserved
        final addrType = SOCKSAddressType.fromValue(data[3]);
        Uint8List addr;
        int port = 0;

        switch (addrType) {
          case SOCKSAddressType.Domain:
            final len = data[4];
            addr = data.sublist(5, 5 + len);
            port = data[5 + len] << 8 | data[6 + len];
            break;
          case SOCKSAddressType.IPv4:
            addr = data.sublist(5, 9);
            port = data[9] << 8 | data[10];
            break;
          case SOCKSAddressType.IPv6:
            addr = data.sublist(5, 21);
            port = data[21] << 8 | data[22];
            break;
        }

        print(
            "<< Version: $version, Reply: $reply, AddrType: $addrType, Addr: $addr, Port: $port");
        if (reply.rawValue == SOCKSReply.Success.rawValue) {
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
        req.command.rawValue,
        0x00,
        req.addressType.rawValue,
        if (req.addressType == SOCKSAddressType.Domain)
          req.address.lengthInBytes,
        ...req.address,
        req.port >> 8,
        req.port & 0xF0,
      ];

      print(
          "_writeRequest >> Version: ${req.version}, Command: ${req.command}, AddrType: ${req.addressType}, Addr: ${req.getAddressString()}, Port: ${req.port}");
      _sock.write(data);
    } else {
      throw "Must be in RequestReady state, current state $_state";
    }
  }
}
