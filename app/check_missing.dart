import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  final lines = file.readAsLinesSync();
  bool inTarget = false;
  
  for (var line in lines) {
    if (line.startsWith('SF:')) {
      if (line.contains('crypto_service.dart') || line.contains('express_pdf_generator.dart')) {
        inTarget = true;
        print(line);
      } else {
        inTarget = false;
      }
    } else if (inTarget) {
      if (line.startsWith('DA:') && line.endsWith(',0')) {
        print(line); // missing lines
      }
    }
  }
}
