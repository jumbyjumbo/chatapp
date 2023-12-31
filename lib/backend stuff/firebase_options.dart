// File generated by FlutterFire CLI.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Provides the default FirebaseOptions for the current platform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCzLZN6i_v2rkcjI8pLmpYAumOMux0UzQ8',
    appId: '1:858719003309:web:9f08140183f1ed993ddc24',
    messagingSenderId: '858719003309',
    databaseURL: "https://flutterchatapp-4e28e-default-rtdb.firebaseio.com/",
    projectId: 'flutterchatapp-4e28e',
    authDomain: 'flutterchatapp-4e28e.firebaseapp.com',
    storageBucket: 'flutterchatapp-4e28e.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3btes9MGfpAZ7MY9YN4gAUFh7K73dtQI',
    appId: '1:858719003309:android:2acdf62e58e20cb83ddc24',
    messagingSenderId: '858719003309',
    projectId: 'flutterchatapp-4e28e',
    databaseURL: "https://flutterchatapp-4e28e-default-rtdb.firebaseio.com/",
    storageBucket: 'flutterchatapp-4e28e.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBBed5qOj_s5NeENyyqK18YOXlbGK7Pe2I',
    appId: '1:858719003309:ios:cf922e8e60c0c1053ddc24',
    messagingSenderId: '858719003309',
    databaseURL: "https://flutterchatapp-4e28e-default-rtdb.firebaseio.com/",
    projectId: 'flutterchatapp-4e28e',
    storageBucket: 'flutterchatapp-4e28e.appspot.com',
    iosClientId:
        '858719003309-58u3i91f9t4ec28tbbt6nltg816pf97t.apps.googleusercontent.com',
    iosBundleId: 'com.example.pleasepleasepleaseplease',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBBed5qOj_s5NeENyyqK18YOXlbGK7Pe2I',
    appId: '1:858719003309:ios:2c9f6dd02264c52a3ddc24',
    messagingSenderId: '858719003309',
    databaseURL: "https://flutterchatapp-4e28e-default-rtdb.firebaseio.com/",
    projectId: 'flutterchatapp-4e28e',
    storageBucket: 'flutterchatapp-4e28e.appspot.com',
    iosClientId:
        '858719003309-5pftaqlcrgsb0gqsaasos0ol17rpd40v.apps.googleusercontent.com',
    iosBundleId: 'com.example.pleasepleasepleaseplease.RunnerTests',
  );
}
