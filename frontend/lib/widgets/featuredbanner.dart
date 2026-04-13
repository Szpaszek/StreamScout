import 'package:flutter/material.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/services/navcontroller.dart';

class FeaturedBanner extends StatelessWidget {
  final Media media;
  final double height;

  const FeaturedBanner({super.key, required this.media, this.height = 220.0});

  // Theme Colors
  static const Color bgColor = Color(0xFF21212E);
  static const Color accentTeal = Color(0xFF4EEAD7);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the details page
        NavController.showDetails(media);
      },
      child: Stack(
        children: [
          // 1. Background Image
          SizedBox(
            height: height,
            width: double.infinity,
            child: Image.network(
              media.backdropPath ?? '',
              fit: BoxFit.cover,

              // fallback if image fails to load
              errorBuilder: (context, error, s) => SizedBox(
                height: 220,
                child: Center(
                  child: const Icon(Icons.movie, color: Colors.grey, size: 50),
                ),
              ),
            ),
          ),

          // 2. gradient overlay
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  bgColor.withValues(alpha: 0.4), // Subtle darkening
                  bgColor, // Full blend into background
                ],
              ),
            ),
          ),

          // 3. Minimalist Content
          Positioned(
            bottom: 30, // Adjusted padding for a tighter look
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  media.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black45,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Metadata Row
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: accentTeal, size: 22),
                    const SizedBox(width: 4),
                    Text(
                      "${media.rating.toStringAsFixed(1)}  •  ${media.mediaType.toUpperCase()}",
                      style: const TextStyle(
                        color: accentTeal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
