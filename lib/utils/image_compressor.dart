import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as im;
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';

Future<File> compressFile(File file, {int width = 250}) async {
  //create temporary path for file
  final tempDir = await getTemporaryDirectory();
  final path = tempDir.path;
  int rand = new math.Random().nextInt(10000);

  //compress file size
  im.Image image = im.decodeImage(file.readAsBytesSync());
  im.Image smallerImage = im.copyResize(image, width);
  File compressedImage = File('$path/$rand.png')..writeAsBytesSync(im.encodePng(smallerImage));

  return compressedImage;
}