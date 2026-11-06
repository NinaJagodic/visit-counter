import os
import socket
from flask import Flask, jsonify
import redis

app = Flask(__name__)

APP_PORT = int(os.getenv("APP_PORT", 5000))
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))

db = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

@app.route("/")
def home():
    return jsonify(message="Hello DevOps", host=socket.gethostname())

@app.route("/visits")
def visits():
    try:
        count = db.incr("visits")
    except redis.ConnectionError:
        count = 0
    return jsonify(visits=count)

@app.route("/health")
def health():
    try:
        if db.ping():
            return jsonify(status="ok"), 200
    except Exception:
        pass
    return jsonify(status="error"), 503

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=APP_PORT)