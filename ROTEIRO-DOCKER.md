# Roteiro: Gerenciador de Tarefas com Docker Compose

Projeto 04 da atividade "Projetos com Dockerfile e Docker Compose". O código da aplicação é o original do professor, sem alterações. Os arquivos criados para a atividade são:

| Arquivo | Para que serve |
|---|---|
| `Dockerfile` | Receita da imagem própria do app (`gerenciador-tarefas:1.0`) |
| `.dockerignore` | O que **não** entra na imagem (`node_modules`, `.env`, `.git`, `database/`...) |
| `compose.yaml` | Os 2 serviços (`app` e `db`), a rede, o volume, as variáveis e a ordem de inicialização |

Testado: CRUD completo, os 4 testes do README e persistência com `docker compose down` + `docker compose up -d`.

## 1. Preparar

No Windows: **Docker Desktop aberto** (com "Engine running") e o **Git Bash**.

```bash
cd ~
git clone https://github.com/vicentenrx/gerenciador-tarefas-compnuvem.git
cd gerenciador-tarefas-compnuvem
```

Se a pasta já existe, entre nela e rode `git pull`.

Se os containers da Prática 1 ainda estiverem rodando, eles ocupam a porta 3000. Remova-os (o volume `dados-alunos` não é apagado):

```bash
docker rm -f app-alunos postgres-alunos adminer-alunos
```

## 2. Subir a aplicação

```bash
docker compose up -d --build
```

A saída termina com:

```
 Container tarefas-db  Healthy
 Container tarefas-app Started
```

Abra **http://localhost:3000**. A primeira tela já mostra 3 tarefas (Marina, Lucas e Pedro), que vêm do `database/init.sql`.

Teste de saúde: http://localhost:3000/api/health deve responder `{"status":"ok","database":"conectado"}`.

## 3. Comandos da apresentação

| Comando | O que mostrar |
|---|---|
| `docker compose ps` | `tarefas-app` **Up** e `tarefas-db` **Up (healthy)** |
| `docker images` | `gerenciador-tarefas:1.0` (a imagem própria) e `postgres:16` |
| `docker ps` | Os 2 containers; só o app publica porta (`0.0.0.0:3000->3000`); o banco mostra só `5432/tcp` |
| `docker network ls` | `gerenciador-tarefas_rede-tarefas` (driver `bridge`) |
| `docker network inspect gerenciador-tarefas_rede-tarefas` | Na seção `"Containers"`: `tarefas-app` e `tarefas-db` |
| `docker volume ls` | `gerenciador-tarefas_dados-tarefas` |
| `docker compose logs` | `running /docker-entrypoint-initdb.d/init.sql` (só na 1ª vez) e `Gerenciador de Tarefas: http://localhost:3000` |
| `docker compose stop` | Containers ficam **Exited**, mas continuam existindo |
| `docker compose start` | Os mesmos containers voltam |
| `docker compose down` | Remove containers e rede; **o volume fica** |
| `docker compose up -d` | Recria tudo e os dados continuam lá |

O Compose usa o nome do projeto (`name: gerenciador-tarefas`) como prefixo da rede e do volume.

## 4. Testes na interface

1. **Cadastrar tarefa e prazo:** preencha título, responsável, prazo e status e clique em **Cadastrar**. Aparece "Registro cadastrado.".
2. **Marcar como concluída:** clique em **Editar** na tarefa, mude o Status para **Concluída** e clique em **Salvar alterações**. Aparece "Registro atualizado.".
3. **Filtrar por responsável:** digite um nome (ex.: `Marina`) no campo **Pesquisar registros**. A tabela mostra só as tarefas dessa pessoa.
4. **Excluir:** clique em **Excluir** e confirme. Aparece "Registro excluído.".

Consulta direta no banco, para mostrar que os dados estão no PostgreSQL:

```bash
docker compose exec -T db psql -U appuser -d laboratorio -c "SELECT * FROM tarefas;"
```

## 5. Teste de persistência

```bash
docker compose down
docker volume ls
docker compose up -d
```

Recarregue a página: as tarefas cadastradas, editadas e excluídas continuam como estavam. O `init.sql` **não** roda de novo, porque o volume já tem dados.

> **Não use `docker compose down -v` neste teste:** o `-v` apaga o volume e todos os dados.

## 6. Para explicar ao professor

- **Dockerfile:** parte do `node:22-alpine`, copia primeiro o `package.json` (para aproveitar o cache: se só o código mudar, o `npm install` não roda de novo), instala só as dependências de produção, copia o código e inicia com `npm start`. Roda com o usuário `node`, e não como root.
- **.dockerignore:** deixa a imagem menor e evita levar para dentro dela o `node_modules` do Windows, o `.env` com senhas e o `.git`.
- **Rede bridge:** o app acessa o banco com `DB_HOST: db`, que é o **nome do serviço**. O DNS da rede do Compose resolve esse nome para o IP do container, sem IP fixo.
- **Porta do banco:** o `db` não tem `ports`, então o PostgreSQL só é acessível de dentro da rede. Só o app publica a porta 3000.
- **Volume:** `dados-tarefas` guarda `/var/lib/postgresql/data`. Remover o container não apaga o volume.
- **init.sql:** montado em `/docker-entrypoint-initdb.d/` como somente leitura (`:ro`). O PostgreSQL só o executa quando o volume está vazio, ou seja, na primeira inicialização.
- **healthcheck + depends_on:** o `depends_on` sozinho só espera o container do banco *iniciar*. Com `condition: service_healthy`, o app espera o `pg_isready` confirmar que o banco já aceita conexões.
- **restart: unless-stopped:** se um container cair, o Docker o religa. Isso foi testado: ao reiniciar o banco com o app no ar, o app caiu (o código não trata a queda da conexão) e o Docker o religou sozinho.

## 7. Problemas comuns

| Sintoma | Solução |
|---|---|
| `error during connect` / `dockerDesktopLinuxEngine` | O Docker Desktop está fechado. Abra e espere "Engine running". |
| `port is already allocated` (3000) | Containers da Prática 1 ainda rodando: veja o item 1. |
| `429 Too Many Requests` ao baixar imagens | Limite de downloads do Docker Hub (comum em rede de laboratório). Espere alguns minutos e tente de novo, ou faça `docker login` com uma conta gratuita. Para não depender da rede da aula, rode `docker compose up -d --build` uma vez em casa antes: as imagens ficam salvas. |
| Página abre mas dá erro / tabela `tarefas` não existe | O volume foi criado antes, com o banco vazio ou com outro script. **Fora do teste de persistência**, apague e recrie: `docker compose down -v` e depois `docker compose up -d`. Isso apaga os dados. |
| Alterei um arquivo e nada mudou | O código fica dentro da imagem: `docker compose up -d --build`. |
| `the input device is not a TTY` no Git Bash | Use `docker compose exec -T ...` (como no item 4) ou coloque `winpty` antes do comando. |
| Ver o que deu errado | `docker compose logs app` ou `docker compose logs db` |
