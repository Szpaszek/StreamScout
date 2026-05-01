from flask import Blueprint, jsonify, current_app
import requests.exceptions
from utils.utils import process_tmdb_result

# define the blueprint
person_bp = Blueprint('person', __name__)

@person_bp.route('/details/<int:person_id>', methods=['GET'])
def get_person_details(person_id):
            # access global variable
    tmdb_client = current_app.config['tmdb_client']

    try:
        people = tmdb_client.People(person_id)

        response = people.info()

        return jsonify({
            "status": "success",
            "media": response,
            "total_results": response.get('total_results') # total number of upcoming movies needed for pagination
        }), 200

    # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch credits"}), 503

    # cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500

@person_bp.route('/credits/<int:person_id>', methods=['GET'])
def get_person_credits(person_id):

        # access global variable
    tmdb_client = current_app.config['tmdb_client']

    try:
        people = tmdb_client.People(person_id)

        response = people.combined_credits()

        optimized_results = []
        for movie in response.get('cast', []):
            
            # set media_type for every movie
            movie['media_type'] = 'movie'
            
            processed_movie = process_tmdb_result(movie)
            if processed_movie:
                optimized_results.append(processed_movie)

        return jsonify({
            "status": "success",
            "media": optimized_results,
        }), 200

    # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch credits"}), 503

    # cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500