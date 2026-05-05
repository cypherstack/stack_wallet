import 'dart:io';

const _mwebdVersion = "v0.1.8";
const _defaultFetchBaseUrl =
    "https://github.com/cypherstack/stack_wallet/releases/download";

Future<void> main(List<String> args) async {
  final projectToolDir = File(Platform.script.toFilePath()).parent;

  if (args.contains("--fetch")) {
    await _fetchPrebuilt(projectToolDir);
  } else {
    await _buildFromSource(projectToolDir);
  }
}

Future<void> _fetchPrebuilt(Directory projectToolDir) async {
  final baseUrl =
      Platform.environment["MWEBD_FETCH_BASE_URL"] ?? _defaultFetchBaseUrl;
  final tag = "mwebd-$_mwebdVersion";

  final winAssetsDir = Directory(
    "${projectToolDir.parent.path}"
    "${Platform.pathSeparator}assets"
    "${Platform.pathSeparator}windows",
  );
  if (!(await winAssetsDir.exists())) {
    await winAssetsDir.create(recursive: true);
  }
  final exePath = "${winAssetsDir.path}${Platform.pathSeparator}mwebd.exe";
  final shaPath = "$exePath.sha256";

  await _waitForProcess(
    await Process.start(
      "curl",
      ["-fL", "-o", exePath, "$baseUrl/$tag/mwebd.exe"],
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    ),
  );
  await _waitForProcess(
    await Process.start(
      "curl",
      ["-fL", "-o", shaPath, "$baseUrl/$tag/mwebd.exe.sha256"],
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    ),
  );

  final expected = (await File(
    shaPath,
  ).readAsString()).trim().split(RegExp(r"\s+")).first;
  final actual = (await Process.run("sha256sum", [
    exePath,
  ], runInShell: true)).stdout.toString().trim().split(RegExp(r"\s+")).first;
  if (expected.toLowerCase() != actual.toLowerCase()) {
    stderr.writeln(
      "mwebd.exe sha256 mismatch: expected $expected, got $actual",
    );
    exit(1);
  }
  await File(shaPath).delete();
}

Future<void> _buildFromSource(Directory projectToolDir) async {
  // setup temp build dir
  final tempBuildDir = Directory(
    "${projectToolDir.path}"
    "${Platform.pathSeparator}build",
  );
  if (await tempBuildDir.exists()) {
    await tempBuildDir.delete(recursive: true);
  }
  await tempBuildDir.create();

  // change working dir and clone mwebd
  Directory.current = tempBuildDir;
  final clone = await Process.start(
    "git",
    [
      "clone",
      "https://www.github.com/ltcmweb/mwebd.git",
      "--branch",
      _mwebdVersion,
    ],
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  await _waitForProcess(clone);

  // change working dir and build mwebd.exe
  Directory.current = Directory(
    "${tempBuildDir.path}"
    "${Platform.pathSeparator}mwebd",
  );
  final isCI = Platform.environment['CI'] == 'true';
  final Process build;
  if (Platform.isWindows && isCI) {
    build = await Process.start(
      "go",
      [
        "build",
        "-v",
        "-o",
        "../mwebd.exe",
        "github.com/ltcmweb/mwebd/cmd/mwebd",
      ],
      environment: {"CGO_ENABLED": "1"},
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
  } else if (Platform.isWindows) {
    build = await Process.start(
      "wsl",
      [
        "bash",
        "-l",
        "-c",
        "GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc "
            "go build -v -o ../mwebd.exe github.com/ltcmweb/mwebd/cmd/mwebd",
      ],
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
  } else {
    build = await Process.start(
      "go",
      [
        "build",
        "-v",
        "-o",
        "../mwebd.exe",
        "github.com/ltcmweb/mwebd/cmd/mwebd",
      ],
      environment: {
        "GOOS": "windows",
        "GOARCH": "amd64",
        "CGO_ENABLED": "1",
        "CC": "x86_64-w64-mingw32-gcc",
      },
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
  }
  await _waitForProcess(build);

  // create assets/windows dir if needed
  final winAssetsDir = Directory(
    "${Directory.current.parent.parent.parent.path}"
    "${Platform.pathSeparator}assets"
    "${Platform.pathSeparator}windows",
  );
  if (!(await winAssetsDir.exists())) {
    await winAssetsDir.create();
  }

  // copy the build mwebd.exe to assets/windows
  final copy = Platform.isWindows
      ? await Process.start("cmd", [
          "/C",
          "copy",
          "${Directory.current.parent.path}"
              "${Platform.pathSeparator}mwebd.exe",
          "${winAssetsDir.path}"
              "${Platform.pathSeparator}mwebd.exe",
        ], mode: ProcessStartMode.inheritStdio)
      : await Process.start("cp", [
          "${Directory.current.parent.path}"
              "${Platform.pathSeparator}mwebd.exe",
          "${winAssetsDir.path}"
              "${Platform.pathSeparator}mwebd.exe",
        ], mode: ProcessStartMode.inheritStdio);
  await _waitForProcess(copy);

  // cleanup
  Directory.current = projectToolDir;
  await tempBuildDir.delete(recursive: true);
}

Future<void> _waitForProcess(Process process) async {
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print("Exited process with code=$exitCode\n${StackTrace.current}");
    exit(exitCode);
  }
}
