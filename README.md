# LifeUp (AV2 — App Flutter)

> Evolução Offline-First da Avaliação Processual 2B (Flutter + SQLite + sync HTTP).  
> A API REST correspondente está em `../life_up_av2_api`.  
> A base CLI da AP1B permanece em `../life_up_av1`.

## Descrição

> LifeUp AV2 é um aplicativo Flutter de monitoramento pessoal e hábitos conectados, com arquitetura Offline-First: a interface lê e grava no SQLite local e sincroniza pendências com a API REST sob demanda (tela Sync).

Projeto prático da disciplina **Computação Móvel** (AP2B) — Curso de Sistemas de Informação.

**Grupo 04**

---

## Integrantes

* Allan Scherrer Santos
* Maxuel Peçanha Silva
* Gabriel de Oliveira Palmeiras
* Rafael de Almeida Pereira
* Matheus Anholetti Pessoa de Souza

---

## Tema

```text
Tema 03 — Monitoramento Pessoal & Hábitos Conectados
```

---

## Tecnologias

```text
Flutter / Dart 3
sqflite (SQLite local)
shared_preferences
package:http
uuid / intl
Material Design 3
flutter_test
```

---

## Arquitetura

O projeto segue Offline-First com padrão Repository (fonte única da verdade = SQLite):

```text
UI (telas Flutter / MainShell)
 ↓ Future / formulários
LifeUpRepository
 ├─ 1º SQLite (sqflite)  ← Single Source of Truth
 └─ 2º HTTP sync sob demanda → life_up_av2_api
```

| Camada | Responsabilidade |
|--------|------------------|
| **Screens / Widgets** | Interface, formulários, navbar, FAB contextual, SyncBadge |
| **AppScope** | Injeta repository, API e sessão na árvore de widgets |
| **Repository** | Orquestra CRUD local e sync HTTP; captura falhas de rede |
| **Datasources local** | DAO `sqflite` (insert / query / update / delete) |
| **Datasources remote** | `ApiClient` (login, register, sync, health) |
| **Models** | `Habito`, `Meta`, `Registro`, `UsuarioSessao` (`toMap` / `fromMap`) |
| **Services** | Sessão do usuário (`SharedPreferences`) |
| **Config** | URL da API e timeout |

### Fluxo Offline-First

1. Leitura e escrita sempre no SQLite (`sincronizado = false` ao criar/editar).
2. UI atualiza imediatamente (funciona em modo avião).
3. Sincronização **manual** na tela Sync: `POST /usuarios/:id/sync` envia pendências e consolida o retorno.

---

## Rotas nomeadas (≥ 10)

| # | Rota | Tela | Função |
|---|------|------|--------|
| 1 | `/` | SplashScreen | Boot + restaura sessão |
| 2 | `/login` | LoginScreen | Autenticação |
| 3 | `/register` | RegisterScreen | Cadastro |
| 4 | `/home` | MainShellScreen | Shell (Início / Hábitos / Metas / Sync + FAB) |
| 5 | `/habitos` | HabitosListScreen | Listagem de hábitos |
| 6 | `/habitos/form` | HabitoFormScreen | Criar / editar hábito |
| 7 | `/habitos/detalhe` | HabitoDetailScreen | Detalhe do hábito |
| 8 | `/metas` | MetasListScreen | Listagem de metas |
| 9 | `/metas/form` | MetaFormScreen | Criar / editar meta |
| 10 | `/registros` | RegistrosListScreen | Histórico de registros |
| 11 | `/registros/form` | RegistroFormScreen | Novo registro |
| 12 | `/sync` | SyncScreen | Diagnóstico + sync manual |
| 13 | `/perfil` | PerfilScreen | Perfil + logout |

**Total: 13 rotas.** Navegação logada: **Início · Hábitos · [FAB contextual] · Metas · Sync**.

O FAB central muda conforme a aba: registro / hábito / meta / sincronizar.

---

## Como configurar

### 1. Instalar Flutter

Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable) e um emulador Android ou dispositivo.

Verifique:

```bash
flutter doctor
flutter --version
```

### 2. Subir a API (local ou Render)

- Local: ver `../life_up_av2_api` (`dart run bin/server.dart` na porta **8080**).
- Produção: URL do Web Service no Render.

No emulador Android, `localhost` do host = **`10.0.2.2`**.

### 3. (Opcional) Definir a URL da API

Padrão em `lib/config/api_config.dart`: `http://10.0.2.2:8080`.  
Para sobrescrever no run:

```bash
flutter run --dart-define=API_BASE_URL=https://SUA-API.onrender.com
```

---

## Como instalar dependências

Na pasta `life_up_av2_app`:

```bash
flutter pub get
```

---

## Como executar

```bash
cd life_up_av2_app
flutter run

# Emulador Android apontando para API local:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# API no Render:
flutter run --dart-define=API_BASE_URL=https://SUA-API.onrender.com
```

### Testes automatizados

```bash
flutter test
```

A suíte cobre domínio/models, repository Offline-First com `MockClient` e widgets (login, SyncBadge, etc.).

---

## Estrutura de pastas

```text
life_up_av2_app/
├── lib/
│   ├── main.dart
│   ├── app_scope.dart
│   ├── config/
│   ├── models/
│   ├── datasources/
│   │   ├── local/          # sqflite (DAOs)
│   │   └── remote/         # ApiClient HTTP
│   ├── repositories/       # LifeUpRepository
│   ├── services/           # SessaoService
│   ├── screens/            # Telas + MainShell
│   ├── widgets/            # Cards, SyncBadge, navbar, filtros
│   └── theme/
├── test/
├── README.md
├── ROTEIRO_APRESENTACAO_AP2B.md
└── pubspec.yaml
```

---

## API

Projeto irmão: [`../life_up_av2_api`](../life_up_av2_api)

| Recurso | Caminho |
|---------|---------|
| Health | `GET /health` |
| Sync Offline-First | `POST /usuarios/:id/sync` |
| Swagger | `http://localhost:8080/swagger` |

---

## Declaração de Uso de IA

Ferramentas de Inteligência Artificial foram usadas como apoio durante o desenvolvimento:

**Cursor:** Apoio na estrutura Offline-First (DAO/repositório/telas), shell com FAB contextual, filtros, testes com `MockClient` e documentação.

**ChatGPT:** Apoio em dúvidas pontuais de Flutter/Dart, revisão de ideias de arquitetura e clareza do README.

O uso foi de suporte: scaffolding, depuração e organização. A validação no emulador, o deploy, a integração com a API e a defesa técnica ficaram a cargo do grupo.

### Exemplos de prompts utilizados

* “Como organizar um Repository Offline-First com sqflite e package:http?”
* “Como passar argumentos em rotas nomeadas do MaterialApp?”
* “Como simular API 500 e falha de rede nos testes com MockClient?”
* “Como implementar um FAB contextual conforme a aba do IndexedStack?”
* “Revisa se o README cobre arquitetura Offline-First, rotas, comandos e Declaração de IA.”

---

## Referências

* Flutter Documentation: https://docs.flutter.dev
* Dart Language Tour: https://dart.dev/language
* Package `sqflite`: https://pub.dev/packages/sqflite
* Package `shared_preferences`: https://pub.dev/packages/shared_preferences
* Package `http`: https://pub.dev/packages/http
* Package `uuid`: https://pub.dev/packages/uuid
* Testing Flutter apps: https://docs.flutter.dev/testing
* Material Design 3: https://m3.material.io
