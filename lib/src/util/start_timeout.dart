import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// A wrapper around startFromArgs that adds timeout functionality
///
/// Uses timeout command (or gtimeout on macOS) to prevent commands
/// from hanging indefinitely.
///
/// If [timeout] is null, calls startFromArgs directly without timeout.
/// Throws [CommandTimeoutException] if no timeout command is available.
Progress startFromArgsWithTimeout(
  String command,
  List<String> args, {
  Progress? progress,
  bool runInShell = false,
  bool detached = false,
  bool terminal = false,
  bool privileged = false,
  bool nothrow = false,
  String? workingDirectory,
  bool extensionSearch = true,
  Duration? timeout = const Duration(seconds: 60),
}) {
  if (timeout == null) {
    return startFromArgs(
      command,
      args,
      progress: progress,
      runInShell: runInShell,
      detached: detached,
      terminal: terminal,
      privileged: privileged,
      nothrow: nothrow,
      workingDirectory: workingDirectory,
      extensionSearch: extensionSearch,
    );
  }

  final timeoutCmd = _getTimeoutCommand(timeout);
  final effectiveCommand = timeoutCmd[0];
  final effectiveArgs = [...timeoutCmd.sublist(1), command, ...args];

  final result = startFromArgs(
    effectiveCommand,
    effectiveArgs,
    progress: progress,
    runInShell: runInShell,
    detached: detached,
    terminal: terminal,
    privileged: privileged,
    nothrow: nothrow,
    workingDirectory: workingDirectory,
    extensionSearch: extensionSearch,
  );

  if (result.exitCode == 124 && !nothrow) {
    throw CommandTimeoutException(
      'Command timed out after ${timeout.inSeconds} seconds: $command ${args.join(' ')}',
    );
  }

  return result;
}

/// A wrapper around start that adds timeout functionality
///
/// Uses the Unix timeout command to prevent commands from hanging indefinitely.
///
/// If [timeout] is null, calls start directly without timeout.
/// Throws [CommandTimeoutException] if no timeout command is available.
Progress startWithTimeout(
  String commandLine, {
  Progress? progress,
  bool runInShell = false,
  bool detached = false,
  bool terminal = false,
  bool nothrow = false,
  bool privileged = false,
  String? workingDirectory,
  bool extensionSearch = true,
  Duration? timeout = const Duration(seconds: 60),
}) {
  if (timeout == null) {
    return start(
      commandLine,
      progress: progress,
      runInShell: runInShell,
      detached: detached,
      terminal: terminal,
      privileged: privileged,
      nothrow: nothrow,
      workingDirectory: workingDirectory,
      extensionSearch: extensionSearch,
    );
  }

  final timeoutCmd = _getTimeoutCommand(timeout);
  final effectiveCommand = '${timeoutCmd.join(' ')} $commandLine';

  final result = start(
    effectiveCommand,
    progress: progress,
    runInShell: runInShell,
    detached: detached,
    terminal: terminal,
    privileged: privileged,
    nothrow: nothrow,
    workingDirectory: workingDirectory,
    extensionSearch: extensionSearch,
  );

  if (result.exitCode == 124 && !nothrow) {
    throw CommandTimeoutException(
      'Command timed out after ${timeout.inSeconds} seconds: $commandLine',
    );
  }

  return result;
}

/// Exception thrown when a command times out
class CommandTimeoutException implements Exception {
  final String message;

  CommandTimeoutException(this.message);

  @override
  String toString() => message;
}

/// Returns a timeout command as a list of strings
///
/// Checks for availability of timeout commands and returns the appropriate
/// command with the timeout value in seconds.
///
/// If no timeout command is available, attempts to install coreutils.
///
/// Throws a [CommandTimeoutException] if no timeout command could be found.
List<String> _getTimeoutCommand(Duration timeout) {
  // Check for gtimeout first (macOS with homebrew)
  if (isProgramInstalled('gtimeout')) {
    return ['gtimeout', '${timeout.inSeconds}'];
  }

  // Check for standard timeout
  if (isProgramInstalled('timeout')) {
    return ['timeout', '${timeout.inSeconds}'];
  }

  print('No timeout command found. Attempting to install GNU coreutils...');

  final installProgress = Progress.printStdErr();
  start(
    'brew install coreutils',
    progress: installProgress,
    nothrow: true,
  );

  if (installProgress.exitCode == 0 && isProgramInstalled('gtimeout')) {
    print('Successfully installed coreutils, using gtimeout');
    return ['gtimeout', '${timeout.inSeconds}'];
  }

  throw CommandTimeoutException(
    'Could not install coreutils. No timeout command available.',
  );
}
