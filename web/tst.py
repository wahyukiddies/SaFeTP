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
        users = subprocess.check_output(f"getent passwd | awk -F: '$4 == {group_id} {{print $1}}'", shell=True).decode('utf-8').split()
        user_list = [{'id': i + 1, 'name': user} for i, user in enumerate(users)]
    except subprocess.CalledProcessError:
        user_list = []

    return jsonify(user_list)

@app.route('/add_user', methods=['POST'])
def add_user():
    data = request.json
    user_names = data.get('names', [])

    if user_names:
        try:
            # Overwrite the userlist.txt file with new user names
            with open('userlist.txt', 'w') as file:
                for user_name in user_names:
                    file.write(f"{user_name}\n")
            
            # Run the safetp.sh script
            # subprocess.run("sudo safetp.sh -l userlist.txt", shell=True, check=True)
            subprocess.run("sudo echo userlist.txt", shell=True, check=True)
            
            return jsonify({'status': 'success', 'message': 'Users added and script executed'}), 200
        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)}), 500
    return jsonify({'status': 'error', 'message': 'Invalid data'}), 400

@app.route('/delete_user', methods=['POST'])
def delete_user():
    data = request.json
    user_name = data.get('name')

    if user_name:
        try:
            # Delete user from system and remove home directory
            subprocess.run(f"sudo userdel {user_name}", shell=True, check=True)
            subprocess.run(f"sudo rm -rf /home/{user_name}", shell=True, check=True)
            return jsonify({'status': 'success', 'message': 'User and home directory deleted'}), 200
        except subprocess.CalledProcessError:
            return jsonify({'status': 'error', 'message': 'Failed to delete user'}), 500
    return jsonify({'status': 'error', 'message': 'Invalid data'}), 400

if __name__ == '__main__':
    app.run(debug=True)
