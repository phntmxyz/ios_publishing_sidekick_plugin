import 'package:dcli/dcli.dart';

/// A wrapper around startFromArgs that adds timeout functionality
///
/// Uses the Unix timeout command to prevent commands from hanging indefinitely.
/// Returns the same Progress object that regular startFromArgs would return.
///
/// If [timeout] is null, calls startFromArgs directly without timeout.
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
  final String effectiveCommand;
  final List<String> effectiveArgs;

  if (timeout == null) {
    effectiveCommand = command;
    effectiveArgs = args;
    print('Running command: $command ${args.join(' ')}');
  } else {
    effectiveCommand = 'timeout';
    effectiveArgs = ['${timeout.inSeconds}', command, ...args];
    print('Running command with timeout: $command ${args.join(' ')}');
    print('Timeout set to ${timeout.inSeconds} seconds');
  }

  // Call startFromArgs only once
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

  // Check if the command timed out (exit code 124), but only if using timeout
  if (timeout != null && result.exitCode == 124 && !nothrow) {
    throw 'Command timed out after ${timeout.inSeconds} seconds: $command ${args.join(' ')}';
  }

  return result;
}

/// A wrapper around start that adds timeout functionality
///
/// Uses the Unix timeout command to prevent commands from hanging indefinitely.
/// Returns the same Progress object that regular start would return.
///
/// If [timeout] is null, calls start directly without timeout.
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
  Duration? timeout,
}) {
  final String effectiveCommand;

  if (timeout == null) {
    effectiveCommand = commandLine;
    print('Running command: $commandLine');
  } else {
    effectiveCommand = 'timeout ${timeout.inSeconds} $commandLine';
    print('Running command with timeout: $commandLine');
    print('Timeout set to ${timeout.inSeconds} seconds');
  }

  // Call start only once
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

  // Check if the command timed out (exit code 124), but only if using timeout
  if (timeout != null && result.exitCode == 124 && !nothrow) {
    throw 'Command timed out after ${timeout.inSeconds} seconds: $commandLine';
  }

  return result;
}
