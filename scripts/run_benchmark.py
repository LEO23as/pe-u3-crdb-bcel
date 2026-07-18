
import time
import psycopg2
import pandas as pd
import matplotlib.pyplot as plt


DSN_CLUSTER = "postgresql://root@localhost:26257/sga_dist?sslmode=disable"
DSN_SINGLE  = "postgresql://root@localhost:26260/sga_dist?sslmode=disable"

REPETICIONES = 10  

CONSULTAS = {
    "Q1 JOIN": "SELECT e.nombres, m.estado FROM estudiantes e JOIN matriculas m ON e.id_estudiante = m.id_estudiante LIMIT 100;",
    "Q2 GROUP BY": "SELECT id_ano_lectivo, estado, COUNT(*) FROM matriculas GROUP BY id_ano_lectivo, estado;",
    "Q3 Lookup PK": "SELECT * FROM estudiantes WHERE id_estudiante = 500;",
    "Q4 Rango": "SELECT COUNT(*) FROM matriculas WHERE id_ano_lectivo BETWEEN 2024 AND 2026;",
    "Q5 Subconsulta": "SELECT e.nombres FROM estudiantes e WHERE (SELECT AVG(c.nota) FROM calificaciones c JOIN matriculas m ON c.id_matricula=m.id_matricula WHERE m.id_estudiante=e.id_estudiante) > (SELECT AVG(nota) FROM calificaciones) LIMIT 50;",
}

def medir(dsn):
    conn = psycopg2.connect(dsn)
    cur = conn.cursor()
    tiempos = {}
    for nombre, sql in CONSULTAS.items():
        acum = 0.0
        for _ in range(REPETICIONES):
            t0 = time.perf_counter()
            cur.execute(sql)
            cur.fetchall()
            acum += (time.perf_counter() - t0) * 1000  # ms
        tiempos[nombre] = round(acum / REPETICIONES, 2)
    cur.close(); conn.close()
    return tiempos

def main():
    print("Midiendo en el CLÚSTER (3 nodos)...")
    t_cluster = medir(DSN_CLUSTER)
    print("Midiendo en NODO ÚNICO...")
    t_single = medir(DSN_SINGLE)

    filas = []
    for q in CONSULTAS:
        tc, tu = t_cluster[q], t_single[q]
        factor = round(tu / tc, 2) if tc > 0 else 0
        filas.append({"Consulta": q, "Cluster_ms": tc, "NodoUnico_ms": tu, "Factor_mejora": factor})

    df = pd.DataFrame(filas)
    df.to_csv("evidencia/resultados.csv", index=False)
    print(df.to_string(index=False))

   
    df.plot(x="Consulta", y=["Cluster_ms", "NodoUnico_ms"], kind="bar")
    plt.ylabel("Tiempo (ms)"); plt.title("Rendimiento: Clúster vs Nodo Único")
    plt.tight_layout(); plt.savefig("evidencia/benchmark.png")
    print("\n✅ Guardado: evidencia/resultados.csv y evidencia/benchmark.png")

if __name__ == "__main__":
    main()