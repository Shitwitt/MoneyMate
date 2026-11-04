import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../data/seed.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class ReceiptService {
  static Future<Receipt?> pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 72,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > maxReceiptBytes) {
      throw const FormatException('Please choose an image smaller than 2 MB');
    }
    final mime = bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50
        ? 'image/png'
        : bytes.length > 12 &&
              String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP'
        ? 'image/webp'
        : 'image/jpeg';
    return Receipt(
      id: uuid.v4(),
      name: file.name,
      mime: mime,
      data: base64Encode(bytes),
    );
  }
}
