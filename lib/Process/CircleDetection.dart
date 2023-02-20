/////////////////////
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:dart_tensor/dart_tensor.dart';
import 'package:tuple/tuple.dart';

class Circledetection {
  circularhoughtransform(imglib.Image src1, int thresholdValue) async {
    Stopwatch stopwatch1 = Stopwatch()..start();

    num a = 0, b = 0;
    List<int> list2 = [], list3 = [];
    List<double> listcos = [], listsin = [];
    List<double> radius = [];
    int range = 7;

    var src = imglib.copyResize(src1, width: 180, height: 320);
    var gray = imglib.grayscale(src); //gray image
    var blur = imglib.gaussianBlur(gray, 3); //blur image
    var edgeimg = edgeDetectionHard(blur); //edge detected image

    //to get the number of slices
    int mini = min(src.height, src.width);
    int slice = mini ~/ 3;

    int w = src.width;
    int h = src.height;

    int w1 = src1.width;
    int h1 = src1.height;

    print(w);
    print(h);

    //to get the slice values
    for (int i = 0; i < slice; i++) {
      radius.add((range++).toDouble());
    }

    //generate 3Dmatrix with zeros filled
    List list1 = List.generate(
        src.width,
        (_) => List.generate(src.height, (_) => List.filled(slice, 0),
            growable: false),
        growable: false);

    Stopwatch stopwatch = Stopwatch()..start();
    var img = getpix(edgeimg);
    var segment1 = segment(img, thresholdValue);

    //convert img list to 2Dmatrix
    DartTensor dt = const DartTensor();
    List img1 = dt.cvt2D(segment1, src.width, src.height);

    //if it is whitepixel then add the index values in list
    for (int x = 0; x < src.width; x++) {
      for (int y = 0; y < src.height; y++) {
        if (img1[x][y] == 255) {
          list2.add(x); //xaxis
          list3.add(y); //yaxis
        }
      }
    }
    print('1Executed in ${stopwatch.elapsed}');

    Stopwatch stopwatch2 = Stopwatch()..start();

    //get the list of sin and cos value
    for (num theta = 0; theta <= 360; theta = theta + 3) {
      listsin.add(sin(theta * 3.14 / 180.0));
      listcos.add(cos(theta * 3.14 / 180.0));
    }

    int list2L = list2.length;
    int listcosL = listcos.length;

    print(list2L); //To get the number of white pixel

    int count = 0;

    //------Applying circular Hough Transform by voting-------
    for (int r = 0; r < slice; r = r + 2) {
      for (int i = 0; i < list2L; i = i + 2) {
        count = 0;

        for (int p = 0; p < listcosL; p++) {
          b = (list3[i].toDouble() -
              radius[r] *
                  listsin[
                      p]); //polar coordinate for center (convert to radians)//yaxis

          a = (list2[i].toDouble() -
              radius[r] *
                  listcos[
                      p]); //polar coordinate for center (convert to radians)//xaxis

          if (a >= 0 && b >= 0 && a < w && b < h) {
            list1[a.toInt()][b.toInt()][r] += 1;
            count++;
          }
        }

        if (count < 10 && i > (list2L ~/ 2)) {
          break;
        }
      }
    }
    print('2Executed in ${stopwatch2.elapsed}');
    //----------------------------------------------

    var voting;
    List firstcircle = [], secondcircle = [];
    List firstcircle1 = [], secondcircle1 = [];
    double dist = 0.0;
    Stopwatch stopwatch3 = Stopwatch()..start();

    //---Find the first and second circle-----
    try {
      for (int i1 = 0; i1 < 5; i1++) {
        if (i1 == 0) {
          voting = maxvoting(src, slice, list1, radius);
          firstcircle = [voting.item1, voting.item2, voting.item3];
        } else {
          voting = maxvoting(src, slice, voting.item4, radius);
        }

        dist = sqrt(pow(firstcircle[0] - voting.item1, 2) +
            pow(firstcircle[1] - voting.item2, 2));

        if (dist > 20) {
          secondcircle = [voting.item1, voting.item2, voting.item3];
          break;
        }
      }
      //-----------------------------------------------

      print(firstcircle);
      print(secondcircle);

      var inter = interpolation(firstcircle[0], firstcircle[1], firstcircle[2]);
      var inter1 =
          interpolation(secondcircle[0], secondcircle[1], secondcircle[2]);

      firstcircle1 = [inter.item1, inter.item2, inter.item3];
      secondcircle1 = [inter1.item1, inter1.item2, inter1.item3];

      print(firstcircle1);
      print(secondcircle1);
    } catch (e) {}

    // var dist = distance(firstcircle, secondcircle);
    // print(dist);

    //To draw the border around the circle
    // Color? color = Colors.redAccent;
    // int color1 = abgrToArgb(color.value);

    // var border = imglib.drawCircle(
    //     src1, firstcircle[0], firstcircle[1], firstcircle[2].toInt(), color1);
    // var border1 = imglib.drawCircle(border, secondcircle[0], secondcircle[1],
    //     secondcircle[2].toInt(), color1);

    print('3Executed in ${stopwatch3.elapsed}');
    print('totalExecuted in ${stopwatch1.elapsed}');

    return Tuple3(
        firstcircle1,
        secondcircle1,
        dist.toStringAsFixed(
            3)); //distance value only get the 3 digit after point
  }

