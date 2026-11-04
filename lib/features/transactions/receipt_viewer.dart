import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/services/file_service.dart';
import '../../shared/actions.dart';

class ReceiptViewer extends StatefulWidget {
  final List<Receipt> receipts;
  final int initialIndex;
  const ReceiptViewer(this.receipts, {super.key, this.initialIndex = 0});
  @override
  State<ReceiptViewer> createState() => _ReceiptViewerState();
}
class _ReceiptViewerState extends State<ReceiptViewer> {
  late final PageController controller = PageController(initialPage: widget.initialIndex);
  late int index = widget.initialIndex;
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text('Receipt ${index + 1} / ${widget.receipts.length}'), actions: [IconButton(tooltip: 'Share receipt', icon: const Icon(Icons.ios_share_rounded), onPressed: () => runSafe(context, () => FileService.save(base64Decode(widget.receipts[index].data), widget.receipts[index].name, mime: widget.receipts[index].mime)))]), body: PageView.builder(controller: controller, itemCount: widget.receipts.length, onPageChanged: (value) => setState(() => index = value), itemBuilder: (context, index) => InteractiveViewer(minScale: .5, maxScale: 6, child: Center(child: Image.memory(base64Decode(widget.receipts[index].data), fit: BoxFit.contain, semanticLabel: 'Receipt image', errorBuilder: (_, __, ___) => const Text('This image could not be opened', style: TextStyle(color: Colors.white)))))));
}
