import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

import 'build_ios_command.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  if (PluginContext.localPlugin == null) {
    pubAddDependency(package, 'phntm_release_ios_sidekick_plugin');
  } else {
    // For local development
    pubAddLocalDependency(package, PluginContext.localPlugin!.root.path);
  }
  pubGet(package);

  final commandFile =
      package.root.file('lib/src/commands/build_ios_command.dart');
  commandFile.writeAsStringSync(buildIosCommand);

  registerPlugin(
    sidekickCli: package,
    import:
        "import 'package:${package.name}/src/commands/build_ios_command.dart';",
    command: 'BuildIosCommand()',
  );
}
