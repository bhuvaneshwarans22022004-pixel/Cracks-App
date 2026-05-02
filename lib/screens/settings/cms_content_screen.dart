import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cms_provider.dart';

class CmsContentScreen extends StatefulWidget {
  final String title;
  final String contentType;

  const CmsContentScreen({
    super.key,
    required this.title,
    required this.contentType,
  });

  @override
  State<CmsContentScreen> createState() => _CmsContentScreenState();
}

class _CmsContentScreenState extends State<CmsContentScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<CmsProvider>(context, listen: false).fetchContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Consumer<CmsProvider>(
        builder: (context, cms, child) {
          if (cms.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final content = cms.content[widget.contentType] ?? "Content not found.";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          );
        },
      ),
    );
  }
}
