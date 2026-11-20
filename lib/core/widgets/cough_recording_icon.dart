import 'package:flutter/material.dart';

/// An icon widget displaying a microphone with sound-wave and cough acoustic burst elements,
/// used to represent cough sound audio recording.
class CoughRecordingIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const CoughRecordingIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/ic_cough_recording.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.mic,
          size: size,
          color: color,
        );
      },
    );
  }
}
