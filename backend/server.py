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

# helper function to process TMDB results into a standardized format
def _process_tmdb_result(result):
    media_type = result.get('media_type') if result.get('media_type') else None
    optimized_data = {
        "id": result.get('id'),
        "media_type": media_type,
    }

    if media_type == 'movie' or media_type == 'tv' or media_type == None:
        # movie/TV fields
        optimized_data["title"] = result.get('title') or result.get('name', 'No Title') # movies use title and shows use name
        optimized_data["overview"] = result.get('overview', 'No overview available.') 
        optimized_data["release_date"] = result.get('release_date') or result.get('first_air_date','Unknown') 
        optimized_data["poster_path"] = f"{IMAGE_BASE_URL}{result.get('poster_path')}" if result.get('poster_path') else None
        optimized_data["rating"] = result.get('vote_average', 0.0)
        optimized_data["backdrop_path"] = f"{IMAGE_BASE_URL}{result.get('backdrop_path')}" if result.get('backdrop_path') else None
        optimized_data["genre_ids"] = result.get('genre_ids', [])

    elif media_type == 'person': 
        # TODO: raw response needs to be checked first
        # actor fields
        optimized_data["name"] = result.get('name', 'No Name')
        optimized_data["profile_path"] = f"{IMAGE_BASE_URL}{result.get('profile_path')}" if result.get('profile_path') else None

        # process nown_for items into a simple list of names for the actor model
        known_for_list = []
        for item in result.get('known_for', []):
            if item.get('media_type') in ['movie', 'tv']:
                known_for_list.append({
                    "id": item.get('id'),
                    "title": item.get('title') or item.get('name', 'Unknown'),
                    "media_type": item.get('media_type')
                })

        optimized_data["known_for"] = known_for_list
        optimized_data["department"] = result.get('known_for_department', 'Unknown')

    else:
        return None
    
    return optimized_data


@app.route('/api/movies/popular', methods=['GET'])
def get_popular_movies():

    try:
        # get the movie object
        movie = tmdb_client.Movies()

        # get popular movies
        popular_movies_response = movie.popular()
        
        optimized_results = []
        for movie in popular_movies_response.get('results', []):
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
    
@app.route('/api/search/multi/', methods=['GET'])
def get_search_results():

    # retrieve the search query from the URL query parameters
    search_query = request.args.get('query')

    if not search_query:
        return jsonify({
            "status": "error",
            "message": "Missing search query parameter 'query'"
        }),

    try:
        search = tmdb_client.Search()
        response = search.multi(query=search_query)

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
    
# for testing puposese
@app.route('/api/test', methods=['GET'])
def test():

     # get the movie object
    series = tmdb_client.TV()

    # get popular movies
    popular_series_response = series.popular()

    optimized_results = []
    # for movie in popular_movies_response.get('results', []):
    #     processed_movie = _process_tmdb_result(movie)
    #     optimized_results.append(processed_movie)

    return popular_series_response


if __name__ == '__main__':
    print("--- Starting Flask Server on http://127.0.0.1:5000 ---")
    app.run(debug=True)