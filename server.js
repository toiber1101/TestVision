const express = require('express');
const path = require('path');
const bodyParser = require('body-parser');
const { sql, getConnection } = require('./database');

const app = express();
const port = 3000;

app.use(bodyParser.json());

// Servir archivos estáticos desde la raíz del proyecto
app.use(express.static(path.join(__dirname, '/')));

getConnection();

// Ruta para servir el archivo index.html
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Ruta para obtener los usuarios
app.get('/api/usuarios', async (req, res) => {
    try {
        const result = await sql.query`SELECT id_usuario, nombre FROM usuarios`;
        res.json(result.recordset);
    } catch (err) {
        res.status(500).send('Error al obtener los usuarios');
    }
});

// Ruta para obtener préstamos por usuario
app.get('/api/prestamos/:id_usuario', async (req, res) => {
    const id_usuario = req.params.id_usuario;
    try {
        const result = await sql.query`
            SELECT l.titulo, l.autor, p.fecha_devolucion 
            FROM prestamos p 
            JOIN libros l ON p.id_libro = l.id_libro 
            WHERE p.id_usuario = ${id_usuario} AND p.estado = '1'`;
        res.json(result.recordset);
    } catch (err) {
        res.status(500).send('Error al obtener los préstamos');
    }
});

// Ruta para registrar un nuevo préstamo
app.post('/api/prestamos', async (req, res) => {
    const { id_usuario, id_libro } = req.body;
    const transaction = new sql.Transaction();

    try {
        await transaction.begin();
        const request = new sql.Request(transaction);

        // Registrar el préstamo
        await request.query`
            INSERT INTO prestamos (id_usuario, id_libro, estado)
            VALUES (${id_usuario}, ${id_libro}, '1')`;

        // Actualizar la cantidad disponible del libro
        await request.query`
            UPDATE libros 
            SET cantidad_disponible = cantidad_disponible - 1 
            WHERE id_libro = ${id_libro}`;

        // Verificar si la cantidad disponible es negativa
        const result = await request.query`
            SELECT cantidad_disponible 
            FROM libros 
            WHERE id_libro = ${id_libro}`;

        if (result.recordset[0].cantidad_disponible < 0) {
            throw new Error('La cantidad disponible no puede ser negativa');
        }

        await transaction.commit();
        res.json({ message: 'Préstamo registrado exitosamente' });
    } catch (err) {
        await transaction.rollback();
        res.status(500).send(`Error al registrar el préstamo: ${err.message}`);
    }
});

app.listen(port, () => {
    console.log(`Servidor escuchando en http://localhost:${port}`);
});
