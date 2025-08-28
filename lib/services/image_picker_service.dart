import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? xfile = await _picker.pickImage(source: ImageSource.gallery);
      return xfile?.path;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? xfile = await _picker.pickImage(source: ImageSource.camera);
      return xfile?.path;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }
}
