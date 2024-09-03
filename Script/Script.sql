-- Crear la base de datos
CREATE DATABASE biblioteca;
GO

-- Seleccionar la base de datos para su uso
USE biblioteca;
GO

-- Crear la tabla usuarios
CREATE TABLE usuarios (
    id_usuario INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL,
    correo NVARCHAR(100) NOT NULL UNIQUE,
    fecha_registro DATE NOT NULL DEFAULT GETDATE()
);
GO

-- Crear la tabla libros
-- Crear la tabla libros con el campo ISBN incluido
CREATE TABLE libros (
    id_libro INT PRIMARY KEY IDENTITY(1,1),
    isbn NVARCHAR(13) NOT NULL UNIQUE,
    titulo NVARCHAR(200) NOT NULL,
    autor NVARCHAR(100) NOT NULL,
    fecha_publicacion DATE NOT NULL,
    cantidad_disponible INT NOT NULL CHECK (cantidad_disponible >= 0)
);
GO

GO

-- Crear la tabla prestamos
CREATE TABLE prestamos (
    id_prestamo INT PRIMARY KEY IDENTITY(1,1),
    id_usuario INT FOREIGN KEY REFERENCES usuarios(id_usuario),
    id_libro INT FOREIGN KEY REFERENCES libros(id_libro),
    fecha_prestamo DATE NOT NULL DEFAULT GETDATE(),
    fecha_devolucion DATE,    
	estado smallint
);
GO

---------------------------inserts

-- Insertar registros en la tabla usuarios
INSERT INTO usuarios (nombre, correo, fecha_registro)
VALUES 
('Juan Pérez', 'juan.perez@mail.com', '2024-01-15'),
('María López', 'maria.lopez@mail.com', '2024-02-20'),
('Carlos García', 'carlos.garcia@mail.com', '2024-03-10'),
('Ana Torres', 'ana.torres@mail.com', '2024-04-05'),
('Luis Martínez', 'luis.martinez@mail.com', '2024-05-12');
GO

-- Insertar registros en la tabla libros con el campo ISBN
INSERT INTO libros (isbn, titulo, autor, fecha_publicacion, cantidad_disponible)
VALUES
('9780060883287', 'Cien Años de Soledad', 'Gabriel García Márquez', '1967-05-30', 5),
('9788491050209', 'Don Quijote de la Mancha', 'Miguel de Cervantes', '1605-01-16', 3),
('9788408170041', 'La Sombra del Viento', 'Carlos Ruiz Zafón', '2001-04-17', 4),
('9780307389732', 'El Amor en los Tiempos del Cólera', 'Gabriel García Márquez', '1985-03-06', 2),
('9780451524935', '1984', 'George Orwell', '1949-06-08', 6),
('9780140449136', 'Crimen y Castigo', 'Fyodor Dostoevsky', '1866-12-01', 3),
('9780156012195', 'El Principito', 'Antoine de Saint-Exupéry', '1943-04-06', 7),
('9780544003415', 'El Señor de los Anillos', 'J.R.R. Tolkien', '1954-07-29', 4),
('9780061120084', 'Matar a un Ruiseñor', 'Harper Lee', '1960-07-11', 5),
('9780140187194', 'La Metamorfosis', 'Franz Kafka', '1915-10-15', 3);
GO
-------------consultas
-- Consulta para mostrar todos los usuarios que tienen actualmente libros prestados junto con la información de los libros
SELECT u.nombre, u.correo, l.titulo, l.autor
FROM usuarios u
JOIN prestamos p ON u.id_usuario = p.id_usuario
JOIN libros l ON p.id_libro = l.id_libro
WHERE p.estado = '0';
GO
----------vista

-- Crear una vista para mostrar todos los préstamos actuales y la cantidad de libros que tiene cada usuario
CREATE VIEW vista_prestamos_activos AS
SELECT 
    u.nombre,
    COUNT(p.id_libro) AS cantidad_libros_prestados
FROM 
    usuarios u
JOIN 
    prestamos p ON u.id_usuario = p.id_usuario
WHERE 
    p.estado = '0'
GROUP BY 
    u.nombre;
GO

--------consulta 
-- Consulta para listar los usuarios que han prestado la mayor cantidad de libros utilizando DENSE_RANK
WITH PrestamosPorUsuario AS (
    SELECT 
        u.nombre,
        COUNT(p.id_libro) AS total_libros_prestados
    FROM 
        usuarios u
    JOIN 
        prestamos p ON u.id_usuario = p.id_usuario
    GROUP BY 
        u.nombre
)
SELECT 
    nombre, 
    total_libros_prestados,
    DENSE_RANK() OVER (ORDER BY total_libros_prestados DESC) AS rank_prestamos
FROM 
    PrestamosPorUsuario;
GO



------storeprocedure


-- Implementación de una transacción que registra un nuevo préstamo y actualiza la cantidad de libros disponibles
BEGIN TRANSACTION;

BEGIN TRY
    -- Paso 1: Registrar un nuevo préstamo
    DECLARE @id_usuario INT = 1;  -- Ajusta según sea necesario
    DECLARE @id_libro INT = 3;  -- Ajusta según sea necesario
    DECLARE @fecha_prestamo DATE = GETDATE();
    
    INSERT INTO prestamos (id_usuario, id_libro, fecha_prestamo, estado)
    VALUES (@id_usuario, @id_libro, @fecha_prestamo, 'Prestado');
    
    -- Paso 2: Actualizar la cantidad disponible del libro
    UPDATE libros
    SET cantidad_disponible = cantidad_disponible - 1
    WHERE id_libro = @id_libro;
    
    -- Paso 3: Verificar si la cantidad disponible es negativa
    IF (SELECT cantidad_disponible FROM libros WHERE id_libro = @id_libro) < 0
    BEGIN
        THROW 50000, 'La cantidad disponible no puede ser negativa. Se deshacen los cambios.', 1;
    END

    -- Si todo está bien, confirmar la transacción
    COMMIT TRANSACTION;
    PRINT 'Transacción completada con éxito.';
    
END TRY
BEGIN CATCH
    -- En caso de error, deshacer la transacción
    ROLLBACK TRANSACTION;
    PRINT 'Transacción fallida. Se ha deshecho la operación.';
    PRINT ERROR_MESSAGE();
END CATCH;
GO



