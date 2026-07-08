import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HealthTipCard extends StatelessWidget {
  const HealthTipCard({super.key});

  static const List<_Tip> _tips = [
    _Tip('Stay Hydrated', 'Drink at least 8 glasses of water\ndaily to maintain optimal health.'),
    _Tip('Get 7\u20138 Hours of Sleep', 'Quality sleep helps your body\nrepair and recharge every night.'),
    _Tip('Take a 10-Minute Walk', 'A short daily walk boosts mood,\nenergy, and cardiovascular health.'),
    _Tip('Eat More Vegetables', 'Fill half your plate with colorful\nvegetables for essential nutrients.'),
    _Tip('Practice Deep Breathing', 'Take 5 slow, deep breaths to\nreduce stress and stay focused.'),
  ];

  int get _tipIndex => DateTime.now().millisecondsSinceEpoch ~/ 86400000 % _tips.length;

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_tipIndex];
    return Container(
      width: 355,
      height: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xff80C1D5),
        border: Border.all(
          color: const Color(0xff8FBAC7),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xffBED6DD),
            child: const Icon(
              CupertinoIcons.heart,
              size: 30,
              color: Color(0xff8FBAC7),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tip.title,
                  style: const TextStyle(
                    fontSize: 15,
                    
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  tip.description,
                  style: TextStyle(
                    fontSize: 13,
                    
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip {
  final String title;
  final String description;
  const _Tip(this.title, this.description);
}
