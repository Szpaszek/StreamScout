from flask import Flask, jsonify, request
import tmdbsimple as tmdb
import os
import requests.exceptions
from dotenv import load_dotenv # Load environment variables from .env file
from routes.movies import movies_bp
from routes.search import search_bp

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

# flask app initialization
app = Flask(__name__)

# separating apis into blueprints
# register the movies blueprint with the url prefix
app.register_blueprint(movies_bp, url_prefix='/api/movies')
app.register_blueprint(search_bp, url_prefix='/api/search')

# application configuration, shares global objects with blueprints
app.config['tmdb_client'] = tmdb_client

# APIs to use
# Movies:
# tmdb_client.TV().popular DONE
# tmdb_client.Movies().upcoming()
# tmdb_client.Movies().similar_movies ?
# tmdb_client.Movies().latest
# tmdb_client.Movies().recommendations ?
# tmdb_client.Movies().watch_providers

# tv shows
# tmdb_client.TV().latest
# tmdb_client.TV().recommendations ?
# tmdb_client.TV().popular
# tmdb_client.TV().similar ?
# tmdb_client.TV().on_the_air ?
# tmdb_client.TV().watch_providers

# miscellaneous
# tmdb_client.Discover() ? 
# tmdb_client.Genres() ?

if tmdb_client.API_KEY is None or TMDB_READ_ACCESS_TOKEN is None:
    raise ValueError("TMDB_API_KEY and TMDB_READ_ACCESS_TOKEN must be set in environment variables.")

    
# for testing purposes
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