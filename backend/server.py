from flask import Flask, jsonify, request
import tmdbsimple as tmdb
import os
import requests.exceptions
from dotenv import load_dotenv # Load environment variables from .env file

load_dotenv()

app = Flask(__name__)

# get TMDB API key and read access token from environment variables
TMDB_API_KEY = os.getenv("TMDB_API_KEY")
TMDB_READ_ACCESS_TOKEN = os.getenv("TMDB_READ_ACCESS_TOKEN")

# Base URL for images from TMDB with width 500px for mobile optimization
IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500"

# Initialize TMDB client
tmdb_client = tmdb
tmdb_client.API_KEY = TMDB_API_KEY
tmdb_client.REQUESTS_TIMEOUT = 5  # seconds for API requests

if tmdb_client.API_KEY is None or TMDB_READ_ACCESS_TOKEN is None:
    raise ValueError("TMDB_API_KEY and TMDB_READ_ACCESS_TOKEN must be set in environment variables.")

@app.route('/api/movies/popular', methods=['GET'])
def get_popular_movies():

    try:
        # get the movie object
        movie = tmdb_client.Movies()

        # get popular movies
        popular_movies_response = movie.popular()
        
        optimized_results = []
        for movie in popular_movies_response.get('results', []):
            optimized_results.append({
                "id": movie.get('id'),
                "title": movie.get('title'),
                "overview": movie.get('overview'),
                "release_date": movie.get('release_date'),
                # Use optimized image URL
                "poster_path": f"{IMAGE_BASE_URL}{movie.get('poster_path')}" if movie.get('poster_path') else None,
                "vote_average": movie.get('vote_average')
            })

        return jsonify({
            "status": "success",
            "movies": optimized_results,
            "total_results": popular_movies_response.get('total_results') # total number of popular movies needed for pagination
        }), 200

    # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch popular movies"}), 503

    #cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500
    return "Hello, World!"

if __name__ == '__main__':
    print("--- Starting Flask Server on http://127.0.0.1:5000 ---")
    app.run(debug=True)