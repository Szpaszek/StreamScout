from flask import Blueprint, jsonify, current_app
import requests.exceptions
from utils.utils import _process_tmdb_result

# define the blueprint
search_bp = Blueprint('search', __name__)

@search_bp.route('/multi/<searchQuery>')
def get_search_results(searchQuery):

    # access global variables
    tmdb_client = current_app.config['tmdb_client']

    try:
        search = tmdb_client.Search()
        response = search.multi(query=searchQuery)

        optimized_results = []

        for result in response.get('results', []):
            processed_result = _process_tmdb_result(result)
            optimized_results.append(processed_result)

        return jsonify({
            "status": "success",
            "results": optimized_results,
            "total_results": response.get('total_results')
        }), 200
    
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch popular movies"}), 503
    
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500