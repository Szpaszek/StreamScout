
# helper function to process TMDB results into a standardized format
def _process_tmdb_result(result):

    IMAGE_BASE_URL = "https://image.tmdb.org/t/p/w500"
    media_type = result.get('media_type') if result.get('media_type') else None
    optimized_data = {
        "id": result.get('id'),
        "media_type": media_type,
    }

    if media_type == 'movie' or media_type == 'tv':
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

        # process known_for items into a simple list of names for the actor model
        known_for_list = []
        for item in result.get('known_for', []):
            # recursively process the item to get a full Media JSON structure
            processed_item = _process_tmdb_result(item)

            # ensure it is a movie or tv show
            if processed_item and processed_item['media_type'] in ['movie', 'tv']:
                known_for_list.append(processed_item)

        optimized_data["known_for"] = known_for_list
        optimized_data["department"] = result.get('known_for_department', 'Unknown')

    else:
        return None
    
    return optimized_data