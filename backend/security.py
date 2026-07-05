from functools import wraps
import os 
from flask import abort, request
from dotenv import load_dotenv

load_dotenv()

APP_TOKEN = os.getenv("APP_TOKEN")

# decorator for http requests
def require_app_token(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        # get app token from the request header
        token = request.headers.get('X-StreamScout-Token')
        if token != APP_TOKEN:
            print(f"WARNING: Unauthorized request from the IP: {request.remote_addr}")
            abort(401) # 401 Unautherized
        return f(*args, **kwargs)
    return decorated
