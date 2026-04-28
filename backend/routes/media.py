from flask import Blueprint, jsonify, current_app
import requests.exceptions
from utils.utils import process_tmdb_result

# define the blueprint
media_bp = Blueprint('media', __name__)

@media_bp.route('/popular', methods=['GET'])
def get_popular_movies():

    # access global variable
    tmdb_client = current_app.config['tmdb_client']

    try:
        # get the movie object
        movie = tmdb_client.Movies()

        # get popular movies
        response = movie.popular()
        
        optimized_results = []
        for movie in response.get('results', []):
            
            # set media_type for every movie
            movie['media_type'] = 'movie'
            
            processed_movie = process_tmdb_result(movie)
            if processed_movie:
                optimized_results.append(processed_movie)

        return jsonify({
            "status": "success",
            "movies": optimized_results,
            "total_results": response.get('total_results') # total number of popular movies needed for pagination
        }), 200

    # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch popular movies"}), 503

    # cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500
    
@media_bp.route('/upcoming', methods=['GET'])
def get_upcomming_movies():

    # access global variable
    tmdb_client = current_app.config['tmdb_client']

    try:
        # get the movie object
        movie = tmdb_client.Movies()

        # get upcoming movies
        response = movie.upcoming()

        optimized_results = []
        for movie in response.get('results', []):
            
            # set media_type for every movie
            movie['media_type'] = 'movie'
            
            processed_movie = process_tmdb_result(movie)
            if processed_movie:
                optimized_results.append(processed_movie)

        return jsonify({
            "status": "success",
            "movies": optimized_results,
            "total_results": response.get('total_results') # total number of upcoming movies needed for pagination
        }), 200

    # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch upcoming movies"}), 503

    # cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500
    

@media_bp.route('/<string:media_type>/<int:media_id>', methods=['GET'])
def get_media_details(media_type, media_id):

    tmdb_client = current_app.config['tmdb_client']

    try:
        if (media_type == 'movie'):
            movie = tmdb_client.Movies(media_id)
            response = movie.info()

        elif (media_type == 'tv'):
            tv = tmdb_client.TV(media_id)
            response = tv.info()

        else:
            raise Exception('Invalid media typ')

        return jsonify({
            "status": "success",
            media_type: response,
        }), 200

    # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch movie details"}), 503

    # cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500
    

@media_bp.route('/<string:media_type>/<int:media_id>/similar', methods=['GET'])
def get_similar_media(media_type, media_id):

    tmdb_client = current_app.config['tmdb_client']

    try:
        if (media_type == 'movie'):
            movie = tmdb_client.Movies(media_id)
            response = movie.similar_movies()

        elif (media_type == 'tv'):
            tv = tmdb_client.TV(media_id)
            response = tv.similar()

        else:
            raise Exception('Invalid media typ')

        optimized_results = []
        for movie in response.get('results', []):
            
            # set media_type for every movie
            movie['media_type'] = media_type
            
            processed_movie = process_tmdb_result(movie)
            if processed_movie:
                optimized_results.append(processed_movie)

        return jsonify({
            "status": "success",
            "movies": optimized_results,
            "total_results": response.get('total_results') # total number of popular movies needed for pagination
        }), 200

    # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch movie details"}), 503

    # cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500

