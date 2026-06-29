import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('Sem lcov.info');
    return;
  }
  final lines = file.readAsLinesSync();
  String currentFile = '';
  int lf = 0;
  int lh = 0;
  
  for (var line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      lf = 0;
      lh = 0;
    } else if (line.startsWith('LF:')) {
      lf = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      lh = int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      if (lf > 0) {
        final percent = (lh / lf * 100).toStringAsFixed(1);
        print('$percent% ($lh/$lf) - $currentFile');
      } else {
        print('N/A (0/0) - $currentFile');
      }
    }
  }
}
