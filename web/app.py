from flask import Flask, jsonify, render_template

app = Flask(__name__)


if __name__ == "__main__":
  app.run(host='0.0.0.0', port=8000, debug=False)