import 'package:flutter/material.dart';
import 'package:frontend/models/actor.dart';

class Actorcard extends StatelessWidget {
  final Actor actor;
  const Actorcard({super.key, required this.actor});

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO: decoration
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),

              child: actor.profilePath != null
                  ? Image.network(
                      actor.profilePath!,
                      fit: BoxFit.cover,

                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(
                            Icons.image_not_supported,
                            "Image not available",
                          ),

                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes!)
                                : null,
                            color: Colors.cyanAccent,
                          ),
                        );
                      },
                    )
                  : _buildPlaceholder(
                      Icons.account_circle_rounded,
                      "No Profile",
                    ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
              child: Tooltip(
                message: actor.name,
                child: Text(
                  actor.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a placeholder image widget
  Widget _buildPlaceholder(IconData icon, String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey, size: 40),
            Text(message, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
