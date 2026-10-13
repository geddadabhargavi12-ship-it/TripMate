import 'package:flutter/material.dart';

class DestinationImage extends StatelessWidget {
  const DestinationImage({
    required this.url,
    required this.width,
    required this.height,
    super.key,
  });

  final String url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(Icons.image_outlined);
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(Icons.landscape_outlined),
      ),
    );
  }

  Widget _placeholder(IconData icon) {
    return ColoredBox(
      color: const Color(0xFFE4EEEA),
      child: Center(
        child: Icon(icon, size: 28, color: const Color(0xFF52766B)),
      ),
    );
  }
}