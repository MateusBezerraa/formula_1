-- =====================================================================
-- Arquivo: 04_relatorios.sql
-- Descrição: Contém as funções e índices para os relatórios
--            especificados na seção 5 do projeto.
--            Os nomes das colunas estão em português, conforme solicitado.
-- =====================================================================

-- ========= ÍNDICES DE OTIMIZAÇÃO =========

-- Justificativa: Índice para o Relatório 2 do Admin. Acelera a busca de
-- aeroportos por tipo e país e a junção com cidades por nome, otimizando
-- o cálculo de distância entre cidades e aeroportos brasileiros.
CREATE INDEX IF NOT EXISTS idx_airports_geo ON airports (iso_country, type);
CREATE INDEX IF NOT EXISTS idx_geocities15k_name ON geocities15k (name);


-- Justificativa: Índice para o Relatório 4 das Escuderias. Acelera a busca
-- de vitórias (position=1) por construtor e piloto, otimizando a contagem.
CREATE INDEX IF NOT EXISTS idx_results_constructor_wins ON results (constructorid, driverid, position);

-- Justificativa: Índice para o Relatório 6 do Piloto. Acelera a busca de
-- resultados por piloto, facilitando a agregação de pontos por ano.
CREATE INDEX IF NOT EXISTS idx_results_driver_points ON results (driverid);


-- ========= FUNÇÕES DE RELATÓRIO =========

-- Relatório 1 (Admin): Quantidade de resultados por status 
CREATE OR REPLACE FUNCTION get_relatorio_admin_status()
RETURNS TABLE("Status" TEXT, "Quantidade" INTEGER) AS $$
BEGIN
    RETURN QUERY
        SELECT s.status, rs.contagem
        FROM results_status rs
        JOIN status s ON rs.statusid = s.statusid
        ORDER BY rs.contagem DESC;
END;
$$ LANGUAGE plpgsql;


