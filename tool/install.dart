import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;
  addSelfAsDependency();
  pubGet(package);

  final commandFile =
      package.root.file('lib/src/commands/build_ios_command.dart');
  final template = PluginContext.installerPlugin.root
      .file('template/build_ios_command.template.dart');
  template.copySync(commandFile.path);

  registerPlugin(
    sidekickCli: package,
    import:
        "import 'package:${package.name}/src/commands/build_ios_command.dart';",
    command: 'BuildIosCommand()',
  );
}
