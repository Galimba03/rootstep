import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';

class GpxService {
  static Future<void> exportAndShare(Activity activity) async {
    // 1. Generate the content of the file gpx. It's just an xml file.
    String gpxContent = _generateGpx(activity);

    // 2. Find the temporary directory to save the gpx file.
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(activity.dateTime);
    final filePath = '${directory.path}/rootstep_$timestamp.gpx';
    final file = File(filePath);

    // 3. Write the file on the device.
    await file.writeAsString(gpxContent);

    // 4. Open the native menu of condivision (IOS/Android)
    await Share.shareXFiles(
      [XFile(file.path)], 
      text: 'Check out my run on RootStep!',
    );
  }

  static String _generateGpx(Activity activity) {
    final buffer = StringBuffer();
    final dateStr = activity.dateTime.toUtc().toIso8601String();

    // Standard headers of the GPX file.
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="RootStep App">');
    buffer.writeln('  <metadata>');
    buffer.writeln('    <time>$dateStr</time>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>Run on ${DateFormat('MMM d, yyyy').format(activity.dateTime)}</name>');
    buffer.writeln('    <trkseg>');

    // Getting point from the route and putting them in the file.
    for (var segment in activity.route) {
      for (var point in segment) {
        if (point.length >= 2) {
          buffer.writeln('      <trkpt lat="${point[0]}" lon="${point[1]}"></trkpt>');
        }
      }
    }

    // Closing tags
    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    
    return buffer.toString();
  }
}