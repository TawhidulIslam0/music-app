import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyiBUq54iSKxbltlC2nnoN3J5rPXzgE-k', // from "current_key"
    appId: '1:591671198936:android:e899c1def0ea3b32eac3ad', // from "mobilesdk_app_id"
    messagingSenderId: '591671198936', // from "project_number"
    projectId: 'music-recommender-516a9', // from "project_id"
    storageBucket: 'music-recommender-516a9.firebasestorage.app', // from "storage_bucket"
  );
}
