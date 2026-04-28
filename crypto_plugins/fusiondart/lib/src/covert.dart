import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Cool down time for Tor connections, in seconds.
const int torCoolDownTime = 660;

// Timeout for inactive connections, in seconds.
const int TIMEOUT_INACTIVE_CONNECTION = 120;

/// Checks if a specific port on a host is running a Tor service.
Future<bool> isTorPort(String host, int port) async {
  // Validate the port range
  if (port < 0 || port > 65535) {
    return false;
  }

  try {
    // Attempt to connect to the host and port within a 100ms timeout.
    Socket sock =
        await Socket.connect(host, port, timeout: Duration(milliseconds: 100));

    // Send a "GET" request to trigger the server's response.
    sock.write("GET\n");

    // Wait for the first data packet from the server.
    List<int> data = await sock.first;

    // Destroy the socket as it's no longer needed.
    sock.destroy();

    // Decode the server's response and check if it contains the typical Tor error message.
    if (utf8.decode(data).contains("Tor is not an HTTP Proxy")) {
      return true;
    }
  } on SocketException {
    // Catch any SocketException that occurs (e.g., timeout, host unreachable)
    return false;
  }

  // Default return value if all the checks fail.
  return false;
}

/// A rate limiter for Tor connections.
class TorLimiter {
  Queue<DateTime> deque = Queue<DateTime>();
  int lifetime;

  /// Internal count to track the number of operations.
  int _count = 0;

  /// Getter for the current count of operations.
  int get count {
    return _count;
  }

  /// Constructor that initializes the limiter with a given [lifetime].
  TorLimiter(this.lifetime);

  /// Increases the internal count.
  void bump() {
    _count++;
  }
}

// Placeholder for the value of TOR_COOLDOWN_TIME. Replace as necessary.
TorLimiter limiter = TorLimiter(torCoolDownTime);

/// Generates a random number based on a trapezoidal distribution.
double randTrap(Random rng) {
  // Define a constant for one-sixth, which we'll use for comparisons.
  final sixth = 1.0 / 6;

  // Generate a random double between 0 and 1.
  final f = rng.nextDouble();

  // Calculate the complement of the random double.
  final fc = 1.0 - f;

  if (f < sixth) {
    // Check if the random number falls within the first one-sixth of the range.
    //
    // Calculate using the formula for the left trapezoid.
    return sqrt(0.375 * f);
  } else if (fc < sixth) {
    // Check if the random number's complement falls within the first one-sixth of the range.
    //
    // Calculate using the formula for the right trapezoid.
    return 1.0 - sqrt(0.375 * fc);
  } else {
    // For all other cases, falling within the middle trapezoid.
    //
    // Calculate using the formula for the middle trapezoid.
    return 0.75 * f + 0.125;
  }
}
