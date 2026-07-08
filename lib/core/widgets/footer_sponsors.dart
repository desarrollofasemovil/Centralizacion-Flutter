import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class FooterSponsors extends StatelessWidget {
  const FooterSponsors({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final tint = ColorFilter.mode(color, BlendMode.srcIn);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/icobancolombia.svg',
          height: 16,
          colorFilter: tint,
        ),
        Container(
          width: 1,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: color.withValues(alpha: 0.5),
        ),
        SvgPicture.asset(
          'assets/images/ico101software.svg',
          height: 20,
          colorFilter: tint,
        ),
      ],
    );
  }
}
