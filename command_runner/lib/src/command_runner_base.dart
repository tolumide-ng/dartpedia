import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:command_runner/src/arguments.dart';
import 'package:command_runner/src/exception.dart';

class CommandRunner {
  CommandRunner({this.onError});

  final Map<String, Command> _commands = <String, Command>{};

  UnmodifiableSetView<Command> get commands =>
      UnmodifiableSetView<Command>(<Command>{..._commands.values});

  FutureOr<void> Function(Object)? onError;

  Future<void> run(List<String> input) async {
    try {
      final ArgResults results = parse(input);
      if (results.command != null) {
        Object? output = await results.command!.run(results);
        print(output.toString());
      }
    } on Exception catch (exception) {
      if (onError != null) {
        onError!(exception);
      } else {
        rethrow;
      }
    }
  }

  void addCommand(Command command) {
    _commands[command.name] = command;
    command.runner = this;
  }

  ArgResults parse(List<String> input) {
    ArgResults results = ArgResults();
    if (input.isEmpty) return results;

    // Throw an exception if the command is not recognized.
    if (_commands.containsKey(input.first)) {
      results.command = _commands[input.first];
      input = input.sublist(1);
    } else {
      throw ArgumentException(
        'The first word of input must be a command.',
        null,
        input.first,
      );
    }

    // Throw an exception if multiple commands are provided.
    if (results.command != null &&
        input.isNotEmpty &&
        _commands.containsKey(input.first)) {
      throw ArgumentException(
        'Input can only contain one command. Got ${input.first} and ${results.command!.name}',
        null,
        input.first,
      );
    }

    Map<Option, Object> inputOptions = {};

    int i = 0;
    while (i < input.length) {
      if (input[i].startsWith('-')) {
        var base = _removeDash(input[i]);
        // Throw an exception if an option is not recognized for the given command.
        var option = results.command!.options.firstWhere(
          (o) => o.name == base || o.abbr == base,
          orElse: () {
            throw ArgumentException(
              'Unknown option ${input[i]}',
              results.command!.name,
              input[i],
            );
          },
        );

        if (option.type == OptionType.flag) {
          inputOptions[option] = true;
          i++;
          continue;
        }

        if (option.type == OptionType.option) {
          // Throw an exception if an option requires an argument but none is given.
          if (i + 1 >= input.length) {
            throw ArgumentException(
              "Option ${option.name} requires an argument",
              results.command!.name,
              option.name,
            );
          }

          var arg = input[i + 1];
          inputOptions[option] = arg;
          i++;
        }
      } else {
        // throw an exception if more than one positional argument is provided.
        if (results.commandArg != null && results.commandArg!.isNotEmpty) {
          throw ArgumentException(
            'Commands can only have up to one argument',
            results.command!.name,
            input[i],
          );
        }
        results.commandArg = input[i];
      }
      i++;
    }
    results.options = inputOptions;

    return results;
  }

  String _removeDash(String input) {
    if (input.startsWith('--')) {
      return input.substring(2);
    }
    if (input.startsWith('-')) {
      return input.substring(1);
    }
    return input;
  }

  String get usage {
    final execFile = Platform.script.path.split('/').last;
    return 'Usage: dart bin/$execFile <command> (commandArg?) [...options?]';
  }
}
