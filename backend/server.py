import json
from flask import Flask, request
from flask_socketio import SocketIO, emit, join_room
import redis
import tmdbsimple as tmdb
import os
from dotenv import load_dotenv # Load environment variables from .env file
import time

from routes.media import media_bp
from routes.search import search_bp
from routes.discover import discover_bp
from routes.person import person_bp
from voting.room_events import register_voting_events

load_dotenv()

# get TMDB API key and read access token from environment variables
TMDB_API_KEY = os.getenv("TMDB_API_KEY")
TMDB_READ_ACCESS_TOKEN = os.getenv("TMDB_READ_ACCESS_TOKEN")
APP_TOKEN = os.getenv("APP_TOKEN")

if not TMDB_API_KEY or not TMDB_READ_ACCESS_TOKEN or not APP_TOKEN:
    raise ValueError("TMDB_API_KEY, TMDB_READ_ACCESS_TOKEN and APP_TOKEN must be set in environment variables.")

# Base URL for images from TMDB with width 500px for mobile optimization
IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500"

# flask app initialization
app = Flask(__name__)

# Initialize TMDB client
tmdb_client = tmdb
tmdb_client.API_KEY = TMDB_API_KEY
tmdb_client.REQUESTS_TIMEOUT = 5  # seconds for API requests

# separating apis into blueprints
# register the movies blueprint with the url prefix
app.register_blueprint(media_bp, url_prefix='/api/media')
app.register_blueprint(search_bp, url_prefix='/api/search')
app.register_blueprint(discover_bp, url_prefix='/api/discover')
app.register_blueprint(person_bp, url_prefix='/api/person')

# application configuration, shares global objects with blueprints
app.config['tmdb_client'] = tmdb_client

# apis to use:
# tmdb_client.Movies().watch_providers
# tmdb_client.TV().watch_providers


# connect to redis
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'localhost'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    db=0,
    decode_responses=True # Automatically converts bytes to Python strings
)
# Using Redis as a message queue 
socketio = SocketIO(
    app, 
    cors_allowed_origins='*', 
    path="voting_room/socket.io",
    message_queue=f"redis://{os.getenv('REDIS_HOST', 'localhost')}:6379/0"
)

register_voting_events(
    socketio=socketio,
    redis_client=redis_client,
    app_token=APP_TOKEN
)


# Test route
@app.route('/test/')
def index():
    # Example: Incrementing a simple page hit counter
    hits = redis_client.incr('page_hits')
    return f"This page has been viewed {hits} times!"


if __name__ == '__main__':
    socketio.run(app, debug=False)