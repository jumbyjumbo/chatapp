// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

Future<String> uploadImageToFirebaseWeb(
    String conversationId, XFile imageFile, String pathToStore) async {
  List<int> imageBytes = await imageFile.readAsBytes();
  var blob = Blob([imageBytes]);

  FirebaseStorage storage = FirebaseStorage.instance;

  // Get file extension
  String fileExtension = extension(imageFile.name);
  String fullPath =
      "conversations/$conversationId/$pathToStore/${basename(imageFile.path)}.$fileExtension";

  try {
    // store the image at path
    await storage.ref(fullPath).putBlob(blob);

    // Return the download URL
    String downloadURL = await storage.ref(fullPath).getDownloadURL();
    return downloadURL;
  } catch (e) {
    return "error";
  }
}
