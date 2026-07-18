-- ============================================================
-- PE-U3 | Equipo BCEL | Esquema SGA para clúster CockroachDB
-- Modelo: estudiantes --< matriculas --< calificaciones >-- actividades
-- Tabla principal: matriculas (fragmentada por id_ano_lectivo)
-- ============================================================

CREATE DATABASE IF NOT EXISTS sga_dist;
USE sga_dist;

-- ---------- 1. ESTUDIANTES ----------
CREATE TABLE estudiantes (
    id_estudiante    INT8        NOT NULL DEFAULT unique_rowid(),
    cedula           STRING(10)  NOT NULL,
    nombres          STRING(100) NOT NULL,
    apellidos        STRING(100) NOT NULL,
    fecha_nacimiento DATE        NOT NULL,
    genero           STRING(1)   NOT NULL DEFAULT 'M',
    correo           STRING(150),
    fecha_creacion   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT pk_estudiantes PRIMARY KEY (id_estudiante),
    CONSTRAINT uq_estudiantes_cedula UNIQUE (cedula),
    CONSTRAINT ck_estudiantes_genero CHECK (genero IN ('M','F'))
);

-- ---------- 2. ACTIVIDADES ----------
CREATE TABLE actividades (
    id_actividad  INT8         NOT NULL DEFAULT unique_rowid(),
    nombre        STRING(200)  NOT NULL,
    tipo          STRING(20)   NOT NULL DEFAULT 'TAREA',
    fecha_entrega DATE         NOT NULL,
    ponderacion   DECIMAL(5,2) NOT NULL DEFAULT 0,
    nota_maxima   DECIMAL(4,2) NOT NULL DEFAULT 10,
    es_sumativa   BOOL         NOT NULL DEFAULT false,
    CONSTRAINT pk_actividades PRIMARY KEY (id_actividad),
    CONSTRAINT ck_actividades_tipo CHECK (tipo IN ('TAREA','LECCION','PROYECTO','EXAMEN','FORMATIVA','SUMATIVA')),
    CONSTRAINT ck_actividades_nota CHECK (nota_maxima > 0)
);

-- ---------- 3. MATRICULAS (tabla principal, PK compuesta para poder particionar) ----------
CREATE TABLE matriculas (
    id_ano_lectivo  INT8       NOT NULL,
    id_matricula    INT8       NOT NULL DEFAULT unique_rowid(),
    id_estudiante   INT8       NOT NULL,
    id_grado        INT8       NOT NULL,
    estado          STRING(15) NOT NULL DEFAULT 'ACTIVA',
    fecha_matricula DATE       NOT NULL DEFAULT current_date(),
    CONSTRAINT pk_matriculas PRIMARY KEY (id_ano_lectivo, id_matricula),
    CONSTRAINT uq_matriculas_id UNIQUE (id_matricula),
    CONSTRAINT fk_matriculas_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id_estudiante),
    CONSTRAINT ck_matriculas_estado CHECK (estado IN ('ACTIVA','RETIRADA','APROBADA','REPROBADA')),
    CONSTRAINT ck_matriculas_ano CHECK (id_ano_lectivo BETWEEN 2000 AND 2100)
);

-- ---------- 4. CALIFICACIONES (relaciona matriculas y actividades) ----------
CREATE TABLE calificaciones (
    id_calificacion INT8         NOT NULL DEFAULT unique_rowid(),
    id_matricula    INT8         NOT NULL,
    id_actividad    INT8         NOT NULL,
    nota            DECIMAL(4,2) NOT NULL,
    fecha_registro  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_calificaciones PRIMARY KEY (id_calificacion),
    CONSTRAINT fk_calif_matricula FOREIGN KEY (id_matricula) REFERENCES matriculas (id_matricula),
    CONSTRAINT fk_calif_actividad FOREIGN KEY (id_actividad) REFERENCES actividades (id_actividad),
    CONSTRAINT ck_calif_nota CHECK (nota >= 0 AND nota <= 10)
);