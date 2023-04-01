import 'package:flutter/material.dart';

//Represents the reusable time counting Text Widget.
class Counter extends AnimatedWidget{
  final Animation<int> animation;
  final Function(int)? onValueCntdClbck;
  final TextStyle? customStyle;
  
  const Counter({required this.animation, this.customStyle, this.onValueCntdClbck, Key? key}) :
    super(key: key, listenable: animation);
  
  @override
  Widget build(BuildContext context) {
    if(onValueCntdClbck != null){
      onValueCntdClbck!(animation.value);
    }
    return Text(
      writeTimeString(animation.value),
      style: customStyle ?? TextStyle(
        fontSize: 85,
        color: Colors.blue[900],
      ),
    );
  }

  static String writeTimeString(int timeInSeconds, {bool shouldDisplaySeconds = true}){
    Duration _time = Duration(seconds: timeInSeconds);
    String _timeString = "${_time.inHours.toString().padLeft(2, '0')}:"
        "${_time.inMinutes.remainder(60).toString().padLeft(2, '0')}";
    if(shouldDisplaySeconds){
      _timeString += ":${_time.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    }
    return _timeString;
  }
}