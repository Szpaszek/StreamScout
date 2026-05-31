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

# apis to use:
# tmdb_client.Movies().watch_providers
# tmdb_client.TV().watch_providers

if tmdb_client.API_KEY is None or TMDB_READ_ACCESS_TOKEN is None:
    raise ValueError("TMDB_API_KEY and TMDB_READ_ACCESS_TOKEN must be set in environment variables.")


# TinyDB
db = TinyDB('db.json')
rooms_table = db.table('rooms')
Room = Query()

# 1 hour experation
def is_expired(created_at):
    return (time.time() - created_at) > 3600

socketio = SocketIO(app, cors_allowed_origins='*')



@socketio.on('create_room')
def handle_create(data):
    room_code = data['code']
    user_id = request.sid # type: ignore # The host's connection ID 
    
    # create room structure
    rooms_table.insert({
        'code': room_code,
        'status': 'suggesting',
        'host_sid': user_id,
        'submissions': {}, # media_id + vote_count
        'voted_users': [],
        'users': [user_id],
        'created_at': time.time(),
        'timer_end': None
        })
    join_room(room_code)
    print(f"Room {room_code} created.")

    # Let the host know they are successfully hosting
    emit('room_state', {
        'status': 'suggesting',
        'is_host': True,
        'user_count': 1,
        'media_list': [],
        'votes': {}
    }, room=user_id) # type: ignore

@socketio.on('join_room')
def handle_join(data):
    room_code = data['room']
    user_id = request.sid # type: ignore

    room = rooms_table.get(Room.code == room_code)
    if not room:
        emit('error', {'msg': 'Room not found!'})
        return
    
    join_room(room_code)
    print(f"User {request.sid} joined {room_code}") # type: ignore

    # Update user list if they aren't already in it
    current_users = room.get('users', []) # type: ignore
    if user_id not in current_users:
        current_users.append(user_id)
        rooms_table.update({'users': current_users}, Room.code == room_code)

    emit('user_count_update', {'count': len(current_users)}, to=room_code)

    # room data
    submissions = room.get('submissions', {}) # type: ignore
    current_media = [wrapper['data'] for wrapper in submissions.values()]
    current_votes = {mid: wrapper.get('votes', 0) for mid, wrapper in submissions.items()}

# Send current state explicitly to this joining user
    emit('room_state', {
        'status': room['status'], # type: ignore
        'is_host': (room['host_sid'] == user_id), # type: ignore
        'user_count': len(current_users),
        'media_list': current_media,
        'votes': current_votes,
        'timer_end': room.get('timer_end') # Pass the end timestamp if voting already started # type: ignore
    }, room=user_id) # type: ignore

@socketio.on('add_media')
def handle_add_media(data):
    room_code = data['room']
    media_data = data['media'] # The full movie object from Flutter
    user_id = request.sid      # Unique ID for this connection # type: ignore
    
    room = rooms_table.get(Room.code == room_code)
    
    if not room or is_expired(room['created_at']): # type: ignore
        emit('error', {'msg': 'Room expired or not found'})
        return
    
    # Reject submissions if voting has started or ended
    if room.get('status') != 'suggesting': # type: ignore
        emit('error', {'msg': 'Submissions are closed! The room is already voting.'}, room=user_id) # type: ignore
        return

    submissions = room.get('submissions', {}) # type: ignore
    
    already_added = any(s['added_by'] == user_id for s in submissions.values())
    if already_added:
        emit('error', {'msg': 'You can only suggest 1 movie!'}, room=user_id) # type: ignore
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


@socketio.on('start_voting')
def handle_start_voting(data):
    room_code = data['room']
    user_id = request.sid # type: ignore

    room = rooms_table.get(Room.code == room_code)
    if not room or room['host_sid'] != user_id: # type: ignore
        emit('error', {'msg': 'Unauthorized: Only the host can start voting.'}, room=user_id) # type: ignore
        return

    if room['status'] != 'suggesting': # type: ignore
        return

    # Calculate exactly when 5 minutes from now is 
    timer_end_timestamp = time.time() + 30 # normally 300 seconds

    rooms_table.update({
        'status': 'voting',
        'timer_end': timer_end_timestamp
    }, Room.code == room_code)

    # Notify everyone that the phase has shifted and pass the countdown end
    emit('phase_changed', {
        'status': 'voting',
        'timer_end': timer_end_timestamp
    }, to=room_code)
    
    # Start a background timer safely via SocketIO wrapper to auto-close voting
    socketio.start_background_task(target=auto_close_voting, room_code=room_code)

