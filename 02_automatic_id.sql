-- Ajusta a tabela CONSTRUCTORS
-- 1. Cria uma sequência para os IDs
CREATE SEQUENCE IF NOT EXISTS constructors_constructorid_seq;

-- 2. Define o valor padrão da coluna para pegar o próximo valor da sequência
ALTER TABLE constructors ALTER COLUMN constructorid SET DEFAULT nextval('constructors_constructorid_seq');

-- 3. Vincula a sequência à coluna (para consistência)
ALTER SEQUENCE constructors_constructorid_seq OWNED BY constructors.constructorid;

-- 4. Atualiza a sequência para começar a contar a partir do maior ID existente + 1
SELECT setval('constructors_constructorid_seq', COALESCE((SELECT MAX(constructorid) FROM constructors), 1));


--- Ajusta a tabela DRIVER
-- 1. Cria uma sequência para os IDs
CREATE SEQUENCE IF NOT EXISTS driver_driverid_seq;

-- 2. Define o valor padrão da coluna para pegar o próximo valor da sequência
ALTER TABLE driver ALTER COLUMN driverid SET DEFAULT nextval('driver_driverid_seq');

-- 3. Vincula a sequência à coluna
ALTER SEQUENCE driver_driverid_seq OWNED BY driver.driverid;

-- 4. Atualiza a sequência para começar a contar a partir do maior ID existente + 1
SELECT setval('driver_driverid_seq', COALESCE((SELECT MAX(driverid) FROM driver), 1));