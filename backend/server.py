from flask import Flask, request
from flask_socketio import SocketIO, emit, join_room
import tmdbsimple as tmdb
import os
from dotenv import load_dotenv # Load environment variables from .env file
from tinydb import TinyDB, Query, where
import time
from routes.media import media_bp
from routes.search import search_bp
from routes.discover import discover_bp
from routes.person import person_bp

load_dotenv()

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


# TinyDB
db = TinyDB('backend/db.json')
rooms_table = db.table('rooms')
Room = Query()

# 1 hour experation
def is_expired(created_at):
    return (time.time() - created_at) > 3600

socketio = SocketIO(app, cors_allowed_origins='*')

@socketio.on('add_media')
def handle_add_media(data):
    room_code = data['room']
    media_data = data['media'] # The full movie object from Flutter
    user_id = request.sid      # Unique ID for this connection # type: ignore
    
    room = rooms_table.get(Room.code == room_code)
    
    if not room or is_expired(room['created_at']): # type: ignore
        emit('error', {'msg': 'Room expired or not found'})
        return

    # Check if this user already added something
    # Store submissions as: { 'media_id': { 'data': {...}, 'added_by': 'sid' } }
    submissions = room.get('submissions', {}) # type: ignore
    
    already_added = any(s['added_by'] == user_id for s in submissions.values())
    
    if already_added:
        emit('error', {'msg': 'You can only suggest 1 movie!'})
        return

    # Add the new media
    media_id = str(media_data['id'])
    submissions[media_id] = {
        'data': media_data,
        'added_by': user_id,
        'votes': 0
    }
    
    rooms_table.update({'submissions': submissions}, Room.code == room_code)
    
    # Tell everyone in the room a new movie is up for voting
    emit('media_added', media_data, to=room_code)
    print(f"User {user_id} added {media_data['title']} to room {room_code}")



@socketio.on('create_room')
def handle_create(data):
    room_code = data['code']
    
    # create room structure
    rooms_table.insert({
        'code': room_code,
        'status': 'waiting',
        'submissions': {}, # media_id + vote_count
        'voted_users': [],
        'created_at': time.time()
    })
    join_room(room_code)
    print(f"Room {room_code} created.")

@socketio.on('join_room')
def handle_join(data):
    room_code = data['room']
    join_room(room_code)
    print(f"User {request.sid} joined {room_code}") # type: ignore

@socketio.on('vote')
def handle_vote(data):
    room_code = data['room']
    media_id = str(data['media_id'])
    user_id = request.sid # This is the unique ID for the current connection # type: ignore
    
    room = rooms_table.get(Room.code == room_code)
    if not room or is_expired(room['created_at']): # type: ignore
        emit('error', {'msg': 'Room expired or not found'})
        return

    # 1. Get the lists from the DB
    submissions = room.get('submissions', {}) # type: ignore
    voted_users = room.get('voted_users', []) # List of SIDs who have voted # type: ignore

    # 2. CHECK: Has this user already voted in this room?
    if user_id in voted_users:
        emit('error', {'msg': 'You have already cast your vote!'}, room=user_id) # type: ignore
        return

    if media_id in submissions:
        # 3. CHECK: Is the user voting for their own movie?
        if submissions[media_id]['added_by'] == user_id:
            emit('error', {'msg': 'You cannot vote for your own suggestion!'}, room=user_id) # type: ignore
            return
            
        # 4. SUCCESS: Update the vote count
        submissions[media_id]['votes'] += 1
        
        # 5. RECORD: Add this user to the "voted_users" list
        voted_users.append(user_id)
        
        # 6. SAVE: Update TinyDB
        rooms_table.update({
            'submissions': submissions,
            'voted_users': voted_users
        }, Room.code == room_code)
        
        # 7. BROADCAST: Tell everyone the new score
        emit('update_votes', {
            'movie_id': media_id, 
            'votes': submissions[media_id]['votes']
        }, to=room_code)


if __name__ == '__main__':
    socketio.run(app, debug=True)