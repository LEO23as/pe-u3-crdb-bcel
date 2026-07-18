# PE-U3 — Clúster de Base de Datos Distribuida con CockroachDB

**Asignatura:** Aplicaciones Distribuidas (ISR-701) — Unidad 3: Bases de Datos Distribuidas
**Código de actividad:** GA-SUM-03 / PE-U3
**Período académico:** 2026–2027 PPA — UTEQ, Facultad de Ciencias de la Computación
**Docente responsable:** Gleiston C. Guerrero-Ulloa, M.Sc.

## PFC de referencia

**BCEL – SGA Escuela de Educación Básica "Provincias Unidas"** (sistema de gestión académica).

El equipo selecciona el PFC BCEL como dominio de referencia. Este sistema es idóneo para
ejercitar fragmentación y replicación en un clúster de tres nodos por tres razones. Primero,
sus datos crecen de forma natural por año lectivo, lo que ofrece una clave de partición
horizontal clara (`id_ano_lectivo`) sobre la tabla principal de matrículas. Segundo, la
institución opera en una zona rural con conectividad inestable, por lo que la tolerancia a
fallos y la replicación automática de CockroachDB aportan un valor directo al dominio. Tercero,
el volumen de matrículas, calificaciones y actividades justifica distribuir la carga entre
varios nodos para mejorar disponibilidad y rendimiento de lectura, demostrando así las ventajas
de una base de datos distribuida frente a una centralizada.

## Integrantes y responsabilidades

| Integrante | Rama de trabajo | Responsabilidad general |
|---|---|---|
| Bedón Viteri Keyla Betzabé | `Bedon-Keyla` | Rendimiento y consistencia (Teoría 5.4) |
| Castro López Pedro Leonardo | `Castro-Pedro` | Esquema, datos y fragmentación (Teoría 5.2) |
| Emanuel Pino Juliana Romina | `Pino-Juliana` | Tolerancia a fallos y consenso (Teoría 5.3) |
| Vinueza Sánchez Harold Nicolás | `Vinueza-Harold` | Clúster CockroachDB e infraestructura (Teoría 5.1) |



### Detalle por integrante

**Bedón Viteri Keyla Betzabé — Rendimiento y análisis comparativo**
- 5 consultas SQL representativas del dominio SGA (JOIN, GROUP BY, clave primaria, rango, subconsulta correlacionada).
- Ejecución con `EXPLAIN ANALYZE` en el clúster de 3 nodos y en instancia de nodo único.
- Tabla comparativa de tiempos y factor de mejora (`tiempo_nodo_unico / tiempo_cluster`).
- Redacción de la Teoría 5.4: CAP, PACELC, consistencia eventual vs. fuerte, comparación CockroachDB vs. MongoDB vs. Cassandra.
- Entrega: `sql/03_consultas_benchmark.sql`, `scripts/medir_rendimiento.py`, `evidencia/rendimiento/`.

**Castro López Pedro Leonardo — Esquema, datos y fragmentación**
- Esquema reducido a partir de `sga-principal` (estudiantes, matrículas) y `microservicio-docente` (actividades, calificaciones), sin copiar el dump completo de Supabase.
- Tablas: `estudiantes`, `matriculas`, `actividades`, `calificaciones`, con PK, FK e índices.
- Carga de datos ficticios con Faker (≥12.000 registros totales, mínimo 10.000 en `matriculas`).
- Fragmentación horizontal de `matriculas` por año lectivo con `PARTITION BY RANGE (id_ano_lectivo)`.
- Redacción de la Teoría 5.2: completitud, reconstrucción, disyunción, fragmentación horizontal/vertical/mixta, álgebra relacional, replicación síncrona/asíncrona.
- Entrega: `sql/01_schema.sql`, `sql/02_partitions.sql`, `scripts/seed_data.py`, `evidencia/esquema/`.