-- Relatório 2 (Admin): Aeroportos próximos a uma cidade 
CREATE OR REPLACE FUNCTION get_relatorio_admin_aeroportos(nome_cidade TEXT)
RETURNS TABLE("Cidade da Busca" TEXT, "Código IATA" TEXT, "Nome do Aeroporto" TEXT, "Cidade do Aeroporto" TEXT, "Distância (Km)" NUMERIC, "Tipo do Aeroporto" TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        gc.name AS "Cidade da Busca",
        ap.iata_code AS "Código IATA",
        ap.name AS "Nome do Aeroporto",
        ap.municipality AS "Cidade do Aeroporto",
        -- Fórmula de Haversine para calcular distância em Km
        ROUND((6371 * ACOS(
            COS(RADIANS(gc.lat)) * COS(RADIANS(ap.latitude_deg)) *
            COS(RADIANS(ap.longitude_deg) - RADIANS(gc.long)) +
            SIN(RADIANS(gc.lat)) * SIN(RADIANS(ap.latitude_deg))
        ))::NUMERIC, 2) AS "Distancia (Km)",
        ap.type AS "Tipo do Aeroporto"
    FROM geocities15k gc
    JOIN airports ap ON 1=1
    WHERE gc.name = nome_cidade
      AND ap.iso_country = 'BR'
      AND ap.type IN ('medium_airport', 'large_airport')
      AND (6371 * ACOS(
            COS(RADIANS(gc.lat)) * COS(RADIANS(ap.latitude_deg)) *
            COS(RADIANS(ap.longitude_deg) - RADIANS(gc.long)) +
            SIN(RADIANS(gc.lat)) * SIN(RADIANS(ap.latitude_deg))
      )) <= 100 -- Filtro de distância de 100Km
    ORDER BY "Distancia (Km)";
END;
$$ LANGUAGE plpgsql;

-- Relatório 3 (Admin): Quantidade de resultados por ano
CREATE OR REPLACE FUNCTION get_relatorio_desempenho_circuitos()
RETURNS TABLE(
    "Nível" INT,
    "Descrição" TEXT,
    "Valor" TEXT
) AS $$
DECLARE
    total_corridas BIGINT;
    rec_circuito RECORD;
    rec_corrida RECORD;
    rec_detalhes_corrida RECORD;
BEGIN
    -- Nível 1: Quantidade de corridas cadastradas no total
    SELECT COUNT(*) INTO total_corridas FROM races;
    "Nível" := 1;
    "Descrição" := 'Quantidade total de corridas';
    "Valor" := total_corridas::TEXT;
    RETURN NEXT;

    -- Nível 2: Quantidade de corridas por circuito, com stats de voltas
    FOR rec_circuito IN
        SELECT
            c.circuitid,
            c.name AS nome_circuito,
            (SELECT COUNT(*) FROM races r WHERE r.circuitid = c.circuitid) AS qtde_corridas,
            (SELECT MIN(res.laps) FROM results res JOIN races r ON res.raceid = r.raceid WHERE r.circuitid = c.circuitid AND res.laps > 0) AS min_voltas,
            (SELECT ROUND(AVG(res.laps)) FROM results res JOIN races r ON res.raceid = r.raceid WHERE r.circuitid = c.circuitid AND res.laps > 0) AS media_voltas,
            (SELECT MAX(res.laps) FROM results res JOIN races r ON res.raceid = r.raceid WHERE r.circuitid = c.circuitid) AS max_voltas
        FROM circuits c
        WHERE EXISTS (SELECT 1 FROM races r WHERE r.circuitid = c.circuitid)
        ORDER BY c.name
    LOOP
        "Nível" := 2;
        "Descrição" := 'Circuito: ' || rec_circuito.nome_circuito;
        "Valor" := 'Corridas: ' || rec_circuito.qtde_corridas ||
                   ' | Voltas (Min/Média/Máx): ' || COALESCE(rec_circuito.min_voltas::TEXT, 'N/A') ||
                   '/' || COALESCE(rec_circuito.media_voltas::TEXT, 'N/A') ||
                   '/' || COALESCE(rec_circuito.max_voltas::TEXT, 'N/A');
        RETURN NEXT;

        -- Nível 3: Para cada corrida, indica a quantidade de voltas e tempo total
        FOR rec_corrida IN
            SELECT r.raceid, r.name AS nome_corrida, r.year AS ano_corrida
            FROM races r
            WHERE r.circuitid = rec_circuito.circuitid
            ORDER BY r.year, r.name
        LOOP
            -- Busca os detalhes da corrida (voltas e tempo do vencedor)
            SELECT
                MAX(res.laps) AS voltas_da_corrida,
                res.time AS tempo_total
            INTO rec_detalhes_corrida
            FROM results res
            WHERE res.raceid = rec_corrida.raceid
              AND res.position = 1 -- Considera o tempo do vencedor (posição 1)
            GROUP BY res.time;

            "Nível" := 3;
            "Descrição" := ' -> Corrida: ' || rec_corrida.nome_corrida || ' (' || rec_corrida.ano_corrida || ')';
            "Valor" := 'Voltas: ' || COALESCE(rec_detalhes_corrida.voltas_da_corrida::TEXT, 'N/A') ||
                       ' | Tempo Total: ' || COALESCE(rec_detalhes_corrida.tempo_total, 'N/A');
            RETURN NEXT;

        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Relatório 4 (Escuderia): Vitórias por piloto da escuderia 
CREATE OR REPLACE FUNCTION get_relatorio_escuderia_vitorias(p_constructor_id INT)
RETURNS TABLE("Nome do Piloto" TEXT, "Quantidade de Vitórias" BIGINT) AS $$
BEGIN
    RETURN QUERY
        SELECT
            d.forename || ' ' || d.surname as "Nome Completo",
            COUNT(r.resultid) AS "Vitorias"
        FROM results r
        JOIN driver d ON r.driverid = d.driverid
        WHERE r.constructorid = p_constructor_id AND r.position = 1
        GROUP BY d.driverid
        ORDER BY "Vitorias" DESC;
END;
$$ LANGUAGE plpgsql;

-- Relatório 5 (Escuderia): Resultados por status, no escopo da escuderia 
CREATE OR REPLACE FUNCTION get_relatorio_escuderia_status(p_constructor_id INT)
RETURNS TABLE("Status" TEXT, "Quantidade" BIGINT) AS $$
BEGIN
    RETURN QUERY
        SELECT
            s.status,
            COUNT(r.resultid) AS "Quantidade"
        FROM results r
        JOIN status s ON r.statusid = s.statusid
        WHERE r.constructorid = p_constructor_id
        GROUP BY s.statusid
        ORDER BY "Quantidade" DESC;
END;
$$ LANGUAGE plpgsql;

-- Relatório 6 (Piloto): Pontos por ano e corrida 
CREATE OR REPLACE FUNCTION get_relatorio_piloto_pontos(p_driver_id INT)
RETURNS TABLE("Ano" INT, "Corrida" TEXT, "Pontos Obtidos" REAL) AS $$
BEGIN
    RETURN QUERY
        SELECT
            ra.year,
            ra.name,
            r.points::REAL
        FROM results r
        JOIN races ra ON r.raceid = ra.raceid
        WHERE r.driverid = p_driver_id AND r.points > 0
        ORDER BY ra.year DESC, ra.date;
END;
$$ LANGUAGE plpgsql;


-- Relatório 7 (Piloto): Resultados por status, no escopo do piloto 
CREATE OR REPLACE FUNCTION get_relatorio_piloto_status(p_driver_id INT)
RETURNS TABLE("Status" TEXT, "Quantidade" BIGINT) AS $$
BEGIN
    RETURN QUERY
        SELECT
            s.status,
            COUNT(r.resultid) AS "Quantidade"
        FROM results r
        JOIN status s ON r.statusid = s.statusid
        WHERE r.driverid = p_driver_id
        GROUP BY s.statusid
        ORDER BY "Quantidade" DESC;
END;