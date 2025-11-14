# Backend Documentation

This server acts as a secure proxy, now using the 'tmdbsimple' package.
1. Flutter calls the endpoints of the server 
2. Flask calls TMDB using the hidden API key (managed by tmdb_client).
3. Flask returns optimized data to Flutter

# Running the server

1. To run the server create a virtual enviroment:

    python -m venv venv

When properly installed and activated, (venv) should be visible in the terminal 

2. install requered packages:

    pip install -r requirements.txt

