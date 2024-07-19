from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

# In-memory user list for demonstration purposes
users = [{'id': 1, 'name': 'User1'}, {'id': 2, 'name': 'User2'}, {'id': 3, 'name': 'User3'}]

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/add_user', methods=['POST'])
def add_user():
    new_user = request.json
    users.append(new_user)
    return jsonify({'status': 'success', 'user': new_user})

@app.route('/get_users')
def get_users():
    return jsonify(users)

@app.route('/edit_user', methods=['POST'])
def edit_user():
    updated_user = request.json
    for user in users:
        if user['id'] == int(updated_user['id']):
            user['name'] = updated_user['name']
            break
    return jsonify({'status': 'success', 'user': updated_user})

@app.route('/delete_user', methods=['POST'])
def delete_user():
    user_id = int(request.json['id'])
    global users
    users = [user for user in users if user['id'] != user_id]
    return jsonify({'status': 'success'})

if __name__ == '__main__':
    app.run(debug=True)
