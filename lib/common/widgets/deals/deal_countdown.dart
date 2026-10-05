import 'dart:async';

import 'package:flutter/material.dart';

class DealCountdown extends StatefulWidget {
  final DateTime endTime;
  final Color textColor;

  const DealCountdown({
    super.key,
    required this.endTime,
    this.textColor = Colors.white,
  });

  @override
  State<DealCountdown> createState() => _DealCountdownState();
}

class _DealCountdownState extends State<DealCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    _updateRemaining();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        _updateRemaining();
      },
    );
  }

  void _updateRemaining() {
    final remaining = widget.endTime.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      _timer?.cancel();

      if (mounted) {
        setState(() {
          _remaining = Duration.zero;
        });
      }

      return;
    }

    if (mounted) {
      setState(() {
        _remaining = remaining;
      });
    }
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TimeBox(
          value: days.toString(),
          label: 'Days',
          textColor: widget.textColor,
        ),
        const SizedBox(width: 6),
        Text(
          ':',
          style: TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        _TimeBox(
          value: _twoDigits(hours),
          label: 'Hrs',
          textColor: widget.textColor,
        ),
        const SizedBox(width: 6),
        Text(
          ':',
          style: TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        _TimeBox(
          value: _twoDigits(minutes),
          label: 'Min',
          textColor: widget.textColor,
        ),
        const SizedBox(width: 6),
        Text(
          ':',
          style: TextStyle(
            color: widget.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        _TimeBox(
          value: _twoDigits(seconds),
          label: 'Sec',
          textColor: widget.textColor,
        ),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;

  const _TimeBox({
    required this.value,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}