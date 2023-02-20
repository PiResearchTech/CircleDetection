///////////////
import 'dart:io';
import 'CircleDetection.dart';
import 'package:image/image.dart' as imglib;

class MainProcess {
  coordinate1(String imagefile, double value) async {
    //print("processing.............");

    //to get image from user
    imglib.Image? image2;
    image2 = imglib.decodeImage(File(imagefile).readAsBytesSync());

    //To detect the circle
    var a = Circledetection();
    var thumbnail = await a.circularhoughtransform(image2!, value.toInt());

    return thumbnail;
  }
}
