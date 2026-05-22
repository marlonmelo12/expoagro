import 'web_exporter_stub.dart'
    if (dart.library.html) 'web_exporter_web.dart' as exporter;

// Cross-platform function to export CSV. Triggers real download on Web, and copies to Clipboard.
void exportCSV(String csvContent, String filename) {
  exporter.downloadCSVWeb(csvContent, filename);
}
