from flask import Flask, request, jsonify, render_template, Blueprint
from flask_restx import Api, Resource, fields
import os

app = Flask(__name__)

# Blueprint untuk API
api_bp = Blueprint('api', __name__, url_prefix='/api/v1')
api = Api(api_bp, version='1.0', title='SafeTP API', 
          description='API SaFeTP untuk mengelola username dan password FTP', 
          doc='/docs')

ns = api.namespace('users', description='Operasi pengguna')

user_model = api.model('User', {
  'username': fields.String(required=True, description='FTP username'),
  'password': fields.String(required=True, description='FTP password')
})

update_user_model = api.model('UpdateUser', {
  'new_username': fields.String(required=True, description='FTP new username'),
  'new_password': fields.String(required=True, description='FTP new password')
})

# Path ke file allowed file yang berisi daftar username yang diizinkan.
allowed_users_file = '/etc/safetp/allowed'

# Fungsi untuk membaca file allowed_users_file.
def read_allowed_users_file():
  if not os.path.exists(allowed_users_file):
    return []
  with open(allowed_users_file, 'r') as f:
    users = [line.strip() for line in f.readlines()]
  return users

# Fungsi untuk menulis file allowed_users_file.
def write_allowed_users_file(users):
  try:
    with open(allowed_users_file, 'w') as f:
      f.write('\n'.join(users) + '\n')
  except Exception as e:
    print(f"Error writing to file: {e}")

# API endpoint untuk melihat dan membuat FTP user.
@ns.route('/')
class UserList(Resource):
  @ns.doc('list_users')
  def get(self):
    '''Daftar semua pengguna'''
    users = read_allowed_users_file()
    return jsonify(users)

  @ns.doc('create_user')
  @ns.expect(user_model)
  def post(self):
    '''Buat pengguna baru'''
    data = request.json
    users = read_allowed_users_file()
    if data['username'] in users:
      return {'message': 'Pengguna sudah ada'}, 400
    users.append(data['username'])
    write_allowed_users_file(users)
    # Buat pengguna baru di ubuntu server sesuai inputan yang diberikan.
    os.system(f'sudo useradd -G sudo -m -s /bin/bash {data["username"]}')
    
    # Set password untuk pengguna baru (WAJIB).
    os.system(f'echo "{data["username"]}:{data["password"]}" | sudo chpasswd')
    
    # Buat direktori default 'ftp' di /home/$username.
    os.system(f'sudo mkdir -pm700 /home/{data["username"]}/ftp')
    
    # Ubah kepemilikan direktori tersebut menjadi user yang bersangkutan.
    os.system(f'sudo chown -R "{data["username"]}:{data["username"]}" /home/{data["username"]}/ftp')
    
    # Konfigurasi direktori 'user_conf' untuk tiap user.
    os.system(f'echo "local_root=/home/{data["username"]}/ftp" | sudo tee /etc/safetp/user_conf/{data["username"]} > /dev/null')
    
    # Set permission agar file tidak bisa dimodifikasi oleh user lain.
    os.system(f'sudo chmod 644 "/etc/safetp/user_conf/{data["username"]}"')
    return {'message': 'Pengguna dibuat'}, 201

# API endpoint untuk mengedit dan menghapus FTP user.
@ns.route('/<string:username>')
@ns.response(404, 'Pengguna tidak ditemukan')
class User(Resource):
  @ns.doc('delete_user')
  def delete(self, username):
    '''Hapus pengguna berdasarkan username'''
    users = read_allowed_users_file()
    if username not in users:
      return {'message': 'Pengguna tidak ditemukan'}, 404
    users.remove(username)
    write_allowed_users_file(users)
    # Hapus pengguna dari sistem
    os.system(f'sudo userdel -r {username}')
    return {'message': 'Pengguna dihapus'}, 200

  @ns.doc('update_user')
  @ns.expect(update_user_model)
  def put(self, username):
    '''Perbarui pengguna berdasarkan username'''
    data = request.json
    users = read_allowed_users_file()
    if username not in users:
      return {'message': 'Pengguna tidak ditemukan'}, 404
        
    new_username = data['new_username']
    new_password = data['new_password']
        
    # Check if the new username is already in use
    if new_username in users and new_username != username:
      return {'message': 'Username baru sudah ada'}, 400

    # Update the user in the allowed users file
    users.remove(username)
    users.append(new_username)
    write_allowed_users_file(users)

    # Rename the user if the username has changed
    if new_username != username:
      os.system(f'sudo usermod -l {new_username} {username}')
      os.system(f'sudo usermod -d /home/{new_username} -m {new_username}')

    # Change the user's password
    os.system(f'echo "{new_username}:{new_password}" | sudo chpasswd')

    return {'message': 'Pengguna diperbarui'}, 200

@app.route('/')
def index():
  return render_template('index.html')

app.register_blueprint(api_bp)

if __name__ == '__main__':
  app.run(debug=False, host='0.0.0.0', port=8080)