  //---------get the pixel value from the src image------------
  getpix(imglib.Image src) {
    List<num> list1 = [];
    num R = 0;

    final tmp = imglib.Image.from(src);
    for (int x = 0; x < src.width; ++x) {
      for (int y = 0; y < src.height; ++y) {
        final c = tmp.getPixel(x, y);

        R = imglib.getRed(c);

        list1.add(R);
      }
    }

    return list1;
  }

//--------------Function created to detect hard edge of the image-------------
  static imglib.Image edgeDetectionHard(imglib.Image src) {
    const filter = [-1, -1, -1, -1, 8, -1, -1, -1, -1];

    return imglib.convolution(src, filter);
  }

//------To segment the value-------------
  segment(List list1, int thresholdValue) {
    // print("thresholdValue");
    //print(thresholdValue);
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] > thresholdValue) {
        //threshold value need to change
        list1[i] = 255;
      }
    }
    return list1;
  }

  //---------To find the first and second circle------------
  maxvoting(imglib.Image src, int slice, List list1, List<double> radius) {
    int maxi1 = 0;
    int? finalx, finaly, indexk;
    double? finalradius;
    try {
      for (int i = 0; i < src.width; i++) {
        for (int j = 0; j < src.height; j++) {
          for (int k = 0; k < slice; k++) {
            if (maxi1 < list1[i][j][k]) {
              maxi1 = list1[i][j][k];

              finalx = i;
              finaly = j;
              indexk = k;
              finalradius = radius[k];
            }
          }
        }
      }
      list1[finalx!][finaly][indexk] = 0;
    } catch (e) {}
    return Tuple4(finalx, finaly, finalradius, list1);
  }

//----------To find the point in the original image-------
  interpolation(x, y, r) {
    const dy = 720 / 320; //height
    const dx = 480 / 180; //width

    const dy1 = 720 / 320; //height
    const dx1 = 480 / 180; //width

    const dr = (dy1 + dx1) ~/ 2;

    final x2 = (x * dx).toInt();
    final y2 = (y * dy).toInt();
    final r2 = (r * dr).toInt();

    return Tuple3(x2, y2, r2);
  }

  //------to convert ABGR to ARGB format------
  int abgrToArgb(int argbColor) {
    int r = (argbColor >> 16) & 0xFF;
    int b = argbColor & 0xFF;
    return (argbColor & 0xFF00FF00) | (b << 16) | r;
  }

  distance(firstcircle, secondcircle) {
    var dist = sqrt(pow(firstcircle[0] - secondcircle[0], 2) +
        pow(firstcircle[1] - secondcircle[1], 2));

    return dist;
  }

  predictedHeight(a1, a2, a3, hmax) {
    int a = (a3 - a1).abs;
    int height = a2 ~/ (a1 - a);

    return height;
  }

  // process1(src, src1, src2, hmax) {
  //   var a1 = circularhoughtransform(src);
  //   var a2 = circularhoughtransform(src1);
  //   var a3 = circularhoughtransform(src2);

  //   var preHeight = predictedHeight(a1, a2, a3, hmax);

  //   return preHeight;
  // }
}