@socketio.on('vote')
def handle_vote(data):
    room_code = data['room']
    media_id = str(data['media_id'])
    user_id = request.sid # This is the unique ID for the current connection # type: ignore
    
    room = rooms_table.get(Room.code == room_code)
    if not room or is_expired(room['created_at']): # type: ignore
        emit('error', {'msg': 'Room expired or not found'})
        return

    current_status = room.get('status') # type: ignore
    if current_status == 'suggesting':
        emit('error', {'msg': 'Voting has not started yet! Waiting for the host.'}, room=user_id) # type: ignore
        return
    elif current_status == 'results':
        emit('error', {'msg': 'Voting has already ended!'}, room=user_id) # type: ignore
        return
    
    # Get the lists from the DB
    submissions = room.get('submissions', {}) # type: ignore
    voted_users = room.get('voted_users', []) # List of SIDs who have voted # type: ignore

    if user_id in voted_users:
            emit('error', {'msg': 'You have already cast your vote!'}, room=user_id)  # type: ignore
            return
    
    if media_id in submissions:
        # Check if the user is voting for their own movie
        if submissions[media_id]['added_by'] == user_id:
            emit('error', {'msg': 'You cannot vote for your own suggestion!'}, room=user_id)  # type: ignore
            return
            
        # Update the vote count
        submissions[media_id]['votes'] += 1
        
        # Add this user to the "voted_users" list
        voted_users.append(user_id)
        
        # Update TinyDB
        rooms_table.update({
            'submissions': submissions,
            'voted_users': voted_users
        }, Room.code == room_code)
        
        # Tell everyone the new score
        emit('update_votes', {
            'media_id': media_id, 
            'votes': submissions[media_id]['votes']
        }, to=room_code)


def auto_close_voting(room_code):
    # Sleep for 5 minutes
    socketio.sleep(30) # 30 seconds in debug
    
    room = rooms_table.get(Room.code == room_code)
    if room and room['status'] == 'voting': # type: ignore
        rooms_table.update({'status': 'results'}, Room.code == room_code)
        
        # Determine winner
        submissions = room.get('submissions', {}) # type: ignore
        if submissions:
            winner = max(submissions.values(), key=lambda x: x['votes'])['data']
        else:
            winner = None # No movies were added

        socketio.emit('phase_changed', {
            'status': 'results',
            'winner': winner
        }, to=room_code)

        # 60 seconds to look at the winner screen on Flutter
        socketio.sleep(60)

        # notify that the session is officially over
        socketio.emit('room_expired', {
            'msg': 'Voting session completed. Room closed!'
        }, to=room_code)
        
        # clean up completely
        socketio.close_room(room_code)
        rooms_table.remove(Room.code == room_code)
        print(f"Room {room_code} successfully closed and deleted.")

def room_janitor():
    """A single background task that runs forever, cleaning up old rooms."""
    while True:
        socketio.sleep(600)  # run every 10 minutes 600
        print("Janitor: Starting database cleanup...")
        
        now = time.time()
        # 2 hours = 7200 seconds
        two_hours_ago = now - 7200

        # find all rooms that are about to be deleted
        expired_rooms = rooms_table.search(Room.created_at < two_hours_ago)

        for room in expired_rooms:
            room_code = room['code']

            # BUG: for some reason deas not send a message
            # alert the frontend users still in this socket room
            socketio.emit('room_expired', {
                'msg': 'This room has been closed due to inactivity.'
            }, to=room_code)

            socketio.sleep(60)

            # forcefully close the room on the socket server side
            socketio.close_room(room_code)
        
        # Remove rooms that are older than 2 hours
        rooms_table.remove(Room.created_at < two_hours_ago)
        print("Janitor: Cleanup complete.")


if __name__ == '__main__':
    socketio.start_background_task(target=room_janitor)
    socketio.run(app, debug=False)