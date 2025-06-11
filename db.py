# db.py
import psycopg2
import psycopg2.pool

# --- IMPORTANTE: Configure suas credenciais do PostgreSQL aqui ---
DB_CONFIG = {
    "dbname": "ProjetoLabBD",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": "5432"
}

# Pool de conexões para otimizar o acesso ao banco
pool = psycopg2.pool.SimpleConnectionPool(1, 10, **DB_CONFIG)

def get_db_connection():
    """Obtém uma conexão do pool."""
    return pool.getconn()

def release_db_connection(conn):
    """Devolve a conexão ao pool."""
    pool.putconn(conn)

def call_db_function(function_name, args=None):
    """
    Função genérica para chamar uma função do PostgreSQL e retornar os resultados.
    """
    conn = get_db_connection()
    results = []
    try:
        with conn.cursor() as cur:
            # Constrói a chamada da função SQL
            if args:
                placeholders = ', '.join(['%s'] * len(args))
                cur.execute(f"SELECT * FROM {function_name}({placeholders})", args)
            else:
                cur.execute(f"SELECT * FROM {function_name}()")

            if cur.description:
                # Obtém os nomes das colunas
                colnames = [desc[0] for desc in cur.description]
                # Busca todos os resultados
                rows = cur.fetchall()
                results = {"headers": colnames, "rows": rows}
    except Exception as e:
        print(f"Erro ao executar a função {function_name}: {e}")
        # Em caso de erro, retorna uma estrutura vazia para não quebrar o frontend
        results = {"headers": ["Erro"], "rows": [[str(e)]]}
    finally:
        release_db_connection(conn)
    return results

def verify_login(login, password):
    """
    Verifica as credenciais do usuário.
    Para a lógica da aplicação, verificamos
    o login e a senha (que, no protótipo, estão em texto plano).
    """
    conn = get_db_connection()
    user_info = None
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT userid, login, tipo, idoriginal FROM users WHERE login = %s AND password = %s", (login, password))
            user = cur.fetchone()
            if user:
                user_info = {"userid": user[0], "login": user[1], "tipo": user[2], "idoriginal": user[3]}
    except Exception as e:
        print(f"Erro na verificação de login: {e}")
    finally:
        release_db_connection(conn)
    return user_info

def get_display_info(user_tipo, user_idoriginal):
    """Busca informações de exibição (nome do piloto/escuderia)."""
    conn = get_db_connection()
    display = {}
    try:
        with conn.cursor() as cur:
            if user_tipo == 'Piloto':
                cur.execute("SELECT forename || ' ' || surname, (SELECT name FROM constructors c JOIN results r ON c.constructorid = r.constructorid WHERE r.driverid = %s LIMIT 1) FROM driver WHERE driverid = %s", (user_idoriginal, user_idoriginal))
                res = cur.fetchone()
                if res:
                    display = {"nome_piloto": res[0], "nome_escuderia": res[1]}
            elif user_tipo == 'Escuderia':
                cur.execute("SELECT name, (SELECT COUNT(DISTINCT driverid) FROM results WHERE constructorid = %s) FROM constructors WHERE constructorid = %s", (user_idoriginal, user_idoriginal))
                res = cur.fetchone()
                if res:
                    display = {"nome_escuderia": res[0], "qtd_pilotos": res[1]}
    except Exception as e:
        print(f"Erro ao buscar informações de exibição: {e}")
    finally:
        release_db_connection(conn)
    return display

def inserir_escuderia(constructor_ref, name, nationality, url):
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("INSERT INTO constructors (constructorref, name, nationality, url) VALUES (%s, %s, %s, %s)",
                    (constructor_ref, name, nationality, url))
        conn.commit()
        return True, "Escuderia cadastrada com sucesso."
    except Exception as e:
        return False, f"Erro ao cadastrar escuderia: {e}"


