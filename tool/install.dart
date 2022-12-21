import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;
  addSelfAsDependency();
  pubGet(package);

  PluginContext.installerPlugin.root
      .file('template/build_ios_command.template.dart')
      .copy(package.root.file('lib/src/commands/build_ios_command.dart').path);

  registerPlugin(
    sidekickCli: package,
    import:
        "import 'package:${package.name}/src/commands/build_ios_command.dart';",
    command: 'BuildIosCommand()',
  );
}
