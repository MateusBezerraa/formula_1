-- =====================================================================
-- Arquivo: 02_gerenciamento_usuarios.sql
-- Descrição: Contém as funções e triggers para automatizar o cadastro
--            de usuários e o script para a carga inicial. Isso atende
--            aos requisitos 1.4 e 3 sobre automação.
-- =====================================================================

-- ========= TRIGGER FUNCTIONS =========

-- Justificativa: Esta função de trigger é acionada após a inserção
-- na tabela 'driver'. Ela cria um usuário correspondente na tabela 'users',
-- com o tipo 'Piloto' e o padrão de login/senha '<driverref>_d' e '<driverref>'.
-- Ela também impede a criação do piloto se o login já existir, conforme a regra.
CREATE OR REPLACE FUNCTION func_cria_usuario_piloto()
RETURNS TRIGGER AS $$
DECLARE
    v_login TEXT := NEW.driverref || '_d';
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE login = v_login) THEN
        RAISE EXCEPTION 'Login de piloto já existente: %. Operação cancelada.', v_login;
    END IF;

    INSERT INTO users (login, password, tipo, idoriginal)
    VALUES (v_login, NEW.driverref, 'Piloto', NEW.driverid);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Justificativa: Similar à anterior, mas para escuderias. Acionada após a
-- inserção em 'constructors', cria um usuário do tipo 'Escuderia' com
-- login/senha no padrão '<constructorref>_c' e '<constructorref>'.
CREATE OR REPLACE FUNCTION func_cria_usuario_escuderia()
RETURNS TRIGGER AS $$
DECLARE
    v_login TEXT := NEW.constructorref || '_c';
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE login = v_login) THEN
        RAISE EXCEPTION 'Login de escuderia já existente: %. Operação cancelada.', v_login;
    END IF;

    INSERT INTO users (login, password, tipo, idoriginal)
    VALUES (v_login, NEW.constructorref, 'Escuderia', NEW.constructorid);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ========= TRIGGERS =========
DROP TRIGGER IF EXISTS trg_cria_usuario_piloto ON driver;
CREATE TRIGGER trg_cria_usuario_piloto
AFTER INSERT ON driver
FOR EACH ROW
EXECUTE FUNCTION func_cria_usuario_piloto();

DROP TRIGGER IF EXISTS trg_cria_usuario_escuderia ON constructors;
CREATE TRIGGER trg_cria_usuario_escuderia
AFTER INSERT ON constructors
FOR EACH ROW
EXECUTE FUNCTION func_cria_usuario_escuderia();


-- ========= CARGA INICIAL DE USUÁRIOS =========
-- Justificativa: Este bloco realiza a carga inicial dos usuários
-- com base nos dados já existentes, um requisito para que o sistema
-- funcione desde o início com todos os pilotos e escuderias.

DO $$
BEGIN
    -- 1. Inserir usuário Administrador
    IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'admin') THEN
        INSERT INTO users (login, password, tipo) VALUES ('admin', 'admin', 'Administrador'); -- 
    END IF;

    -- 2. Inserir usuários para todos os Pilotos existentes
    INSERT INTO users (login, password, tipo, idoriginal)
    SELECT
        d.driverref || '_d',
        d.driverref,
        'Piloto',
        d.driverid
    FROM driver d
    ON CONFLICT (login) DO NOTHING; -- Evita erro se o usuário já existir

    -- 3. Inserir usuários para todas as Escuderias existentes
    INSERT INTO users (login, password, tipo, idoriginal)
    SELECT
        c.constructorref || '_c',
        c.constructorref,
        'Escuderia',
        c.constructorid
    FROM constructors c
    ON CONFLICT (login) DO NOTHING; -- Evita erro se o usuário já existir
END;
$$;