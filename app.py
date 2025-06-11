# app.py
from flask import Flask, render_template, request, redirect, url_for, session
import db

app = Flask(__name__)
# Chave secreta para gerenciar sessões de usuário (mantenha segura em um projeto real)
app.secret_key = 'super_secret_key_f1'

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        login = request.form['login']
        password = request.form['password']
        
        user_info = db.verify_login(login, password)
        
        if user_info:
            # Armazena informações do usuário na sessão
            session['user_info'] = user_info
            return redirect(url_for('dashboard'))
        else:
            # Se o login falhar, exibe uma mensagem de erro
            return render_template('login.html', error="Login ou senha inválidos.")
            
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('user_info', None) # Limpa a sessão
    return redirect(url_for('login'))

@app.route('/')
@app.route('/dashboard')
def dashboard():
    if 'user_info' not in session:
        return redirect(url_for('login'))

    user_info = session['user_info']
    user_tipo = user_info['tipo']
    
    # Busca dados de exibição para a tela de dashboard
    display_info = db.get_display_info(user_tipo, user_info['idoriginal'])

    if user_tipo == 'Administrador':
        # Busca dados do dashboard do Admin
        counts = db.call_db_function('get_dashboard_admin_counts')
        return render_template('dashboard_admin.html', user=user_info, counts=counts)
        
    elif user_tipo == 'Escuderia':
        # Busca dados do dashboard da Escuderia
        dashboard_data = db.call_db_function('get_dashboard_escuderia', (user_info['idoriginal'],))
        return render_template('dashboard_escuderia.html', user=user_info, display=display_info, data=dashboard_data)
        
    elif user_tipo == 'Piloto':
        # Busca dados do dashboard do Piloto
        anos = db.call_db_function('get_dashboard_piloto_anos', (user_info['idoriginal'],))
        desempenho = db.call_db_function('get_dashboard_piloto_desempenho', (user_info['idoriginal'],))
        return render_template('dashboard_piloto.html', user=user_info, display=display_info, anos=anos, desempenho=desempenho)

    return redirect(url_for('login'))


@app.route('/relatorio/<nome_relatorio>')
def relatorio(nome_relatorio):
    if 'user_info' not in session:
        return redirect(url_for('login'))

    user_info = session['user_info']
    user_id = user_info['idoriginal']
    data = None
    
    # Mapeia o nome do relatório para a função do DB e o título da página
    report_map = {
        # Admin
        'admin_status': ('get_relatorio_admin_status', None, "Relatório de Resultados por Status"),
        'admin_aeroportos': ('get_relatorio_admin_aeroportos', None, "Relatório de Resultados por Aeroportos"),
        'desempenho_circuitos': ('get_relatorio_desempenho_circuitos', None, "Relatório de Desempenho por Circuitos"),
        # Escuderia
        'escuderia_vitorias': ('get_relatorio_escuderia_vitorias', (user_id,), "Relatório de Vitórias por Piloto"),
        'escuderia_status': ('get_relatorio_escuderia_status', (user_id,), "Relatório de Status da Escuderia"),
        # Piloto
        'piloto_pontos': ('get_relatorio_piloto_pontos', (user_id,), "Relatório de Pontos por Corrida"),
        'piloto_status': ('get_relatorio_piloto_status', (user_id,), "Relatório de Status do Piloto")
    }

    if nome_relatorio in report_map:
        func_name, args, title = report_map[nome_relatorio]
        data = db.call_db_function(func_name, args)
        return render_template('relatorio.html', data=data, title=title)
        
    return "Relatório não encontrado.", 404

@app.route('/cadastrar_escuderia', methods=['GET', 'POST'])
def cadastrar_escuderia():
    if 'user_info' not in session or session['user_info']['tipo'] != 'Administrador':
        return redirect(url_for('login'))

    if request.method == 'POST':
        constructor_ref = request.form['constructor_ref']
        name = request.form['name']
        nationality = request.form['nationality']
        url = request.form['url']

        sucesso, mensagem = db.inserir_escuderia(constructor_ref, name, nationality, url)
        return render_template('cadastrar_escuderia.html', sucesso=sucesso, mensagem=mensagem)

    return render_template('cadastrar_escuderia.html')


@app.route('/cadastrar_piloto', methods=['GET', 'POST'])
def cadastrar_piloto():
    if 'user_info' not in session or session['user_info']['tipo'] != 'Administrador':
        return redirect(url_for('login'))

    if request.method == 'POST':
        driver_ref = request.form['driver_ref']
        number = request.form['number']
        code = request.form['code']
        forename = request.form['forename']
        surname = request.form['surname']
        dob = request.form['dob']
        nationality = request.form['nationality']

        sucesso, mensagem = db.inserir_piloto(driver_ref, number, code, forename, surname, dob, nationality)
        return render_template('cadastrar_piloto.html', sucesso=sucesso, mensagem=mensagem)

    return render_template('cadastrar_piloto.html')


if __name__ == '__main__':
    app.run(debug=True)