import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'network/network_called.dart';

/*void main() {
  NetworkCaller.init(); // এটা অবশ্যই আগে call করতে হবে

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MyApp(),
    ),
  );
}*/


void main(){
  NetworkCaller.init();
  runApp(MyApp());
}




