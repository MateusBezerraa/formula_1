CREATE OR REPLACE FUNCTION criar_usuario_escuderia()
RETURNS TRIGGER AS $$
BEGIN
    -- Aqui verifica se já existe um usuário com o mesmo login
    IF EXISTS (SELECT 1 FROM users WHERE login = NEW.constructorref) THEN
        RAISE EXCEPTION 'Login já existe. Cadastro cancelado.';
    END IF;

    -- Inserimos o novo user
    INSERT INTO users (login, senha, tipo, idoriginal)
    VALUES (NEW.constructorref, '123456', 'Escuderia', NEW.constructorid);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_criar_usuario_escuderia
AFTER INSERT ON constructors
FOR EACH ROW
EXECUTE FUNCTION criar_usuario_escuderia();
