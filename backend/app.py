from flask import Flask, jsonify, request
from flask_cors import CORS
import requests
import os                     # Added to read system variables
from dotenv import load_dotenv # Added to load the .env file

app = Flask(__name__)
CORS(app)

# -------------------
# Jamendo credentials (Loaded securely!)
# -------------------
CLIENT_ID = os.getenv("JAMENDO_CLIENT_ID")
BASE_URL = "https://api.jamendo.com/v3.0/"

# -------------------
# Test endpoint
# -------------------
@app.route("/")
def home():
    return jsonify({"message": "Jamendo backend working!"})

# -------------------
# Search for tracks
# -------------------
@app.route("/search_song", methods=["GET"])
def search_song():
    query = request.args.get("q")
    if not query:
        return jsonify({"error": "No query provided"}), 400

    url = f"{BASE_URL}tracks/?client_id={CLIENT_ID}&format=json&limit=20&search={query}"
    response = requests.get(url)
    data = response.json()

    songs = []
    for track in data.get("results", []):
        songs.append({
            "title": track["name"],
            "artist": track["artist_name"],
            "albumArt": track["album_image"],
            "audio": track["audio"]
        })

    return jsonify({"results": songs})

# -------------------
# Home tracks
# -------------------
@app.route("/home_tracks", methods=["GET"])
def get_home_tracks():
    url = f"{BASE_URL}tracks/?client_id={CLIENT_ID}&format=json&limit=25"
    response = requests.get(url)
    data = response.json()

    tracks = []
    for track in data.get("results", []):
        tracks.append({
            "title": track["name"],
            "artist": track["artist_name"],
            "albumArt": track["album_image"],
            "audio": track["audio"]
        })

    return jsonify({"results": tracks})

# -------------------
# Recommendations endpoint
# -------------------
@app.route("/recommendations", methods=["POST"])
def get_recommendations():
    data = request.json
    favorite_artists = data.get("favoriteArtists", [])
    favorite_genres = data.get("favoriteGenres", [])

    if not favorite_artists and not favorite_genres:
        return jsonify({"error": "No favorite artists or genres provided"}), 400

    queries = []
    if favorite_artists:
        queries.append(" OR ".join(favorite_artists))
    if favorite_genres:
        queries.append(" OR ".join(favorite_genres))

    search_query = " ".join(queries)
    url = f"{BASE_URL}tracks/?client_id={CLIENT_ID}&format=json&limit=20&search={search_query}"
    response = requests.get(url)
    data = response.json()

    if not data.get("results"):
        return jsonify({"error": "No recommendations found"}), 404

    recommendations = []
    for track in data.get("results", []):
        recommendations.append({
            "title": track["name"],
            "artist": track["artist_name"],
            "albumArt": track["album_image"],
            "audio": track["audio"]
        })

    return jsonify({"results": recommendations})

# -------------------
# Run Flask
# -------------------
if __name__ == "__main__":
    print("Starting Flask server...")
    app.run(host="0.0.0.0", port=5000, debug=True)
