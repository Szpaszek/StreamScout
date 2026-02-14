from flask import Blueprint, jsonify, current_app
import requests.exceptions
from utils.utils import process_tmdb_result

# define the blueprint
discover_bp = Blueprint('discover', __name__)

@discover_bp.route('/popular', methods=['GET'])
def get_popular_combined():
    """
    Fetches a combined list of popular movies and TV shows using the TMDB Trending API.
    """

    # access global variable
    tmdb_client = current_app.config['tmdb_client']

    try:
        # initialize the trending object
        trending = tmdb_client.Trending()

        # use tranding to get a mixed list (movies, shows, people), time_window can be set to 'day' or 'week'
        response = trending.info(time_window='week')

        optimized_results = []
        for media_item in response.get('results', []):

            media_type = media_item.get('media_type')

            # filter out people
            if media_type in ['movie', 'tv']:
                processed_item = process_tmdb_result(media_item)

                # check if processing was successful
                if processed_item:
                    optimized_results.append(processed_item)

        return jsonify({
            "status": "success",
            "media": optimized_results,
            "total_results": response.get('total_results')
        }), 200
    
    # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch popular media"}), 503

    # cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500
