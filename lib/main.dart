import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';

  late final Permission _permission;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  void _listenForPermissionStatus() async {
    final status = await _permission.status;
    setState(() => _permissionStatus = status);
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  Future<void> initPlatformState() async {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    final status = await Permission.activityRecognition.request();

    setState(() {
      print(status);
      _permissionStatus = status;
      print(_permissionStatus);
    });

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    Future<void> requestPermission(Permission permission) async {
      final status = await permission.request();

      setState(() {
        print(status);
        _permissionStatus = status;
        print(_permissionStatus);
      });
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pedometer app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 100),
                child: Image.network(
                    "https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Man_walking_icon_1410105361.svg/356px-Man_walking_icon_1410105361.svg.png",
                    height: 320),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 100),
                child: _permissionStatus.isGranted
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            _steps,
                            style: TextStyle(fontSize: 20),
                          ),
                          Icon(
                            _status == 'walking'
                                ? Icons.directions_walk
                                : _status == 'stopped'
                                    ? Icons.accessibility_new
                                    : Icons.error,
                            size: 50,
                          ),
                         ],
                      )
                    : _permissionStatus.isPermanentlyDenied
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                child: Text("Grant permission"),
                                onPressed: () {
                                  requestPermission(
                                      Permission.activityRecognition);
                                },
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                                "Go to the settings and grant activity permission"),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
