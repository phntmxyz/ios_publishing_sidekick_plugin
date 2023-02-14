// ignore_for_file: implementation_imports, depend_on_referenced_packages
import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

extension LocalChanges on File {
  bool hasLocalChanges() {
    try {
      final progress = Progress.printStdErr();
      dcli.startFromArgs(
        'git',
        ['diff', '-q', '--exit-code', absolute.path],
        nothrow: true,
        progress: progress,
        workingDirectory: SidekickContext.projectRoot.path,
      );
      return progress.exitCode == 1;
    } catch (e) {
      // most likely no git repo
      return true;
    }
  }

  void discardLocalChanges() {
    'git checkout -q ${absolute.path}'
        .start(workingDirectory: SidekickContext.projectRoot.path);
  }
}
