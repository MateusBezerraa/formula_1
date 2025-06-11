-- =====================================================================
-- Arquivo: 01_schema_usuarios.sql
-- Descrição: Cria as tabelas USERS e USERS_LOG para o controle de
--            autenticação e auditoria de acesso, conforme especificado
--            nos itens 1.1 e 1.5 da seção "Administrar Usuários".
-- 
-- =====================================================================

-- Tabela para armazenar todos os usuários da ferramenta (Admin, Escuderia, Piloto)
-- Justificativa: Centraliza a autenticação e o controle de permissões.
-- O campo 'tipo' usa um CHECK para garantir a integridade dos dados.
-- O campo 'idoriginal' vincula o usuário à sua entidade na base (piloto ou escuderia).
CREATE TABLE IF NOT EXISTS public.users (
    userid SERIAL PRIMARY KEY,
    login VARCHAR(100) UNIQUE NOT NULL,
    password TEXT NOT NULL, -- Armazenará o hash SCRAM-SHA-256 
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('Administrador', 'Escuderia', 'Piloto')),
    idoriginal INTEGER
);

COMMENT ON TABLE public.users IS 'Tabela de usuários para autenticação na ferramenta.';
COMMENT ON COLUMN public.users.idoriginal IS 'ID da tabela de origem (driver.driverid ou constructors.constructorid).';

-- Tabela para auditar os logins dos usuários
-- Justificativa: Cumpre o requisito de auditoria de acessos, registrando
-- cada login com o ID do usuário e o timestamp, conforme solicitado.
CREATE TABLE IF NOT EXISTS public.users_log (
    logid SERIAL PRIMARY KEY,
    userid INTEGER NOT NULL REFERENCES public.users(userid),
    data_login TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.users_log IS 'Log de auditoria para os acessos (logins) dos usuários.';