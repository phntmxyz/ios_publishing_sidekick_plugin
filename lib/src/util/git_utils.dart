// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:actions_toolkit_dart/src/core/command.dart';
import 'package:actions_toolkit_dart/src/core/environment_variables.dart';
import 'package:actions_toolkit_dart/src/core/utils.dart';
import 'package:sidekick_core/sidekick_core.dart';

extension LocalChanges on File {
  bool hasLocalChanges() {
    return git(['diff', '--exit-code', absolute.path]) == 1;
  }

  void discardLocalChanges() {
    git(['checkout', absolute.path]);
  }
}
