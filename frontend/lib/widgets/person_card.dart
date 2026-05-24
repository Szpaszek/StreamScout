import 'package:flutter/material.dart';
import 'package:frontend/models/person.dart';
import 'package:frontend/services/nav_controller.dart';

class Personcard extends StatelessWidget {
  final Person person;
  const Personcard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),

        child: InkWell(
          // Navigate to the details page
          onTap: () => NavController.showPersonDetails(context, person),
          
          // fix Inkwell splash constraint issues
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Area
              Expanded(
                flex: 3,
                  child: person.profilePath != null
                      ? Image.network(
                          person.profilePath!,
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
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes!)
                                    : null,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            );
                          },
                        )
                      : _buildPlaceholder(
                          Icons.account_circle_rounded,
                          "No Profile",
                        ),
                
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                   Tooltip(
                    message: person.name,
                    child: Text(
                      person.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                    ],
                  )
                ),
              ),
            ],
          ),
        ),
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
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
