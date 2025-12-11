import 'dart:io';

Future<void> main() async {
  final projectToolDir = File(() {
    String path = Platform.script.path;
    if (Platform.isWindows) {
      while (!path.startsWith("C:")) {
        path = path.substring(1);
      }
    }
    return path;
  }()).parent;

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
  final clone = await Process.start("git", [
    "clone",
    "https://www.github.com/ltcmweb/mwebd.git",
    "--branch",
    "v0.1.8",
  ], runInShell: true);
  await _waitForProcess(clone);

  // change working dir and build mwebd.exe
  Directory.current = Directory(
    "${tempBuildDir.path}"
    "${Platform.pathSeparator}mwebd",
  );
  final wslBuild = Platform.isWindows
      ? await Process.start("wsl", [
          "bash",
          "-l",
          "-c",
          "GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc "
              "go build -o ../mwebd.exe github.com/ltcmweb/mwebd/cmd/mwebd",
        ], runInShell: true)
      : await Process.start(
          "go",
          ["build", "-o", "../mwebd.exe", "github.com/ltcmweb/mwebd/cmd/mwebd"],
          environment: {
            "GOOS": "windows",
            "GOARCH": "amd64",
            "CGO_ENABLED": "1",
            "CC": "x86_64-w64-mingw32-gcc",
          },
          runInShell: true,
        );
  await _waitForProcess(wslBuild);

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
        ])
      : await Process.start("cp", [
          "${Directory.current.parent.path}"
              "${Platform.pathSeparator}mwebd.exe",
          "${winAssetsDir.path}"
              "${Platform.pathSeparator}mwebd.exe",
        ]);
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
