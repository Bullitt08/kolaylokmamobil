import 'package:flutter/material.dart';

class CustomIcon extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final double size;

  const CustomIcon({
    Key? key,
    required this.iconData,
    this.iconColor = Colors.black,
    this.size = 22.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconData,
      color: iconColor,
      size: size,
    );
  }
}
