import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const String _svgCode = '''
<svg width="1080" height="1920" viewBox="0 0 1080 1920"
     xmlns="http://www.w3.org/2000/svg">

  <defs>
    <linearGradient id="gold" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFD56A"/>
      <stop offset="100%" stop-color="#F4A623"/>
    </linearGradient>

    <filter id="glow">
      <feGaussianBlur stdDeviation="6" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>

  <!-- Background -->
  <rect width="100%" height="100%" fill="#021B4A"/>

  <!-- Fireworks -->
  <g transform="translate(540 500)">
    <circle r="8" fill="#FF6A00">
      <animate attributeName="r"
               values="0;60;0"
               dur="2s"
               repeatCount="indefinite"/>
      <animate attributeName="opacity"
               values="1;0.3;0"
               dur="2s"
               repeatCount="indefinite"/>
    </circle>

    <circle r="8" fill="#FFD700">
      <animate attributeName="r"
               values="0;90;0"
               dur="2.5s"
               repeatCount="indefinite"/>
      <animate attributeName="opacity"
               values="1;0.4;0"
               dur="2.5s"
               repeatCount="indefinite"/>
    </circle>
  </g>

  <!-- Cart -->
  <g stroke="url(#gold)"
     stroke-width="12"
     fill="none"
     stroke-linecap="round"
     stroke-linejoin="round">

    <path d="M380 800 L450 800 L500 980 L700 980 L760 860"
          stroke-dasharray="700"
          stroke-dashoffset="700">
      <animate attributeName="stroke-dashoffset"
               from="700"
               to="0"
               dur="1.5s"
               fill="freeze"/>
    </path>

    <circle cx="540" cy="1050" r="18" fill="#F4A623">
      <animate attributeName="opacity"
               from="0"
               to="1"
               begin="1.3s"
               dur="0.3s"
               fill="freeze"/>
    </circle>

    <circle cx="670" cy="1050" r="18" fill="#F4A623">
      <animate attributeName="opacity"
               from="0"
               to="1"
               begin="1.4s"
               dur="0.3s"
               fill="freeze"/>
    </circle>
  </g>

  <!-- FK -->
  <text x="540"
        y="920"
        text-anchor="middle"
        font-size="90"
        font-family="Poppins, Arial"
        font-weight="bold"
        fill="url(#gold)"
        opacity="0"
        filter="url(#glow)">
    FK
    <animate attributeName="opacity"
             from="0"
             to="1"
             begin="1.2s"
             dur="0.5s"
             fill="freeze"/>
  </text>

  <!-- Brand Name -->
  <text x="540"
        y="1220"
        text-anchor="middle"
        font-size="72"
        font-family="Poppins, Arial"
        font-weight="700"
        fill="url(#gold)"
        opacity="0">
    FestiveKart
    <animate attributeName="opacity"
             from="0"
             to="1"
             begin="1.8s"
             dur="0.8s"
             fill="freeze"/>

    <animateTransform
        attributeName="transform"
        type="translate"
        from="0 30"
        to="0 0"
        begin="1.8s"
        dur="0.8s"
        fill="freeze"/>
  </text>

</svg>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021B4A), // Solid fallback matching background rect
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF021B4A),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1080 / 1920,
            child: SvgPicture.string(
              _svgCode,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
