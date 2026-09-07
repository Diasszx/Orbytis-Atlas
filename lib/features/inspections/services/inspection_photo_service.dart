import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

final class InspectionPhotoService {
  InspectionPhotoService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<String?> capturePhoto({required String clientId}) async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
    );

    if (photo == null) {
      return null;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final photosDirectory = Directory(
      path.join(documentsDirectory.path, 'inspection_photos'),
    );

    if (!await photosDirectory.exists()) {
      await photosDirectory.create(recursive: true);
    }

    final extension = path.extension(photo.path);
    final permanentPath = path.join(
      photosDirectory.path,
      '$clientId$extension',
    );
    final permanentFile = await File(photo.path).copy(permanentPath);

    return permanentFile.path;
  }
}
