import 'package:flutter/material.dart';
import 'package:frontend/models/movie.dart';

class Moviecard extends StatelessWidget{
   final Movie movie;
  const Moviecard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) // Buildcontext is a reference to the location of a widget in the widget tree
  {
    return Container( // Container is a widget that allows for styling and positioning of its child widgets
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2)
          )
        ]
      ),

      //  Column widget to arrange child widgets vertically
      child: Column( // a child is a widget that is contained within another widget
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          // Expanded widget to make the image take up available space
          Expanded(
            flex: 5, // Ratio of size, for example 5:2
            child: ClipRRect( // ClipRRect is a widget that clips its child using a rounded rectangle
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),

              // The posterPath is provided by the Flask backend
              child: movie.posterPath != null ? 

              // if the posterPath exists, download and display the image from the URL
              Image.network(
                movie.posterPath!,
                fit: BoxFit.cover, // BoxFit.cover scales the image to cover the entire widget area

                // if the image fails to load, display a placeholder icon
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(Icons.image_not_supported, "Image not available"),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(

                    // Show a loading indicator while the image is being loaded
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes!)
                          : null,
                      color: Colors.amber,
                    ),
                  );
                }
              )
              : _buildPlaceholder(Icons.movie, "No Poster")
            ) 
          ),

          Expanded(
            flex: 2,
            child: Padding(
              // padding just like in CSS
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left edge
                children: [
                  // Tooltip widget to show full title on hover
                  Tooltip(
                    message: movie.title,
                    child: Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                      maxLines: 2, // Limit title to one line
                      overflow: TextOverflow.ellipsis, // Show ellipsis if title is too long
                    ),
                  ),
                  const Spacer(), // Spacer to add space between title and rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4), // Space between star and rating
                      Text(
                        movie.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      )
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
            Text(message, style: const TextStyle(color: Colors.grey))
          ]
        ),
      ),
    );
  }
}
