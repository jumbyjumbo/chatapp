// web_image_handler.dart
import 'dart:html';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

Future<String> uploadImageToFirebaseWeb(
    String conversationId, XFile imageFile) async {
  List<int> imageBytes = await imageFile.readAsBytes();
  var blob = Blob([imageBytes]);

  FirebaseStorage storage = FirebaseStorage.instance;

  // Get file extension
  String fileExtension = extension(imageFile.name);

  try {
    // Upload the blob to Firebase Storage
    await storage
        .ref(
            'conversations/$conversationId/${basename(imageFile.path)}$fileExtension')
        .putBlob(blob);

    // Return the download URL
    String downloadURL = await storage
        .ref(
            'conversations/$conversationId/${basename(imageFile.path)}$fileExtension')
        .getDownloadURL();
    return downloadURL;
  } catch (e) {
    return "error";
  }
}
