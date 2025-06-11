# Projeto Final - Laboratório de Bases de Dados (SCC-541)

## Descrição do Projeto

Este projeto consiste no desenvolvimento de um protótipo de ferramenta com interface web amigável, projetada para explorar, manipular e gerar relatórios a partir de uma base de dados da Fórmula 1 - FIA. A aplicação atende a três perfis de usuários distintos (Administrador, Escuderia e Piloto), cada um com suas permissões e visualizações específicas, implementando conceitos de banco de dados como funções, gatilhos e otimização de consultas com índices.

**Autores:**
* Lua Gabriella Gonçalves Maia - 13717786 
* Mateus Vinicius Bezerra - 9863382 
* Márcio Guilherme Vieira Silva - 11355786 
* Rafael Jun Morita - 10845040


---

## Tecnologias Utilizadas

* **Backend:** Python 3
    * **Framework:** Flask
    * **Conector PostgreSQL:** psycopg2
* **Frontend:** HTML5, CSS3
    * **Framework CSS:** Bootstrap 5
* **Banco de Dados:** PostgreSQL 17

---

## Estrutura do Projeto

```
/Projeto_F1
|
|-- /templates                          # Arquivos HTML do frontend
|-- /static                             # Arquivos estáticos (CSS)
|
|-- 01_schema_usuarios.sql
|-- 02_automatic_id.sql
|-- 03_gerenciamento_usuarios.sql
|-- 04_admin_create.sql
|-- 05_dashboards.sql
|-- 06_relatorios.sql
|-- 07_acoes_usuarios.sql
|
|-- app.py                              # Aplicação principal Flask
|-- db.py                               # Módulo de conexão com o banco
|-- requirements.txt                    # Dependências do Python
|-- README.md                           # Este arquivo
```

---

## Pré-requisitos

Antes de iniciar, certifique-se de que os seguintes programas estão instalados em sua máquina:

* **PostgreSQL** (versão 12 ou superior)
* **pgAdmin 4** (ou outra ferramenta de sua preferência para gerenciar o banco)
* **Python** (versão 3.9 ou superior)

---

## Instalação e Execução

Siga estes passos para configurar e rodar o projeto localmente.

### Fase 1: Configuração do Banco de Dados

1.  **Crie o Banco de Dados:**
    * Abra o pgAdmin e crie um novo banco de dados. O nome sugerido nos scripts é `f1_projeto`.

2.  **Carregue os Dados Base da F1:**
    * Este projeto utiliza a mesma base de dados do Trabalho 1. Carregue os arquivos `.csv` originais (`circuits.csv`, `driver.csv`, `constructors.csv`, `races.csv`, `results.csv`, `status.csv`, etc.) nas tabelas correspondentes dentro do banco `f1_projeto`.

3.  **Execute os Scripts SQL do Projeto:**
    * No pgAdmin, abra uma "Query Tool" para o banco `f1_projeto`.
    * Execute os arquivos `.sql` fornecidos **na seguinte ordem**:
        1.  `01_schema_usuarios.sql`            (Cria as tabelas de usuários)
        2.  `02_automatic_id.sql`               (Altera as tabelas para que os IDs sejam automáticos)
        3.  `03_gerenciamento_usuarios.sql`     (Popula a tabela de usuários e cria gatilhos)
        4.  `04_admin_create.sql`               (Cria o usuário administrador)
        5.  `05_dashboards.sql`                 (Cria as funções do dashboard)
        6.  `06_relatorios.sql`                 (Cria as funções dos relatórios)
        7.  `07_acoes_usuarios.sql`             (Cria as funções para as ações dos usuários)

    **Importante:** Para os scripts que criam funções (03, 04, 05), execute cada bloco `CREATE FUNCTION` individualmente, selecionando todo o texto da função antes de clicar em "Executar", para evitar erros de sintaxe.

### Fase 2: Configuração do Ambiente Python

1.  **Navegue até a Pasta do Projeto:**
    * Abra um terminal (Prompt de Comando ou PowerShell) e use o comando `cd` para navegar até a pasta raiz do projeto.

2.  **Crie e Ative um Ambiente Virtual:**
    ```bash
    # Criar o ambiente
    python -m venv venv

    # Ativar no Windows (cmd ou PowerShell)
    venv\Scripts\activate.bat

    # Ativar no macOS/Linux
    source venv/bin/activate.bat
    ```

3.  **Instale as Dependências:**
    ```bash
    pip install -r requirements.txt
    ```

### Fase 3: Configuração da Aplicação

1.  **Abra o arquivo `db.py`** em um editor de texto.
2.  **Edite o dicionário `DB_CONFIG`** com as suas credenciais do PostgreSQL:

    ```python
    DB_CONFIG = {
        "dbname": "f1_projeto",
        "user": "postgres",             # Seu usuário do PostgreSQL
        "password": "SUA_SENHA_REAL",   # Sua senha do PostgreSQL
        "host": "localhost",
        "port": "5432"
    }
    ```

### Fase 4: Execução

1.  No terminal (com o ambiente virtual ativado), execute o servidor Flask:
    ```bash
    python app.py
    ```
2.  O terminal exibirá a mensagem `* Running on http://127.0.0.1:5000`.
3.  Abra seu navegador e acesse: **[http://127.0.0.1:5000/login](http://127.0.0.1:5000/login)**

---

## Logins de Teste

Utilize os seguintes logins para testar os diferentes perfis de usuário, conforme especificado no escopo do projeto:

* **Administrador:**
    * **Login:** `admin` 
    * **Senha:** `admin` 

* **Escuderia (Exemplo):**
    * **Login:** `mclaren_c` 
    * **Senha:** `mclaren` 

* **Piloto (Exemplo):**
    * **Login:** `hamilton_d` 
    * **Senha:** `hamilton` 

---

## Justificativas Técnicas

Conforme solicitado, os conceitos da disciplina foram aplicados da seguinte forma:

* **Funções PL/SQL:** Utilizadas para encapsular toda a lógica de negócio para a geração dos dados dos Dashboards e Relatórios. Isso separa a lógica do banco de dados da aplicação Python, tornando o código mais limpo e modular.
* **Triggers:** Empregadas para automatizar a criação e atualização de registros na tabela `USERS` sempre que um novo piloto ou escuderia é cadastrado. Isso garante a consistência e integridade do sistema de autenticação.
* **Índices:** Foram criados índices específicos nas tabelas `results`, `airports` e `geocities15k` para otimizar o desempenho das consultas mais complexas, como as dos Relatórios 2, 4 e 6, reduzindo o tempo de resposta.
* **Visões (Views):** O conceito de visão foi aplicado na criação da tabela `results_status`, que é mantida por um gatilho. Embora não seja uma `VIEW` no sentido estrito, ela funciona como uma visão materializada, pré-calculando os dados para o Relatório 1 do Admin e tornando sua exibição instantânea.

---
