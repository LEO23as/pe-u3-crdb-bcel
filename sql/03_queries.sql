"""
PE-U3 | Equipo BCEL | Carga de datos ficticios en el clúster CockroachDB
Inserta: 3.000 estudiantes, 200 actividades, 12.000 matrículas y ~24.000 calificaciones.
Requisitos:  pip install psycopg2-binary faker
Uso:         python scripts/seed_data.py
"""

import random
import psycopg2
from faker import Faker

fake = Faker("es_ES")

# Conexión al clúster (nodo 1, modo inseguro)
CONN_STR = "postgresql://root@localhost:26257/sga_dist?sslmode=disable"

# Años lectivos para repartir las matrículas (activa la fragmentación por rango)
ANIOS = [2022, 2023, 2024, 2025, 2026]
TIPOS_ACTIVIDAD = ["TAREA", "LECCION", "PROYECTO", "EXAMEN", "FORMATIVA", "SUMATIVA"]
ESTADOS = ["ACTIVA", "RETIRADA", "APROBADA", "REPROBADA"]

N_ESTUDIANTES = 3000
N_ACTIVIDADES = 200
N_MATRICULAS = 12000
CALIF_POR_MATRICULA = 2  # ~24.000 calificaciones


def main():
    conn = psycopg2.connect(CONN_STR)
    conn.autocommit = False
    cur = conn.cursor()
    print("Conectado al clúster CockroachDB...")

    # -------- ESTUDIANTES --------
    print("Insertando estudiantes...")
    ids_estudiantes = []
    for i in range(N_ESTUDIANTES):
        cedula = str(random.randint(1000000000, 9999999999))
        cur.execute(
            """INSERT INTO estudiantes (cedula, nombres, apellidos, fecha_nacimiento, genero, correo)
               VALUES (%s, %s, %s, %s, %s, %s) RETURNING id_estudiante""",
            (cedula, fake.first_name(), fake.last_name(),
             fake.date_of_birth(minimum_age=5, maximum_age=16),
             random.choice(["M", "F"]), fake.email()),
        )
        ids_estudiantes.append(cur.fetchone()[0])
        if i % 500 == 0:
            conn.commit()
    conn.commit()

    # -------- ACTIVIDADES --------
    print("Insertando actividades...")
    ids_actividades = []
    for _ in range(N_ACTIVIDADES):
        cur.execute(
            """INSERT INTO actividades (nombre, tipo, fecha_entrega, ponderacion, nota_maxima, es_sumativa)
               VALUES (%s, %s, %s, %s, %s, %s) RETURNING id_actividad""",
            (fake.sentence(nb_words=4), random.choice(TIPOS_ACTIVIDAD),
             fake.date_this_decade(), round(random.uniform(1, 10), 2),
             10, random.choice([True, False])),
        )
        ids_actividades.append(cur.fetchone()[0])
    conn.commit()

    # -------- MATRICULAS (tabla principal, repartida por año) --------
    print("Insertando matrículas...")
    ids_matriculas = []
    for i in range(N_MATRICULAS):
        anio = random.choice(ANIOS)
        cur.execute(
            """INSERT INTO matriculas (id_ano_lectivo, id_estudiante, id_grado, estado)
               VALUES (%s, %s, %s, %s) RETURNING id_matricula""",
            (anio, random.choice(ids_estudiantes), random.randint(1, 10),
             random.choice(ESTADOS)),
        )
        ids_matriculas.append(cur.fetchone()[0])
        if i % 1000 == 0:
            conn.commit()
            print(f"  {i} matrículas...")
    conn.commit()

    # -------- CALIFICACIONES --------
    print("Insertando calificaciones...")
    for i, id_mat in enumerate(ids_matriculas):
        for _ in range(CALIF_POR_MATRICULA):
            cur.execute(
                """INSERT INTO calificaciones (id_matricula, id_actividad, nota)
                   VALUES (%s, %s, %s)""",
                (id_mat, random.choice(ids_actividades), round(random.uniform(0, 10), 2)),
            )
        if i % 1000 == 0:
            conn.commit()
    conn.commit()

    # -------- RESUMEN --------
    cur.execute("SELECT COUNT(*) FROM matriculas")
    total = cur.fetchone()[0]
    print(f"\n✅ Listo. Total de matrículas insertadas: {total}")

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()