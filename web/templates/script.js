document.addEventListener('DOMContentLoaded', () => {
    const tambahButton = document.getElementById('tambah');
    const kurangButton = document.getElementById('kurang');
    const submitButton = document.getElementById('submit');
    const userListTableBody = document.querySelector('#user-list tbody');
    let userId = 1;

    tambahButton.addEventListener('click', () => {
        const newInput = document.createElement('input');
        newInput.type = 'text';
        newInput.className = 'form-control form-control-lg bg-light fs-6 mt-3';
        newInput.placeholder = 'input user';
        document.querySelector('.right-box .row').insertBefore(newInput, tambahButton.parentElement.parentElement);
        kurangButton.disabled = false;
    });

    kurangButton.addEventListener('click', () => {
        const inputs = document.querySelectorAll('.right-box .row input');
        if (inputs.length > 1) {
            inputs[inputs.length - 1].remove();
        }
        if (inputs.length <= 2) {
            kurangButton.disabled = true;
        }
    });

    submitButton.addEventListener('click', (e) => {
        e.preventDefault();
        const inputs = document.querySelectorAll('.right-box .row input');
        inputs.forEach(input => {
            if (input.value.trim() !== '') {
                addUserToTable(userId, input.value);
                input.value = '';
                userId++;
            }
        });
    });

    // Load user list from backend (for example purpose, hardcoded users)
    const users = ['User1', 'User2', 'User3', 'User4', 'User5', 'User6']; // This should be fetched from the backend
    users.forEach(user => {
        addUserToTable(userId, user);
        userId++;
    });

    function addUserToTable(id, userName) {
        const row = document.createElement('tr');
        row.innerHTML = `
            <th scope="row">${id}</th>
            <td>${userName}</td>
            <td>
                <button class="btn btn-warning btn-sm me-2" onclick="editUser(this)" data-bs-toggle="modal" data-bs-target="#editUserModal">Edit</button>
                <button class="btn btn-danger btn-sm" onclick="deleteUser(this)">Delete</button>
            </td>
        `;
        userListTableBody.appendChild(row);
    }
});

function editUser(button) {
    const row = button.parentNode.parentNode;
    const userName = row.cells[1].textContent;
    document.getElementById('edit-user-name').value = userName;

    const form = document.getElementById('edit-user-form');
    form.onsubmit = function(event) {
        event.preventDefault();
        const newName = document.getElementById('edit-user-name').value;
        if (newName.trim() !== '') {
            row.cells[1].textContent = newName;
            const modal = bootstrap.Modal.getInstance(document.getElementById('editUserModal'));
            modal.hide();
        }
    };
}

function deleteUser(button) {
    const row = button.parentNode.parentNode;
    row.remove();
}
