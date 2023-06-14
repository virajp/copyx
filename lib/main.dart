import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:console/console.dart';
import 'dart:io';

final greenPen = AnsiPen()..green();
final redPen = AnsiPen()..red();
final yellowPen = AnsiPen()..yellow();
late bool verbose, overwrite, dryRun;
var actualCount = 0;
var filterCount = 0;
var potentialCount = 0;

Future<int> main(List<String> arguments) async {
  late String source, dest, pattern;
  late bool help;
  var parser = ArgParser();
 
  try {
    parser.addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.');
    parser.addFlag('verbose', abbr: 'v', negatable: false, help: 'Show file name along with path while being copied');
    parser.addOption('source', abbr: 's', help: 'Source path to copy from', mandatory: true, valueHelp: 'source');
    parser.addOption('dest', abbr: 'd', help: 'Destination path to copy to', mandatory: true, valueHelp: 'destination');
    parser.addOption('pattern', abbr: 'p', help: 'Pattern to match files to copy', defaultsTo: '*', valueHelp: 'pattern');
    parser.addFlag('overwrite', negatable: true, defaultsTo: false, help: 'Overwrite files that already exist in the destination');
    parser.addFlag('dry-run', negatable: false, help: 'Show what files will be copied without actually copying them');
    var argResults = parser.parse(arguments);
    help = argResults['help'] as bool;
    source = argResults['source'] as String;
    dest = argResults['dest'] as String;
    pattern = argResults['pattern'] as String;
    verbose = argResults['verbose'] as bool;
    overwrite = argResults['overwrite'] as bool;
    dryRun = argResults['dry-run'] as bool;
  } catch(e) {
    help = true;
    print(e);
  }

  if (help) {
    await printUsage(parser.usage);
    return(0);
  }

  return(copyFiles(source, dest, pattern));
}

Future<void> printUsage(String usage) async {
  print('CLI to copy all the files matching a pattern');
  print('\nUsage:');
  print('  xcopy [--help]');
  print('  xcopy [--verbose] [--pattern|-p <pattern>] --source|-s <source> --dest|-d <destination>');
  print('\nArguments:\n');
  print(usage);
}

Future<int> copyFiles(String source, String dest, String pattern) async {
  var returnValue = 0;
  // Check if source directory exists
  var dir = Directory(source);
  if (!await dir.exists()) {
    print('Source directory $source does not exist');
    return(-1);
  }

  // Check if the destination directory exists and is NOT a file 
  var destDir = Directory(dest);
  if (await destDir.exists()) {
    if (await destDir.stat().then((value) => value.type == FileSystemEntityType.file)) {
      print('Destination $dest is a file');
      return(-2);
    }
  } else {
    await destDir.create(recursive: true);
  }

  var regex = RegExp(pattern);
  var files = await dir.list(recursive: true).toList();
  for (var file in files) {
    if (file is File) {
      var fileName = path.basename(file.path);
      if (regex.hasMatch(fileName)) {
        filterCount++;
        var extractPath = file.path.substring(source.length);
        var destPath = path.normalize('$dest/${path.dirname(extractPath)}');
        // var newFile = path.normalize('$destPath/$fileName');
        if(await copyEachFile(file, destPath) != 0) {
          returnValue = -9;
        }
      }
    }
  }
  if(dryRun) {
    print('Would have copied ${redPen(potentialCount)} files out of ${yellowPen(filterCount)} matching the pattern');
  } else {
    print('Copied ${greenPen(actualCount)} files out of ${yellowPen(filterCount)} matching the pattern');
  }
  return(returnValue);
}

bool dirExists(String path) {
  var dir = Directory(path);
  return(dir.existsSync());
}

bool fileExists(String file) {
  var f = File(file);
  return(f.existsSync());
}

Future<int> copyEachFile(FileSystemEntity srcFile, String destPath) async {
  var fileName = path.basename(srcFile.path);
  var destFile = path.normalize('$destPath/$fileName');

  // Print the file name and path if verbose is true
  if (verbose) {
    print('Copying: $fileName\n     to: $destFile');
  }

  // Create the destination directory if it does not exist
  var newDir = Directory(destPath);
  if (!await newDir.exists()) {
    await newDir.create(recursive: true);
  }

  // Check if the file already exists in the destination & delete if overwrite is true
  if (fileExists(destFile)) {
    if (overwrite) {
      await File(destFile).delete();
    } else {
      print(yellowPen('File already exists'));
      return(-3);
    }
  }

  potentialCount++;
  // If dryRun is true, just return
  if (dryRun) {
    return(-4);
  }
  
  // Copy the file
  final sourceFile = File(srcFile.path);
  final destinationFile = File(destFile);

  final totalBytes = await sourceFile.length();
  var copiedBytes = 0;

  final progressBar = ProgressBar(complete: totalBytes);

  final input = sourceFile.openRead();
  final output = destinationFile.openWrite();

  await for (final chunk in input) {
    output.add(chunk);

    copiedBytes += chunk.length;
    progressBar.update(copiedBytes);
  }

  await output.close();

  actualCount++;
  return(0);
}