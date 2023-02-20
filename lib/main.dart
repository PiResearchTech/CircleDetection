// ignore_for_file: prefer_const_constructors, unnecessary_new, avoid_unnecessary_containers

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:tuple/tuple.dart';
import 'Process/MainProcess.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  WidgetsFlutterBinding.ensureInitialized(); // can be called before `runApp()`

  final cameras =
      await availableCameras(); // Obtain a list of the available cameras on the device.

  final firstCamera = cameras
      .first; // Get a specific camera from the list of available cameras.

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera:
            firstCamera, // Pass the appropriate camera to the TakePictureScreen widget.
      ),
    ),
  );
}

Color _iconColor1 = Colors.pink;

bool _isCircleVisible = false, flag = false;
double _currentSliderValue = 10;
String distance = "", radius1 = "", radius2 = "";

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  double? leftS, topS, radiusS;
  double? leftS1, topS1, radiusS1;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
        widget
            .camera, // Get a specific camera from the list of available cameras.

        ResolutionPreset.medium,
        enableAudio: false // Define the resolution to use.
        );

    _initializeControllerFuture = _controller
        .initialize(); // Next, initialize the controller. This returns a Future.

    try {
      _controller.setFlashMode(FlashMode.off); //camera flashlight off

    } catch (e) {
      print(e);
    }
  }

  Timer? _clocktimer;
  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              //-------To show the live camera-------------
              children: <Widget>[
                Positioned.fromRect(
                  rect: const Rect.fromLTWH(0, 0, 480, 720),
                  child: CameraPreview(_controller),
                ),
                //---------------------------
                //---------To show the circle in the live camera---------------
                if (_isCircleVisible)
                  Positioned.fromRect(
                    rect: const Rect.fromLTWH(0, 0, 480, 720),
                    child: InkWell(
                      child: Container(
                        child: CustomPaint(
                          painter: OpenPainter(leftS!, topS!, radiusS!),
                        ),
                      ),
                      // When the user taps on the rectangle, it will disappear
                      onTap: () {
                        setState(() {
                          _isCircleVisible = false;
                        });
                      },
                    ),
                  ),
                if (_isCircleVisible)
                  Positioned.fromRect(
                    rect: const Rect.fromLTWH(0, 0, 480, 720),

                    child: InkWell(
                      child: Container(
                        child: CustomPaint(
                          painter: OpenPainter(leftS1!, topS1!, radiusS1!),
                        ),
                      ),
                      // When the user taps on the rectangle, it will disappear
                      onTap: () {
                        setState(() {
                          _isCircleVisible = false;
                        });
                      },
                    ),
                    //  ),
                  ),
                if (_isCircleVisible)
                  Positioned(
                      //rect: const Rect.fromLTWH(0, 0, 480, 720),
                      child: SizedBox(
                    child: Align(
                        alignment: Alignment.topRight,
                        child: Column(children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              "Distance: $distance",
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                          Container(
                            // padding: EdgeInsets.only(right: 40),
                            child: Text(
                              "Radius1: $radius1",
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                          Container(
                            child: Text(
                              "Radius2: $radius2",
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic),
                            ),
                          )
                        ])),
                  )),
                Container(
                    padding: EdgeInsets.only(
                        top: 0.7 * MediaQuery.of(context).size.height,
                        left: 10),
                    child: Text("Threshold",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic))),
                Container(
                  padding: EdgeInsets.only(top: 450),
                  child: Slider(
                    activeColor: Colors.pink,
                    inactiveColor: Colors.white,
                    value: _currentSliderValue,
                    max: 250,
                    divisions: 250,
                    label: _currentSliderValue.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _currentSliderValue = value;
                      });
                    },
                  ),
                ),
              ],
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          flag = !flag;
          await _initializeControllerFuture; // Ensure that the camera is initialized.
          if (flag == true) {
            try {
              var a = MainProcess();

              //---------live circle detection----------------
              _clocktimer = Timer.periodic(const Duration(milliseconds: 40),
                  (timer) async {
                setState(() {
                  _iconColor1 = Colors.deepOrange;
                  if (flag == false) {
                    _clocktimer!.cancel();
                  }
                });
                try {
                  final image = await _controller
                      .takePicture(); // to take picture from camera

                  Tuple3 b =
                      await a.coordinate1(image.path, _currentSliderValue);
                  var b1 = b.item1;
                  var b2 = b.item2;

                  setState(() {
                    leftS = b1[0].toDouble();
                    topS = b1[1].toDouble();
                    radiusS = b1[2].toDouble();

                    _isCircleVisible = true;

                    leftS1 = b2[0].toDouble();
                    topS1 = b2[1].toDouble();
                    radiusS1 = b2[2].toDouble();

                    distance = b.item3.toString();
                    radius1 = b1[2].toString();
                    radius2 = b2[2].toString();
                  });
                } catch (e) {
                  print(e);
                }
              });
              //---------------------------------------
            } catch (e) {
              print(e);
            }
          }
          //  else {
          //   setState(() {
          //     if (_clocktimer!.isActive) {
          //       _clocktimer!.cancel();
          //     }
          //   });
          // }
        },
        child: Icon(
          flag ? Icons.pause : Icons.play_arrow,
          color: Colors.pink,
        ),
      ),
    );
  }

  // coordinate1(imagefile) async {
  //   imglib.Image? image2;
  //   image2 = imglib.decodeImage(File(imagefile).readAsBytesSync());
  //   var a = Circledetection();
  //   var b = await a.circularhoughtransform(image2!);
  //   return b;
  // }
}

//--------To draw the circle in the live camera---------
class OpenPainter extends CustomPainter {
  double x = 0, y = 0, radius;
  OpenPainter(this.x, this.y, this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    var paint1 = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(x, y), radius, paint1);
    canvas.drawCircle(Offset(x, y), radius - 0.5, paint1);
    canvas.drawCircle(Offset(x, y), radius + 0.5, paint1);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
