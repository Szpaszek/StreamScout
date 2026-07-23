import json
import time

from flask import request
from flask_socketio import emit, join_room

ROOM_TTL_SECONDS = 3600
VOTING_DURATION_SECONDS = 30
RESULTS_DUARATION_SECONDS = 60

# Helper function to generate standardized Redis keys
def get_room_key(room_code):
    return f"room:{room_code}"

# 1 hour experation
def is_expired(created_at):
    return (time.time() - float(created_at)) > 3600

def register_voting_events(socketio, redis_client, app_token):

    # check token when user connects
    @socketio.on('connect')
    def handle_connect():
        # check query parameter during handshake
        token = request.headers.get('X-StreamScout-Token')

        # fallback
        if not token:
            token = request.args.get('token')

        if token != app_token:
            print(f"Invalid token from {request.remote_addr}, Websocket connection was denied.")
            return False
        print(f"Socket connected: {request.sid}")


    # create room
    @socketio.on('create_room')
    def handle_create(data):
        room_code = data['code']
        user_id = request.sid # type: ignore # The host's connection ID 
        room_key = get_room_key(room_code)

        if redis_client.exists(room_key):
            emit('error', {'msg': 'Room already exists!'}, room=user_id)
            return
        
    # Create room mapping using Redis Hashes. Complex types are JSON stringified.
        room_data = {
            'code': room_code,
            'status': 'suggesting',
            'host_sid': user_id,
            'submissions': json.dumps({}), 
            'voted_users': json.dumps([]),
            'users': json.dumps([user_id]),
            'created_at': time.time(),
            'timer_end': '' # Redis fields are string-based; use empty string for None
        }

        redis_client.hset(room_key, mapping=room_data)
        # Set a 24-hour safety TTL on the Redis key so dead rooms automatically vanish
        redis_client.expire(room_key, ROOM_TTL_SECONDS)

        join_room(room_code)
        print(f"Room {room_code} created in Redis.")

        # Let the host know they are successfully hosting
        emit('room_state', {
            'status': 'suggesting',
            'is_host': True,
            'user_count': 1,
            'media_list': [],
            'votes': {}
        }, room=user_id) 

    # join to a existing room
    @socketio.on('join_room')
    def handle_join(data):
        room_code = data['room']
        user_id = request.sid # type: ignore
        room_key = get_room_key(room_code)

        room = redis_client.hgetall(room_key)
        if not room:
            emit('error', {'msg': 'Room not found!'})
            return
        
        join_room(room_code)
        print(f"User {user_id} joined {room_code}") 

        # Update user list if they aren't already in it
        current_users = json.loads(room['users'])

        if user_id not in current_users:
            current_users.append(user_id)
            redis_client.hset(room_key, 'users', json.dumps(current_users))

        emit('user_count_update', {'count': len(current_users)}, to=room_code)

        # room data
        submissions = json.loads(room['submissions']) 

        current_media = [
            wrapper['data'] 
            for wrapper in submissions.values()
            ]
        
        current_votes = {
            mid: wrapper.get('votes', 0) 
            for mid, wrapper in submissions.items()
            }

        timer_end = room.get('timer_end')

    # Send current state explicitly to this joining user
        emit('room_state', {
                'status': room['status'], 
                'is_host': (room['host_sid'] == user_id), 
                'user_count': len(current_users),
                'media_list': current_media,
                'votes': current_votes,
                'timer_end': float(timer_end) if timer_end else None 
            }, room=user_id)

    @socketio.on('add_media')
    def handle_add_media(data):
        room_code = data['room']
        media_data = data['media'] # The full movie object from Flutter
        user_id = request.sid      # Unique ID for this connection # type: ignore
        room_key = get_room_key(room_code)
        
        room = redis_client.hgetall(room_key)
        
        if not room or is_expired(room['created_at']): 
            emit('error', {'msg': 'Room expired or not found'},
                 room=user_id)
            return
        
        # Reject submissions if voting has started or ended
        if room.get('status') != 'suggesting': 
            emit('error', {'msg': 'Submissions are closed! The room is already voting.'}, 
                 room=user_id) # type: ignore
            return

        submissions = json.loads(room['submissions'])
        
        already_added = any(
            s['added_by'] == user_id 
            for s in submissions.values())
        
        if already_added:
            emit('error', {'msg': 'You can only suggest 1 movie!'}, 
                 room=user_id) 
            return

        # Add the new media
        media_id = str(media_data['id'])

        submissions[media_id] = {
            'data': media_data,
            'added_by': user_id,
            'votes': 0
        }
        
        redis_client.hset(
            room_key, 
            'submissions', 
            json.dumps(submissions))
        
        # Tell everyone in the room a new movie is up for voting
        emit('media_added', media_data, to=room_code)
        print(f"User {user_id} added {media_data['title']} to room {room_code}")


    @socketio.on('start_voting')
    def handle_start_voting(data):
        room_code = data['room']
        user_id = request.sid # type: ignore
        room_key = get_room_key(room_code)

        room = redis_client.hgetall(room_key)

        if not room:
            emit(
                "error",
                {"msg": "Room not found."},
                room=user_id,
            )
            return

        if room["host_sid"] != user_id:
            emit(
                "error",
                {"msg": "Only the host can start voting."},
                room=user_id,
            )
            return

        if room['status'] != 'suggesting': 
            return

        # Calculate exactly when 5 minutes from now is 
        timer_end_timestamp = time.time() + VOTING_DURATION_SECONDS

        redis_client.hset(room_key, mapping={
            'status': 'voting',
            'timer_end': timer_end_timestamp
        },
        )

        # Notify everyone that the phase has shifted and pass the countdown end
        emit('phase_changed', {
            'status': 'voting',
            'timer_end': timer_end_timestamp
        }, to=room_code)
        
        # Start a background timer safely via SocketIO wrapper to auto-close voting
        socketio.start_background_task(
            auto_close_voting,
            socketio,
            redis_client,
            room_code,
        )

    @socketio.on('vote')
    def handle_vote(data):
        room_code = data['room']
        media_id = str(data['media_id'])
        user_id = request.sid # This is the unique ID for the current connection # type: ignore
        room_key = get_room_key(room_code)
        
        room = redis_client.hgetall(room_key)
        if not room or is_expired(room['created_at']): 
            emit('error', {'msg': 'Room expired or not found'})
            return

        current_status = room.get('status') 
        if current_status == 'suggesting':
            emit('error', {'msg': 'Voting has not started yet! Waiting for the host.'}, room=user_id) 
            return
        elif current_status == 'results':
            emit('error', {'msg': 'Voting has already ended!'}, room=user_id) 
            return
        
        # Get the lists from the DB
        submissions = json.loads(room['submissions'])
        voted_users = json.loads(room['voted_users'])# List of SIDs who have voted 

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
            
            redis_client.hset(room_key, mapping={
                'submissions': json.dumps(submissions),
                'voted_users': json.dumps(voted_users)
            })
            
            # Tell everyone the new score
            emit('update_votes', {
                'media_id': media_id, 
                'votes': submissions[media_id]['votes']
            }, to=room_code)


def auto_close_voting(socketio, redis_client, room_code: str):
    # Sleep for 5 minutes
    socketio.sleep(VOTING_DURATION_SECONDS) # 30 seconds in debug
    room_key = get_room_key(room_code)
    
    room = redis_client.hgetall(room_key)
    if room and room['status'] == 'voting': 
        redis_client.hset(room_key, 'status', 'results')
        
        # Determine winner
        submissions = json.loads(room['submissions'])
        if submissions:
            winner = max(submissions.values(), key=lambda x: x['votes'])['data']
        else:
            winner = None # No movies were added

        socketio.emit('phase_changed', {
            'status': 'results',
            'winner': winner
        }, to=room_code)

        # 60 seconds to look at the winner screen on Flutter
        socketio.sleep(RESULTS_DUARATION_SECONDS)

        # notify that the session is officially over
        socketio.emit('room_expired', {
            'msg': 'Voting session completed. Room closed!'
        }, to=room_code)
        
        # clean up completely
        socketio.close_room(room_code)
        redis_client.delete(room_key)
        print(f"Room {room_code} successfully closed and and deleted from Redis.")