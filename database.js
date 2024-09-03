const sql = require('mssql');

const config = {
    user: 'TestVision',
    password: '1234567',
    server: 'LAPTOP-IIE3LIL6', 
    database: 'biblioteca',
    options: {
        encrypt: true, 
        trustServerCertificate: true 
    }
};

async function getConnection() {
    try {
        await sql.connect(config);
        console.log('Conectado a la base de datos');
    } catch (err) {
        console.error('Error al conectar a la base de datos:', err);
    }
}

module.exports = {
    sql,
    getConnection
};
