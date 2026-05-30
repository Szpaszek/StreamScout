import 'package:flutter/material.dart';

class StreamingProvidersRow extends StatelessWidget {
  final List<dynamic> providers;

  const StreamingProvidersRow({super.key, required this.providers});

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const SizedBox.shrink(); // hide section if no providers
    }

    const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w200';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Streaming Services",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final service = providers[index] as Map<String, dynamic>;
              final logoPath = service['logo_path'] ?? '';
              final providerName =
                  service['provider_name'] ?? 'Unknown Provider';
              final fullImageUrl = '$tmdbImageBaseUrl$logoPath';

              if (logoPath.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Tooltip(
                  message: providerName,
                  child: ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(8),
                    child: Image.network(
                      fullImageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,

                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.broken_image,
                          size: 20,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