**Emanuel Pino Juliana Romina — Tolerancia a fallos y consenso**
- Prueba de caída del nodo 2: consulta base → `docker stop crdb-node2` → misma consulta (debe responder por quórum 2/3) → `SHOW RANGES` antes/después → `docker start crdb-node2` → tiempo de reintegración.
- Video continuo de 2 a 5 minutos con toda la prueba (obligatorio; si falta, el criterio queda en 0).
- Diagrama de secuencia UML propio del comportamiento de Raft ante la caída del nodo.
- Redacción de la Teoría 5.3: problemas de concurrencia, 2PL/S2PL, detección de deadlocks (wait-for graphs), 2PC/3PC, y cómo Raft garantiza consistencia (líder, log replicado, quórum).
- Entrega: `evidencia/tolerancia-fallos/`, diagrama en `docs/diagramas/raft_fallo_nodo.tex`.

**Vinueza Sánchez Harold Nicolás — Clúster e infraestructura**
- `docker-compose.yml`: 3 nodos CockroachDB (`crdb-node1/2/3`), red `roach-net` (bridge), puertos 26257/8080, 26258/8081, 26259/8082, `mem_limit: 512m`, healthcheck y volúmenes persistentes.
- Inicialización (`cockroach init --insecure`) y verificación de los 3 nodos en `is_live=true`.
- Evidencia del dashboard (`http://localhost:8080`) y salida de `node status`.
- README del repositorio.
- Redacción de la Teoría 5.1: definición formal de BDD/SGBD-D, 12 objetivos de Date, arquitecturas (cliente-servidor, colaborativa, middleware), las ocho transparencias, sistemas homogéneos vs. heterogéneos — conectado al dominio SGA.
- Entrega: `docker-compose.yml`, `README.md`, `evidencia/dashboard.png`, `evidencia/node_status.txt`.

Cada integrante, además de su parte técnica y teórica, responde **una pregunta de análisis** del anexo de la guía y redacta su **conclusión individual** (≥150 palabras) para el informe final.

## Requisitos previos

- Docker Desktop 4.x con Docker Compose
- Python 3.10+ (`pip install psycopg2-binary faker pandas matplotlib --break-system-packages` si aplica)
- Git
- TeX Live / Overleaf con Biber, para compilar el informe LaTeX

## Cómo reproducir el experimento (≤ 15 minutos)

```bash
git clone https://github.com/LEO23as/pe-u3-crdb-bcel.git
cd pe-u3-crdb-bcel

docker compose up -d
docker exec -it crdb-node1 cockroach init --insecure
docker exec -it crdb-node1 cockroach node status --insecure

docker exec -it crdb-node1 cockroach sql --insecure < sql/01_schema.sql
python scripts/seed_data.py
docker exec -it crdb-node1 cockroach sql --insecure < sql/02_partitions.sql
```

Dashboard disponible en `http://localhost:8080`.

## Estructura del repositorio

```
pe-u3-crdb-bcel/
├── docker-compose.yml
├── sql/
│   ├── 01_schema.sql
│   ├── 02_partitions.sql
│   └── 03_consultas_benchmark.sql
├── scripts/
│   ├── seed_data.py
│   └── medir_rendimiento.py
├── docs/
│   ├── PE_U3_Informe.tex
│   ├── PE_U3_Informe.pdf
│   ├── references.bib
│   └── diagramas/
│       └── raft_fallo_nodo.tex
├── evidencia/
│   ├── dashboard.png
│   ├── node_status.txt
│   ├── esquema/
│   ├── tolerancia-fallos/
│   │   └── video_tolerancia.mp4
│   └── rendimiento/
├── LICENSE
└── README.md
```

## Checklist de entrega (piso de la rúbrica)

- [ ] PDF de 1 página subido al LMS con URL del repo en una sola línea
- [ ] Declaración de uso de IA generativa al final de `PE_U3_Informe.tex`
- [ ] Portada del informe con PFC declarado y justificación (≥100 palabras)
- [ ] Video de tolerancia a fallos (2–5 minutos) en `evidencia/tolerancia-fallos/`
- [ ] Conclusión individual de cada integrante (≥150 palabras)
- [ ] ≥3 commits por integrante, en fechas distintas
- [ ] Documento compila limpio con `pdflatex` + `biber`, ≥12 páginas de contenido
- [ ] Bibliografía en formato IEEE, ≥8 referencias, ≥6 con DOI/ISBN verificable