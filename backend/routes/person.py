from flask import Blueprint, jsonify, current_app
import requests.exceptions
from utils.security import require_app_token
from utils.utils import process_tmdb_result

# define the blueprint
person_bp = Blueprint('person', __name__)

@person_bp.route('/details/<int:person_id>', methods=['GET'])
@require_app_token
def get_person_details(person_id):
            # access global variable
    tmdb_client = current_app.config['tmdb_client']

    try:
        people = tmdb_client.People(person_id)

        response = people.info()

        return jsonify({
            "status": "success",
            "details": response,
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
@require_app_token
def get_person_credits(person_id):

        # access global variable
    tmdb_client = current_app.config['tmdb_client']

    try:
        people = tmdb_client.People(person_id)

        response = people.combined_credits()

        raw_cast = response.get('cast', [])

        # remove duplicates
        seen_ids = set()
        unique_cast = []
        for item in raw_cast:
            item_id = item.get('id')
            if item_id and item_id not in seen_ids:
                seen_ids.add(item_id)
                unique_cast.append(item)

        # Sort by popularity in descending order (highest popularity first)
        unique_cast.sort(key=lambda x: x.get('popularity', 0.0), reverse=True)

        if len(unique_cast) > 100:
            unique_cast = unique_cast[:100]

        optimized_results = []
        for media in unique_cast:
            processed_media = process_tmdb_result(media)
            if processed_media:
                optimized_results.append(processed_media)

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