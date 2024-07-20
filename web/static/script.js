document.addEventListener('DOMContentLoaded', function() {
  loadUsers();
});

function loadUsers() {
  fetch('/api/v1/users/')
      .then(response => response.json())
      .then(users => {
          const userTableBody = document.getElementById('user-table-body');
          userTableBody.innerHTML = '';
          users.forEach((user, index) => {
              const row = document.createElement('tr');
              row.innerHTML = `
                  <th scope="row">${index + 1}</th>
                  <td>${user}</td>
                  <td>
                      <button class="btn btn-warning btn-sm" onclick="editUser('${user}')">Edit</button>
                      <button class="btn btn-danger btn-sm" onclick="deleteUser('${user}')">Hapus</button>
                  </td>
              `;
              userTableBody.appendChild(row);
          });
      });
}

function addUser() {
  const username = document.getElementById('username-input').value;
  const password = document.getElementById('password-input').value;

  if (!username || !password) {
      alert('Username dan password harus diisi!');
      return;
  }

  fetch('/api/v1/users/', {
      method: 'POST',
      headers: {
          'Content-Type': 'application/json'
      },
      body: JSON.stringify({ username, password })
  })
  .then(response => response.json())
  .then(data => {
      if (data.message) {
          alert(data.message);
      }
      loadUsers();
  })
  .catch(error => console.error('Error:', error));
}

function editUser(username) {
  document.getElementById('edit-username-input').value = username;
  document.getElementById('editUserModal').dataset.username = username;
  const modal = new bootstrap.Modal(document.getElementById('editUserModal'));
  modal.show();
}

function updateUser(event) {
  event.preventDefault();
  const oldUsername = document.getElementById('editUserModal').dataset.username;
  const newUsername = document.getElementById('edit-username-input').value;
  const newPassword = document.getElementById('edit-password-input').value;

  fetch(`/api/v1/users/${oldUsername}`, {
      method: 'PUT',
      headers: {
          'Content-Type': 'application/json'
      },
      body: JSON.stringify({ new_username: newUsername, new_password: newPassword })
  })
  .then(response => response.json())
  .then(data => {
      if (data.message) {
          alert(data.message);
      }
      loadUsers();
      const modal = bootstrap.Modal.getInstance(document.getElementById('editUserModal'));
      modal.hide();
  })
  .catch(error => console.error('Error:', error));
}

function deleteUser(username) {
  fetch(`/api/v1/users/${username}`, {
      method: 'DELETE'
  })
  .then(response => response.json())
  .then(data => {
      if (data.message) {
          alert(data.message);
      }
      loadUsers();
  })
  .catch(error => console.error('Error:', error));
}
