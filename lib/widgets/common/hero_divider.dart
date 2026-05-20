//Hero卡片白色垂直分隔線
import 'package:flutter/material.dart';
 
class HeroDivider extends StatelessWidget {
  final double height;
  final double horizontalMargin;
 
  const HeroDivider({
    super.key,
    this.height = 28,
    this.horizontalMargin = 4,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      color: Colors.white24,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
    );
  }
}