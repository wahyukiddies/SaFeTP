import subprocess
from flask import Flask, render_template, jsonify, request

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

@app.route('/add_user', methods=['POST'])
def add_user():
    data = request.json
    users = data.get('names')

    if users:
        with open('userlist.txt', 'w') as file:  # Open the file in write mode to replace its content
            for user_name in users:
                file.write(f"{user_name}\n")
        return jsonify({'status': 'success', 'message': 'Users added'}), 200
    return jsonify({'status': 'error', 'message': 'Invalid data'}), 400

@app.route('/delete_user', methods=['POST'])
def delete_user():
    data = request.json
    user_id = data.get('id')
    password = data.get('password')

    try:
        # Get the user to be deleted from /etc/passwd
        user_to_delete = subprocess.check_output(f"cat /etc/passwd | cut -d: -f1 | awk 'NR=={user_id}'", shell=True).decode('utf-8').strip()
        
        if user_to_delete:
            # Run the deleteuser.sh script with the specified user
            command = f'echo {password} | sudo -S ./deleteuser.sh {user_to_delete}'
            subprocess.run(command, shell=True, check=True)
            return jsonify({'status': 'success', 'message': 'User deleted'}), 200
        return jsonify({'status': 'error', 'message': 'User not found'}), 404
    except subprocess.CalledProcessError:
        return jsonify({'status': 'error', 'message': 'Failed to delete user'}), 500


if __name__ == '__main__':
    app.run(debug=True)
