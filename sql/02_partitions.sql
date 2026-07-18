-- ============================================================
-- PE-U3 | Fragmentación horizontal de "matriculas" por año lectivo
-- Estrategia: PARTITION BY RANGE (id_ano_lectivo)
-- Álgebra relacional:  matriculas_i = σ (a_i <= id_ano_lectivo < a_{i+1}) (matriculas)
-- ============================================================
USE sga_dist;

ALTER TABLE matriculas PARTITION BY RANGE (id_ano_lectivo) (
    PARTITION p_hasta_2023 VALUES FROM (MINVALUE) TO (2024),
    PARTITION p_2024       VALUES FROM (2024)     TO (2025),
    PARTITION p_2025       VALUES FROM (2025)     TO (2026),
    PARTITION p_2026       VALUES FROM (2026)     TO (MAXVALUE)
);

-- Verificar la distribución de rangos entre los nodos (para la tabla booktabs del informe)
SHOW RANGES FROM TABLE matriculas;

-- Ver las particiones aplicadas
SHOW PARTITIONS FROM TABLE matriculas;