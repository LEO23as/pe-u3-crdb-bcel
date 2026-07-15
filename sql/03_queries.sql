
USE sga_dist;

-- Q1: JOIN entre dos tablas (estudiantes + matriculas)
SELECT e.nombres, e.apellidos, m.id_ano_lectivo, m.estado
FROM estudiantes e
JOIN matriculas m ON e.id_estudiante = m.id_estudiante
LIMIT 100;

-- Q2: Agregación con GROUP BY (matrículas por año y estado)
SELECT id_ano_lectivo, estado, COUNT(*) AS total
FROM matriculas
GROUP BY id_ano_lectivo, estado
ORDER BY id_ano_lectivo, estado;

-- Q3: Búsqueda puntual por clave (lookup)
SELECT * FROM estudiantes WHERE id_estudiante = 500;

-- Q4: Consulta de rango con WHERE
SELECT COUNT(*) FROM matriculas WHERE id_ano_lectivo BETWEEN 2024 AND 2026;

-- Q5: Subconsulta correlacionada (estudiantes por encima del promedio general)
SELECT e.nombres, e.apellidos
FROM estudiantes e
WHERE (
    SELECT AVG(c.nota) FROM calificaciones c
    JOIN matriculas m ON c.id_matricula = m.id_matricula
    WHERE m.id_estudiante = e.id_estudiante
) > (SELECT AVG(nota) FROM calificaciones)
LIMIT 50;