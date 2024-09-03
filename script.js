document.addEventListener('DOMContentLoaded', function() {
    const userSelect = document.getElementById('user-select');
    const loansTableBody = document.querySelector('#loans-table tbody');
    const loanForm = document.getElementById('loan-form');

    // Cargar usuarios al seleccionar
    fetch('/api/usuarios')
        .then(response => response.json())
        .then(users => {
            users.forEach(user => {
                const option = document.createElement('option');
                option.value = user.id_usuario;
                option.textContent = user.nombre;
                userSelect.appendChild(option);
            });
        });

    // Cargar préstamos cuando se selecciona un usuario
    userSelect.addEventListener('change', function() {
        const userId = userSelect.value;
        loansTableBody.innerHTML = ''; // Limpiar tabla

        fetch(`/api/prestamos/${userId}`)
            .then(response => response.json())
            .then(loans => {
                loans.forEach(loan => {
                    const row = document.createElement('tr');
                    row.innerHTML = `
                        <td>${loan.titulo}</td>
                        <td>${loan.autor}</td>
                        <td>${loan.fecha_devolucion || 'No devuelto'}</td>
                    `;
                    loansTableBody.appendChild(row);
                });
            });
    });

    // Registrar nuevo préstamo
    loanForm.addEventListener('submit', function(e) {
        e.preventDefault();

        const userId = document.getElementById('user-id').value;
        const bookId = document.getElementById('book-id').value;

        fetch('/api/prestamos', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ id_usuario: userId, id_libro: bookId })
        })
        .then(response => response.json())
        .then(data => {
            alert(data.message);
            userSelect.dispatchEvent(new Event('change')); // Refrescar lista de préstamos
        })
        .catch(error => console.error('Error:', error));
    });
});
