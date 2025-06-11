-- =====================================================================
-- Arquivo: 03_dashboards.sql
-- Descrição: Contém as funções para gerar os dados dos dashboards,
--            conforme a seção 4 do projeto. Cada função é
--            otimizada para retornar os dados específicos de cada perfil.
-- =====================================================================

-- Justificativa: Função para o dashboard do Admin. Retorna as contagens
-- totais de pilotos, escuderias e temporadas.
CREATE OR REPLACE FUNCTION get_dashboard_admin_counts()
RETURNS TABLE("Total de Pilotos" BIGINT, "Total de Escuderias" BIGINT, "Total de Temporadas" BIGINT) AS $$
BEGIN
    RETURN QUERY
        SELECT
            (SELECT COUNT(*) FROM driver),
            (SELECT COUNT(*) FROM constructors),
            (SELECT COUNT(*) FROM seasons);
END;
$$ LANGUAGE plpgsql;

-- Justificativa: Função para o dashboard da Escuderia. Recebe o ID do
-- construtor e retorna a quantidade de vitórias, pilotos distintos
-- e o primeiro/último ano de atividade, usando a tabela RESULTS.
CREATE OR REPLACE FUNCTION get_dashboard_escuderia(p_constructor_id INT)
RETURNS TABLE("Quantidade de Vitórias" BIGINT, "Quantidade de Pilotos" BIGINT, "Primeiro Ano" INT, "Último Ano" INT) AS $$
BEGIN
    RETURN QUERY
        SELECT
            (SELECT COUNT(*) FROM results WHERE constructorid = p_constructor_id AND position = 1) AS vitorias,
            (SELECT COUNT(DISTINCT driverid) FROM results WHERE constructorid = p_constructor_id) AS pilotos,
            MIN(ra.year)::INT AS primeiro_ano,
            MAX(ra.year)::INT AS ultimo_ano
        FROM results r
        JOIN races ra ON r.raceid = ra.raceid
        WHERE r.constructorid = p_constructor_id;
END;
$$ LANGUAGE plpgsql;


-- Justificativa: Função para o dashboard do Piloto. Retorna o primeiro
-- e último ano de atividade do piloto na F1.
CREATE OR REPLACE FUNCTION get_dashboard_piloto_anos(p_driver_id INT)
RETURNS TABLE("Primeiro Ano" INT, "Último Ano" INT) AS $$
BEGIN
    RETURN QUERY
        SELECT MIN(ra.year)::INT, MAX(ra.year)::INT
        FROM results r
        JOIN races ra ON r.raceid = ra.raceid
        WHERE r.driverid = p_driver_id;
END;
$$ LANGUAGE plpgsql;


-- Justificativa: Função complementar para o dashboard do Piloto,
-- retornando um resumo de seu desempenho por ano e circuito.
CREATE OR REPLACE FUNCTION get_dashboard_piloto_desempenho(p_driver_id INT)
RETURNS TABLE("Ano" INT, "Circuito" TEXT, "Pontos Obtidos" DOUBLE PRECISION, "Vitórias" BIGINT, "Corridas Disputadas" BIGINT) AS $$
BEGIN
    RETURN QUERY
        SELECT
            ra.year,
            c.name,
            SUM(r.points) AS "Pontos",
            COUNT(*) FILTER (WHERE r.position = 1) AS "Vitorias",
            COUNT(r.resultid) AS "Corridas"
        FROM results r
        JOIN races ra ON r.raceid = ra.raceid
        JOIN circuits c ON ra.circuitid = c.circuitid
        WHERE r.driverid = p_driver_id
        GROUP BY ra.year, c.name
        ORDER BY ra.year DESC, c.name;
END;
$$ LANGUAGE plpgsql;