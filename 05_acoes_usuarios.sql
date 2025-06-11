-- =====================================================================
-- Arquivo: 05_acoes_usuarios.sql
-- Descrição: Contém as funções que implementam as ações disponíveis
--            para os usuários, conforme seção 3 do projeto.
-- =====================================================================

-- Ação (Admin): Cadastrar nova escuderia 
-- Justificativa: Encapsula a lógica de inserção. A criação do usuário
-- correspondente é feita automaticamente pelo trigger 'trg_cria_usuario_escuderia'.
CREATE OR REPLACE FUNCTION admin_cadastrar_escuderia(
    p_constructorref TEXT, p_name TEXT, p_nationality TEXT, p_url TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO constructors (constructorref, name, nationality, url)
    VALUES (p_constructorref, p_name, p_nationality, p_url);
END;
$$ LANGUAGE plpgsql;


-- Ação (Admin): Cadastrar novo piloto 
-- Justificativa: Encapsula a inserção na tabela 'driver'. A criação
-- do usuário é feita pelo trigger 'trg_cria_usuario_piloto'.
CREATE OR REPLACE FUNCTION admin_cadastrar_piloto(
    p_driverref TEXT, p_number INT, p_code TEXT, p_forename TEXT, p_surname TEXT, p_dob DATE, p_nationality TEXT
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO driver(driverref, number, code, forename, surname, dob, nationality)
    VALUES (p_driverref, p_number, p_code, p_forename, p_surname, p_dob, p_nationality);
END;
$$ LANGUAGE plpgsql;


-- Ação (Escuderia): Consultar piloto por 'forename' que já correu pela equipe 
-- Justificativa: A função recebe o ID da escuderia e o primeiro nome do piloto,
-- retornando os dados dos pilotos que correspondem ao critério. Usa a tabela
-- 'results' para verificar o vínculo, como sugerido.
CREATE OR REPLACE FUNCTION escuderia_consultar_piloto_por_nome(p_constructor_id INT, p_forename TEXT)
RETURNS TABLE("Nome Completo" TEXT, "Data de Nascimento" DATE, "Nacionalidade" TEXT) AS $$
BEGIN
    RETURN QUERY
        SELECT DISTINCT
            d.forename || ' ' || d.surname,
            d.dob,
            d.nationality
        FROM driver d
        JOIN results r ON d.driverid = r.driverid
        WHERE r.constructorid = p_constructor_id
          AND d.forename ILIKE p_forename;
END;
$$ LANGUAGE plpgsql;