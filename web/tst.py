import subprocess
from flask import Flask, render_template, jsonify

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/get_users')
def get_users():
    try:
        group_id = subprocess.check_output("getent group safetp | cut -d: -f3", shell=True).decode('utf-8').strip()
        users = subprocess.check_output(f"cat /etc/passwd | grep {group_id} | cut -d: -f1", shell=True).decode('utf-8').split()
        user_list = [{'id': i + 1, 'name': user} for i, user in enumerate(users)]
    except subprocess.CalledProcessError:
        user_list = []

    return jsonify(user_list)

if __name__ == '__main__':
    app.run(debug=True)
