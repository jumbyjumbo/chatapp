// web_image_handler.dart
import 'dart:html';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

Future<String> uploadImageToFirebaseWeb(XFile imageFile) async {
  List<int> imageBytes = await imageFile.readAsBytes();
  var blob = Blob([imageBytes]);

  FirebaseStorage storage = FirebaseStorage.instance;

  try {
    // Upload the blob to Firebase Storage
    await storage
        .ref('conversations/${basename(imageFile.path)}')
        .putBlob(blob);

    // Return the download URL
    String downloadURL = await storage
        .ref('conversations/${basename(imageFile.path)}')
        .getDownloadURL();
    return downloadURL;
  } catch (e) {
    print(e);
    return "";
  }
}
