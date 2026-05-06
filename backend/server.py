from flask import Flask, jsonify, request
from flask_socketio import SocketIO, emit, join_room
import tmdbsimple as tmdb
import os
from dotenv import load_dotenv # Load environment variables from .env file
import redis
import json
from routes.media import media_bp
from routes.search import search_bp
from routes.discover import discover_bp
from routes.person import person_bp

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

# tmdb_client.Discover().

# separating apis into blueprints
# register the movies blueprint with the url prefix
app.register_blueprint(media_bp, url_prefix='/api/media')
app.register_blueprint(search_bp, url_prefix='/api/search')
app.register_blueprint(discover_bp, url_prefix='/api/discover')
app.register_blueprint(person_bp, url_prefix='/api/person')

# application configuration, shares global objects with blueprints
app.config['tmdb_client'] = tmdb_client

# APIs to use
# Movies:
# tmdb_client.TV().popular DONE
# tmdb_client.Movies().upcoming()
# tmdb_client.Movies().similar_movies 
# tmdb_client.TV().similar

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
# tmdb_client.Trending()

if tmdb_client.API_KEY is None or TMDB_READ_ACCESS_TOKEN is None:
    raise ValueError("TMDB_API_KEY and TMDB_READ_ACCESS_TOKEN must be set in environment variables.")

# Redis connection (default port is 6379)
r = redis.Redis(host='localhost', port=6379, decode_responses=True)
socketio = SocketIO(app, cors_allowed_origins='*')

@socketio.on('create_room')
def handle_create(data):
    room_code = data['code']
    # initializing the room in Redis with a 1-hour expiration
    r.hset(f"room:{room_code}", "status", "waiting")
    r.expire(f"room:{room_code}", 3600)
    join_room(room_code)
    print(f"Room {room_code} created.")

@socketio.on('vote')
def handle_vote(data):
    room_code = data['room']
    movie_id = data['movie_id']

    # atomic increment in Redis prevents rare conditions
    # if 10 people vote at the exact same time
    new_votes = r.hincrby(f"room:{room_code}", movie_id, 1)

    # broadcast the updated count to everyone in that specific room
    emit('update_votes', {'movie_id': movie_id, 'votes': new_votes}, to=room_code)
    
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
    socketio.run(app, debug=True)