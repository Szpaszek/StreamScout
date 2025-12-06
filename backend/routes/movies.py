from flask import Blueprint, jsonify, current_app
import requests.exceptions
from utils.utils import _process_tmdb_result

# define the blueprint
movies_bp = Blueprint('movies', __name__)

@movies_bp.route('/popular', methods=['GET'])
def get_popular_movies():

    # access global variables
    tmdb_client = current_app.config['tmdb_client']

    try:
        # get the movie object
        movie = tmdb_client.Movies()

        # get popular movies
        popular_movies_response = movie.popular()
        
        optimized_results = []
        for movie in popular_movies_response.get('results', []):
            
            # set media_type for every movie
            movie['media_type'] = 'movie'
            
            processed_movie = _process_tmdb_result(movie)
            if processed_movie:
                optimized_results.append(processed_movie)

        return jsonify({
            "status": "success",
            "movies": optimized_results,
            "total_results": popular_movies_response.get('total_results') # total number of popular movies needed for pagination
        }), 200

    # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch popular movies"}), 503

    # cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500