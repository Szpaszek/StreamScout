from datetime import datetime, timedelta
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
    

@discover_bp.route('latest', methods=['GET'])
def get_latest_releases():
    """
    Fetches the latest released movies and TV shows (within the last 30 days).
    Uses the Discover API for better results than the 'latest' endpoint.
    """
    tmdb_client = current_app.config['tmdb_client']

    # Calculate date range: Today and 30 days ago
    today = datetime.now().strftime('%Y-%m-%d')
    thirty_days_ago = (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d')

    try:
        discover = tmdb_client.Discover()

        # 1. Recently released movies
        movie_response = discover.movie(
            primary_release_date_gte=thirty_days_ago,
            primary_release_date_lte=today,
            sort_by='primary_release_date.desc'
        )
        movies = movie_response.get('results', [])
        for m in movies: m['media_type'] = 'movie'

        # 2. Recently released TV shows
        tv_response = discover.tv(
            first_air_date_gte=thirty_days_ago,
            first_air_date_lte=today,
            sort_by='first_air_date.desc'
        )
        tv_shows = tv_response.get('results', [])
        for t in tv_shows: t['media_type'] = 'tv'

        # 3. Combine and Process
        combined_raw = movies + tv_shows
        # Sort by popularity to ensure we don't show obscure indie titles at the top
        combined_raw.sort(key=lambda x: x.get('popularity', 0), reverse=True)

        optimized_results = []
        for item in combined_raw:
            processed = process_tmdb_result(item)
            if processed:
                optimized_results.append(processed)

        return jsonify({
            "status": "success",
            "media": optimized_results,
            "total_results": len(optimized_results)
        }), 200
    
        # cathing any request exceptions from tmdbsimple
    except requests.exceptions.RequestException as e:
        print(f"Error communicating with TMDB API: {e}")
        return jsonify({"status": "error", "message": "Failed to fetch popular media"}), 503

    # cathing any other unexpected exceptions
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"status": "error", "message": "An unexpected error occurred"}), 500