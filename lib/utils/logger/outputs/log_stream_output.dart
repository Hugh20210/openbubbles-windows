import 'package:logger/logger.dart';

// ignore: library_prefixes
import 'package:openbubbles/utils/logger/logger.dart' as OpenBubblesLogger;


class LogStreamOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    return OpenBubblesLogger.Logger.logStream.sink.add(event.lines.join('\n'));
  }
}
