// ignore_for_file: implementation_imports, depend_on_referenced_packages
import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

extension LocalChanges on File {
  bool hasLocalChanges() {
    final progress =
        dcli.startFromArgs('git', ['diff', '--exit-code', absolute.path]);
    return progress.exitCode == 1;
  }

  void discardLocalChanges() {
    'git checkout ${absolute.path}'.run;
  }
}
