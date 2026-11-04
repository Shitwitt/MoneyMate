import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../data/seed.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/image_headers.dart';

class ReceiptService {
  static Future<Receipt?> pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 72,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > maxReceiptBytes) {
      throw const FormatException('Please choose an image smaller than 2 MB');
    }
    final mime = receiptMime(bytes);
    if (mime == null) throw const FormatException('Choose a PNG, JPEG, or WebP image');
    return Receipt(
      id: uuid.v4(),
      name: file.name,
      mime: mime,
      data: base64Encode(bytes),
    );
  }
}
