# Orbytis Atlas

![Preview do projeto](https://i.imgur.com/f8JGy3W.png)

> Aplicativo mobile desenvolvido em Flutter para gerenciamento de **Ordens de Serviço e Inspeções em campo**, com suporte a operação offline, persistência local e sincronização automática com uma API.
>
> Projeto desenvolvido como desafio técnico para uma vaga de **Desenvolvedor Mobile Flutter**.

---

## Tecnologias

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge\&logo=dart\&logoColor=white)
![flutter\_bloc](https://img.shields.io/badge/flutter__bloc-5A45FF?style=for-the-badge\&logo=bloc\&logoColor=white)
![Dio](https://img.shields.io/badge/Dio-5A64D8?style=for-the-badge\&logo=dart\&logoColor=white)
![Hive CE](https://img.shields.io/badge/Hive%20CE-FFCA28?style=for-the-badge\&logo=dart\&logoColor=black)
![flutter\_secure\_storage](https://img.shields.io/badge/flutter__secure__storage-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![GoRouter](https://img.shields.io/badge/GoRouter-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![Geolocator](https://img.shields.io/badge/Geolocator-4285F4?style=for-the-badge\&logo=googlemaps\&logoColor=white)
![ImagePicker](https://img.shields.io/badge/ImagePicker-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![connectivity\_plus](https://img.shields.io/badge/connectivity__plus-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![UUID](https://img.shields.io/badge/UUID-6A53F6?style=for-the-badge\&logo=dart\&logoColor=white)
![Mocktail](https://img.shields.io/badge/Mocktail-E91E63?style=for-the-badge\&logo=dart\&logoColor=white)
![bloc\_test](https://img.shields.io/badge/bloc__test-5A45FF?style=for-the-badge\&logo=bloc\&logoColor=white)

---

# Como executar o projeto

## Pré-requisitos

Tenha instalado:

* Flutter com Dart compatível com `^3.13.2`, conforme o `pubspec.yaml`;
* Android SDK;
* Node.js;
* dispositivo Android físico ou emulador.

Verifique o ambiente Flutter:

```bash
flutter doctor
```

Clone o repositório e instale as dependências:

```bash
flutter pub get
```

---

## API Mock

A API mock utilizada pelo aplicativo faz parte dos **materiais oficiais fornecidos para o desafio técnico**.

O pacote original do desafio, contendo a API mock, contrato da API e demais arquivos de apoio, foi disponibilizado pela empresa:

[Materiais oficiais do Desafio Flutter](https://engeselt-my.sharepoint.com/personal/demesio_oliveira_engeselt_onmicrosoft_com/_layouts/15/onedrive.aspx?id=%2Fpersonal%2Fdemesio_oliveira_engeselt_onmicrosoft_com%2FDocuments%2FDesafio%20Flutter%2Fdesafio%2Dflutter%2Ezip&parent=%2Fpersonal%2Fdemesio_oliveira_engeselt_onmicrosoft_com%2FDocuments%2FDesafio%20Flutter&ga=1&LOF=1)

> A API mock não foi desenvolvida como parte deste aplicativo. Ela foi fornecida pela empresa como suporte para desenvolvimento e validação do desafio técnico.

### Instalando e executando o mock

Após baixar e extrair o material do desafio, acesse a pasta da API:

```bash
cd mock-api
```

Instale as dependências:

```bash
npm install
```

Inicie o servidor:

```bash
npm run start
```

A API ficará disponível por padrão em:

```text
http://localhost:3000
```

Utilize as credenciais disponibilizadas nos materiais oficiais do desafio para realizar o login.

---

## Executando no Android Emulator

Dentro do Android Emulator, `localhost` representa o próprio dispositivo virtual.

Para acessar a API executada na máquina host, utilize:

```text
http://10.0.2.2:3000
```

Altere `AppConfig.apiBaseUrl` em `lib/core/config/app_config.dart` para esse endereço antes de executar. O valor atual do projeto é `http://localhost:3000`; a seleção de URL não é automática.

Depois execute:

```bash
flutter run
```

---

## Executando em dispositivo Android físico

Com o dispositivo conectado por USB e a depuração USB habilitada:

```bash
adb devices
```

Crie um redirecionamento para a porta da API:

```bash
adb reverse tcp:3000 tcp:3000
```

Nesse cenário, o aplicativo pode acessar:

```text
http://localhost:3000
```

Mantenha (ou restaure) esse valor em `AppConfig.apiBaseUrl`, em `lib/core/config/app_config.dart`.

Depois:

```bash
flutter run
```

Para verificar os redirecionamentos existentes:

```bash
adb reverse --list
```

Para remover:

```bash
adb reverse --remove tcp:3000
```

A remoção do `adb reverse` também pode ser utilizada para validar o comportamento offline do aplicativo durante o desenvolvimento.

---

# Arquitetura escolhida

O projeto utiliza uma arquitetura organizada por **features**, inspirada nos princípios de Clean Architecture e SOLID.

O objetivo foi separar:

* apresentação;
* gerenciamento de estado;
* coordenação das regras da aplicação;
* acesso a dados;
* serviços externos;
* detalhes de infraestrutura.

Estrutura simplificada:

```text
lib/
├── app/
│   ├── router/
│   ├── theme/
│   └── widgets/
│
├── core/
│   ├── auth/
│   ├── errors/
│   ├── network/
│   └── storage/
│
└── features/
    ├── auth/
    ├── work_orders/
    └── inspections/
```

Dentro das features:

```text
feature/
├── datasources/
├── errors/
├── models/
├── repositories/
├── services/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

---

## Fluxo de dependências

O fluxo principal é:

```text
UI
 ↓
BLoC
 ↓
Repository
 ↓
Abstrações
 ↓
Implementações concretas
```

Por exemplo:

```text
InspectionBloc
      ↓
InspectionsRepository
      ↓
┌─────────────────────────────────┐
│ InspectionsLocalDataSource      │
│ InspectionsRemoteDataSource     │
│ InspectionPhotoService          │
│ InspectionLocationService       │
└─────────────────────────────────┘
      ↑
Implementações concretas
      │
┌──────────┬───────┬─────────────┬────────────┐
│ Hive     │ Dio   │ ImagePicker │ Geolocator │
└──────────┴───────┴─────────────┴────────────┘
```

A camada de apresentação não acessa diretamente Dio, Hive, ImagePicker ou Geolocator.

---

## Dependency Inversion

Os contratos de infraestrutura são definidos utilizando `abstract interface class`.

As implementações reais permanecem `final`.

Exemplo:

```dart
abstract interface class InspectionsRemoteDataSource {
  Future<String> submitInspection(
    Inspection inspection,
  );
}

final class InspectionsRemoteDataSourceImpl
    implements InspectionsRemoteDataSource {
  // implementação utilizando Dio
}
```

Assim:

```text
Repository
   ↓
Interface
   ↑
Implementação concreta
```

em vez de:

```text
Repository
   ↓
Dio / Hive / Geolocator / ImagePicker
```

Essa decisão reduz o acoplamento e facilita:

* testes automatizados;
* substituição das implementações;
* evolução da infraestrutura;
* manutenção do código.

---

## Composition Root

O `main.dart` funciona como **Composition Root** da aplicação.

Ele é responsável por construir as implementações concretas e conectá-las:

```text
main.dart
 ↓
DataSources / Services
 ↓
Repositories
 ↓
BLoCs
 ↓
UI
```

Dessa forma, as camadas internas não precisam conhecer como suas dependências concretas são construídas.

---

## Gerenciamento de estado

Foi utilizado `flutter_bloc`.

Os formulários, autenticação e listagens usam BLoCs. A sincronização geral acionada na lista de OS usa o `InspectionQueueCubit`, responsável pelo estado de carregamento, bloqueio de cliques repetidos e mensagem de resultado.

Fluxo:

```text
UI
 ↓
Event
 ↓
BLoC
 ↓
Repository
 ↓
State
 ↓
UI
```

Os BLoCs não possuem conhecimento direto de:

* Dio;
* Hive;
* ImagePicker;
* Geolocator;
* detalhes HTTP.

---

# Como funciona a fila de sincronização

O aplicativo foi desenvolvido considerando que a conexão de rede pode ser instável durante o trabalho em campo.

Por isso, uma inspeção não depende da disponibilidade imediata da API para ser concluída.

Os estados locais utilizados são:

```text
draft
pending
synced
failed
```

### `draft`

Inspeção ainda em edição.

Não participa da fila de sincronização.

### `pending`

Inspeção concluída e persistida localmente, aguardando envio para o servidor.

### `synced`

Inspeção sincronizada com sucesso.

### `failed`

Inspeção rejeitada pelo servidor ou com dados inválidos detectados durante o envio, exigindo atenção ou nova tentativa manual.

---

## Fluxo de conclusão

Ao concluir uma inspeção:

```text
Usuário conclui
 ↓
validação local
 ↓
persistência no Hive
 ↓
status = pending
 ↓
retorno à lista de OS
 ↓
botão Sincronizar
```

A persistência acontece **antes da requisição HTTP**.

Assim, mesmo sem conexão, o trabalho realizado pelo técnico permanece salvo no dispositivo.

---

## Sincronização com sucesso

```text
pending
 ↓
POST /inspections
 ↓
sucesso
 ↓
serverId
 ↓
synced
 ↓
Hive atualizado
```

---

## Falha de conexão

Em erros de rede:

```text
pending
 ↓
POST /inspections
 ↓
sem conexão / timeout
 ↓
continua pending
```

A inspeção permanece disponível localmente e pode ser sincronizada posteriormente.

---

## Rejeição pelo servidor

Quando a API responde com uma rejeição dos dados:

```text
pending
 ↓
POST /inspections
 ↓
HTTP 4xx (exceto 401)
 ↓
failed
 ↓
syncError persistido
```

O estado `failed` é diferente de uma indisponibilidade temporária de rede.

O HTTP `401` invalida a sessão e interrompe o envio sem marcar a inspeção como `failed` por rejeição de dados. Erros de conexão, timeout e respostas HTTP `5xx` mantêm a inspeção em `pending`.

---

## Sincronização automática

Inspeções `pending` são verificadas automaticamente quando:

* o aplicativo é iniciado;
* uma conexão volta a estar disponível;
* o aplicativo retorna ao estado ativo.

Fluxo:

```text
pending
 ↓
InspectionSyncCoordinator
 ↓
InspectionsRepository
 ↓
POST /inspections
```

O `connectivity_plus` é utilizado apenas como **gatilho para tentar uma nova sincronização**.

Ele não é utilizado como fonte definitiva para afirmar que a API está acessível.

A própria requisição HTTP continua sendo a fonte de verdade.

### Gatilhos simultâneos e controle de concorrência

O `InspectionSyncCoordinator` mantém apenas uma execução automática da fila por vez. O primeiro gatilho inicia a tentativa imediatamente, sem debounce temporal. Se inicialização, retorno da conectividade ou retorno ao foreground ocorrerem durante essa execução, os novos gatilhos são agrupados em uma solicitação de nova passagem, executada após a atual terminar, inclusive se ela terminar com erro.

Cada passagem percorre sequencialmente as inspeções `pending` e interrompe o processamento quando um envio continua `pending`. Uma falha, sozinha, não agenda outra passagem: é necessário um novo gatilho. Gatilhos recebidos durante a passagem seguinte podem solicitar mais uma passagem. Ao parar o coordenador, a solicitação pendente é descartada; o envio em andamento pode terminar.

No `InspectionsRepository`, chamadas simultâneas de `syncInspection()` com o mesmo `clientId` compartilham o mesmo `Future`, incluindo a requisição HTTP e a persistência do resultado. Essa proteção vale tanto para a fila automática quanto para o envio manual. Ela é liberada após sucesso ou erro, permitindo tentativas posteriores. Inspeções diferentes não ficam bloqueadas entre si.

Esses controles ficam em memória e valem por instância; o app cria um único coordenador e compartilha o repositório. As inspeções e seus estados continuam persistidos no Hive, mas os controles não sobrevivem ao encerramento do processo. Evitar duplicidade no servidor após timeout ou encerramento entre o envio e a gravação local ainda depende de idempotência no backend usando o `clientId`.

---

## Sincronização manual geral e retry

Na lista de **Ordens de serviço**, o botão **Sincronizar** envia as inspeções `pending` de todas as OS. Ele fica desabilitado e mostra **Sincronizando...** durante a operação. Ao terminar, uma mensagem informa quantas foram sincronizadas, quantas continuam pendentes e quantas falharam; os detalhes ficam no histórico. Se não houver pendências, isso também é informado.

Concluir uma inspeção valida e salva os dados localmente, depois retorna à lista de OS. A conclusão não dispara uma requisição de sync nem abre uma tela intermediária de envio. O usuário pode continuar trabalhando e tocar em **Sincronizar** quando desejar. Os gatilhos automáticos de conectividade, inicialização e retorno ao foreground continuam ativos.

Inspeções em `pending` participam do fluxo automático.

Inspeções em `failed` não entram em um loop infinito de tentativas.

Nesse caso, o histórico disponibiliza:

```text
Tentar novamente
```

permitindo uma nova tentativa manual.

---

## Idempotência

Cada inspeção recebe um `clientId` gerado localmente com UUID.

Esse identificador permanece o mesmo entre as tentativas:

```text
clientId = A
 ↓
tentativa
 ↓
falha
 ↓
retry
 ↓
clientId = A
```

O `clientId` pode ser utilizado pelo backend como chave de idempotência, reduzindo o risco de registros duplicados em situações como:

* timeout;
* perda de conexão;
* repetição de envio;
* fechamento inesperado do aplicativo.

---

# O que ficou pendente / o que faria com mais tempo

O escopo principal do desafio foi priorizado, especialmente os fluxos de autenticação, ordens de serviço, inspeção, persistência local e sincronização offline-first.

Com mais tempo, as principais evoluções seriam:

* ampliar a cobertura de testes automatizados;
* adicionar integration tests completos do fluxo offline → online;
* adicionar CI com GitHub Actions para `flutter analyze` e `flutter test`;
* implementar política de retry com exponential backoff;
* adicionar telemetria e observabilidade;
* evoluir a persistência para Drift/SQLite caso o volume e os relacionamentos aumentem;
* implementar gerenciamento mais sofisticado de conflitos de sincronização;
* adicionar paginação às ordens de serviço;
* melhorar a configuração de ambientes de desenvolvimento/homologação/produção;
* adicionar internacionalização;
* ampliar testes de acessibilidade;
* adicionar Golden Tests para os principais componentes visuais;
* aplicar otimizações adicionais de compressão e armazenamento de imagens.

Para um cenário de produção, também seria importante incluir monitoramento de falhas, métricas de sincronização e uma política mais completa para conflitos entre dados locais e remotos.

---

# Visão geral

O Orbytis Atlas permite que um técnico de campo:

* realize autenticação;
* consulte ordens de serviço;
* visualize detalhes de uma OS;
* continue acessando ordens previamente carregadas mesmo sem conexão;
* inicie e salve inspeções como rascunho;
* registre observações;
* capture fotos;
* registre localização por GPS;
* conclua inspeções offline;
* acompanhe o estado de sincronização;
* sincronize automaticamente os dados quando a conexão estiver disponível;
* envie as pendências de todas as OS pelo botão **Sincronizar**;
* consulte o histórico de inspeções;
* tente novamente sincronizações rejeitadas pelo servidor.

---

# Identidade visual

## Tela de abertura

Ao iniciar o app, o `StartupApp` exibe a imagem `assets/images/hover_atlas.png`, centralizada sobre fundo preto e com a proporção preservada, sem cortes. A imagem está incluída no aplicativo e não depende de conexão.

A abertura aguarda a inicialização do armazenamento local e das dependências, com duração mínima de 1,2 segundo. Depois, o fluxo de autenticação direciona para o login ou para a lista de OS conforme a sessão. Se a inicialização falhar, uma mensagem orienta fechar e abrir o app novamente.

Essa tela é renderizada pelo Flutter; a tela nativa anterior ao primeiro frame segue o comportamento do Android, com os fundos de lançamento configurados em preto. Para conferir a abertura completa após alterações, encerre e execute o app novamente.

## Referências visuais

A identidade visual do **Orbytis Atlas** foi desenvolvida tomando como referência a própria identidade pública da **Orbytis**, buscando manter coerência entre o aplicativo criado para o desafio e a linguagem visual utilizada pela marca.

A principal referência utilizada foi o projeto de identidade visual publicado no Behance:

[ORBYITIS — Identidade Visual](https://www.behance.net/gallery/239515133/ORBYITIS-Identidade-Visual)

A partir dessa referência, elementos da marca foram adaptados para uma experiência mobile voltada ao trabalho de campo.

Entre os elementos utilizados estão:

* predominância de tons de roxo e azul;
* gradientes baseados na paleta visual da marca;
* formas circulares e elementos gráficos aplicados aos headers;
* superfícies de alto contraste;
* linguagem visual moderna e tecnológica;
* componentes reutilizáveis para preservar consistência entre as telas.

A paleta utilizada pelo aplicativo inclui:

```text
#BBA7FC
#9958FC
#6A53F6
#4247DA
#222D9C
#1D2769
```

Os tokens visuais estão centralizados em:

```text
lib/app/theme/
├── app_colors.dart
├── app_gradients.dart
└── app_theme.dart
```

Também foi criado o componente reutilizável `OrbytisHeader`, mantendo a mesma linguagem visual nas principais telas.

A interface utiliza **Material 3** como base, adaptada à identidade visual e ao contexto de utilização em campo.

Foram priorizados:

* alto contraste;
* legibilidade;
* áreas de toque maiores;
* hierarquia clara de ações;
* feedback visual de carregamento;
* feedback de erro;
* feedback de sincronização;
* estados acompanhados por texto, ícone e cor;
* suporte a temas claro e escuro.

O objetivo foi evitar uma interface genérica de desafio técnico e aproximar o aplicativo de um produto que pudesse integrar o ecossistema visual da Orbytis.

---

# Autenticação

### Logout e proteção de rotas

Na lista de OS, a ação **Sair** abre uma confirmação. Ao confirmar, o app remove o token do armazenamento seguro e atualiza o estado de autenticação, retornando ao login.

O `GoRouter` possui um `redirect` que permite as rotas internas apenas no estado `AuthAuthenticated`. Na inicialização, a sessão é verificada pela presença de um token não vazio no armazenamento seguro. Sem sessão, inclusive ao tentar abrir diretamente uma rota interna, o destino é `/login`. Mudanças de autenticação atualizam o router; respostas HTTP 401 invalidam a sessão. A presença local do token não valida sua expiração antecipadamente.

A autenticação utiliza JWT.

Fluxo:

```text
Login
 ↓
POST /auth/login
 ↓
JWT
 ↓
FlutterSecureStorage
 ↓
Dio Interceptor
 ↓
Authorization: Bearer <token>
```

O token é armazenado utilizando:

```text
flutter_secure_storage
```

em vez de Hive ou armazenamento local não destinado a informações sensíveis.

---

## Sessão expirada

O cliente HTTP trata respostas `401 Unauthorized`.

Fluxo:

```text
401
 ↓
token removido
 ↓
sessão invalidada
 ↓
AuthBloc
 ↓
redirecionamento para login
```

O cache local não é utilizado para mascarar erros de autenticação.

Assim, uma requisição que retorna `401` não é silenciosamente substituída por dados antigos do Hive.

---

# Ordens de Serviço

### Pull-to-refresh e estados da lista

A lista permite **puxar para baixo para atualizar**, inclusive quando está vazia ou possui poucos itens. A ação consulta novamente o repositório e termina ao apresentar dados, estado vazio ou erro. Há indicador de carregamento e botão **Tentar novamente** nas falhas. Em falhas de conexão, o repositório pode apresentar os dados locais previamente carregados.

As ordens são obtidas através da API e persistidas localmente.

Fluxo online:

```text
GET /work-orders
 ↓
API
 ↓
WorkOrdersRepository
 ↓
Hive
 ↓
UI
```

Quando uma listagem completa é recebida, o cache local é atualizado.

---

## Ordens de Serviço offline

Quando existe falha de conexão:

```text
GET /work-orders
 ↓
erro de conexão
 ↓
WorkOrdersRepository
 ↓
Hive
 ↓
UI
```

Ordens previamente carregadas continuam disponíveis.

O mesmo princípio é aplicado aos detalhes:

```text
GET /work-orders/:id
 ↓
sem conexão
 ↓
cache local pelo id
 ↓
detalhes da OS
```

Erros de autenticação não utilizam fallback local.

---

# Rascunhos e autosave

Uma inspeção iniciada é persistida inicialmente como:

```text
draft
```

Se o usuário retornar posteriormente à mesma OS, o rascunho existente é recuperado em vez de criar automaticamente uma nova inspeção.

---

## Autosave

A observação utiliza autosave com debounce:

```text
Usuário digita
 ↓
unsaved
 ↓
debounce
 ↓
saving
 ↓
Hive
 ↓
saved
```

Isso reduz operações excessivas de escrita durante a digitação.

Também existe a ação:

```text
Salvar rascunho
```

para salvar explicitamente o rascunho e continuar editando. Esse botão complementa o autosave e não exige os dados obrigatórios de uma conclusão. **Salvar e sair** persiste e retorna à tela anterior. **Concluir inspeção** é uma ação separada, que valida os campos, altera o status para `pending` e retorna à lista de OS.

---

# Fotos

As fotos são capturadas utilizando `image_picker`.

Como a imagem retornada pela câmera pode estar inicialmente em um diretório temporário, ela é copiada para uma localização permanente da aplicação:

```text
application documents/
└── inspection_photos/
```

O Hive armazena o caminho local da imagem.

Isso evita depender do cache temporário do sistema operacional.

---

# Localização

A localização é obtida utilizando `geolocator`.

O fluxo trata:

* serviço de localização desabilitado;
* permissão atual;
* solicitação de permissão;
* permissão negada;
* permissão permanentemente negada.

Latitude e longitude são persistidas junto à inspeção.

---

# Validação da inspeção

Antes de sair de `draft`, a inspeção passa por validações locais.

Entre os dados obrigatórios estão:

* observação válida;
* foto registrada;
* latitude;
* longitude.

Quando válida:

```text
draft
 ↓
pending
```

Somente depois ela entra na fila de sincronização.

---

# Histórico de inspeções

O histórico utiliza os dados persistidos localmente e continua disponível offline.

Os estados são representados utilizando texto e ícone, evitando depender apenas de cores:

```text
✎ Rascunho
⏳ Aguardando sincronização
✓ Sincronizada
⚠ Falha na sincronização
```

Filtros:

* Todas;
* Rascunhos;
* Pendentes;
* Sincronizadas;
* Falhas.

Inspeções em estado `failed` permitem uma nova tentativa manual.

O histórico recarrega os dados ao abrir a tela, trocar o filtro, puxar para atualizar uma lista não vazia ou terminar um retry manual. Ele não observa automaticamente as gravações do sync em segundo plano; se já estiver aberto, atualize a lista para consultar os novos estados.

---

# Persistência local

Foi utilizado **Hive CE**.

Os objetos são serializados como JSON e armazenados em `Box<String>`.

Essa decisão mantém a persistência simples para o escopo do desafio e evita geração adicional de adapters.

Os dados locais incluem principalmente:

* cache das ordens de serviço;
* inspeções;
* status de sincronização;
* erros de sincronização;
* caminhos das fotos;
* coordenadas;
* identificadores locais e remotos.

Informações sensíveis de autenticação não são armazenadas no Hive.

---

# Tratamento de erros

Erros de infraestrutura são convertidos antes de chegar à apresentação.

Exemplo:

```text
DioException
 ↓
NetworkException
 ↓
Repository
 ↓
Exception da feature
 ↓
BLoC
 ↓
State
```

Isso evita que widgets e BLoCs dependam diretamente do Dio.

São diferenciados cenários como:

* timeout;
* falha de conexão;
* `401 Unauthorized`;
* respostas inválidas;
* rejeições de validação pelo servidor.

---

# Testes

Os testes automatizados foram concentrados principalmente nas regras críticas relacionadas a persistência, comportamento offline e sincronização.

Execute:

```bash
flutter test
```

---

## `InspectionsRepository`

Os testes de concorrência verificam que envio automático e manual compartilham uma única operação até a persistência local terminar, e que uma exceção libera a operação para uma tentativa posterior.

Entre os cenários validados:

```text
pending + sucesso
→ synced
```

```text
serverId retornado
→ persistido localmente
```

```text
retry
→ preserva clientId
```

```text
erro de conexão
→ permanece pending
```

```text
HTTP 400
→ failed
```

```text
draft
→ não é enviado
```

```text
synced
→ não é enviado novamente
```

---

## `InspectionBloc`

São validados comportamentos como:

* carregamento de rascunho;
* alteração de observação;
* autosave;
* estados `unsaved`, `saving` e `saved`;
* conclusão válida;
* transição `draft → pending`;
* bloqueio de conclusão quando dados obrigatórios estão ausentes.

---

## `WorkOrdersRepository`

Entre os cenários testados estão:

```text
API disponível
→ dados remotos
→ cache atualizado
```

```text
API indisponível
→ fallback para Hive
```

```text
detalhes offline
→ busca pelo id no cache
```

```text
401
→ não utiliza fallback local
```

---

## Widget Tests

Os testes de widget validam componentes e representações importantes da interface, incluindo estados relacionados à sincronização.

Também são verificados o retorno à lista de OS após concluir sem iniciar upload, o término do pull-to-refresh com lista vazia inalterada e o acesso ao botão geral **Sincronizar**. Os testes do `InspectionQueueCubit` cobrem sucesso, ausência de pendências, falha de conexão, rejeição do servidor e bloqueio de cliques repetidos durante o envio.

Os testes do `InspectionSyncCoordinator` cobrem gatilhos simultâneos, passagem adicional após erro, parada do coordenador e ausência de retries sem novos gatilhos.

---

# Testando manualmente o fluxo offline → online

Em um dispositivo físico conectado via ADB:

1. inicie a API;
2. execute:

```bash
adb reverse tcp:3000 tcp:3000
```

3. realize login;
4. carregue as ordens de serviço;
5. remova o redirecionamento:

```bash
adb reverse --remove tcp:3000
```

6. confirme que as ordens previamente carregadas continuam disponíveis;
7. abra os detalhes de uma OS;
8. inicie uma inspeção;
9. preencha a observação;
10. registre uma foto;
11. registre a localização;
12. conclua a inspeção;
13. confirme o retorno à lista de OS e consulte no histórico se ela permanece em `pending`;
14. restaure o acesso à API:

```bash
adb reverse tcp:3000 tcp:3000
```

15. retorne ao aplicativo;
16. confirme a sincronização automática;
17. verifique o estado `synced` no histórico.

Esse fluxo valida manualmente o principal cenário offline-first proposto pelo desafio.

Restaurar o `adb reverse` não gera, por si só, um evento de conectividade no Android. Para testar o gatilho automático nesse cenário, coloque o app em segundo plano e retorne ao foreground.

## Testando o botão Sincronizar

1. Com a API inacessível, conclua uma inspeção e confirme o retorno à lista de OS.
2. Toque em **Sincronizar** e confirme que a mensagem informa a pendência, sem indicar sucesso para esse item.
3. Restaure o acesso à API pelo terminal, mantendo o app aberto na lista de OS, sem alternar seu estado de foreground.
4. Toque em **Sincronizar** e confira o estado **Sincronizando...**, seguido do resumo do resultado.
5. Abra o histórico e confirme o estado `synced`.
6. Sem novas pendências, toque em **Sincronizar** novamente e confira a mensagem de ausência de inspeções pendentes.

Se um gatilho automático já tiver enviado a inspeção antes do clique, a ausência de pendências é o resultado esperado. Itens `failed` são reenviados pela ação **Tentar novamente** no histórico.

---

# Análise estática

Execute:

```bash
flutter analyze
```

O projeto utiliza análise mais estrita, incluindo regras como:

* `strict-casts`;
* `strict-inference`;
* `strict-raw-types`;
* `prefer_const_constructors`;
* `prefer_const_declarations`;
* `always_declare_return_types`;
* `avoid_print`;
* `close_sinks`;
* `prefer_final_locals`.

---

# Formatação

```bash
dart format lib test
```

---

# Decisões técnicas

## Por que BLoC?

O BLoC torna explícitas as transições de estado e separa eventos da interface das regras executadas pela aplicação.

Também facilita testes sem depender diretamente da árvore de widgets.

---

## Por que Hive?

O desafio exige persistência local e comportamento offline.

Hive fornece uma solução simples e adequada ao volume de dados do projeto, sem exigir banco relacional ou migrations mais complexas.

Caso os relacionamentos e o volume de dados aumentassem, uma evolução possível seria Drift/SQLite.

---

## Por que FlutterSecureStorage?

O JWT é uma informação sensível e não deve ser armazenado junto aos demais dados da aplicação.

Por isso, é utilizado armazenamento seguro disponibilizado pelo sistema operacional.

---

## Por que salvar localmente antes de sincronizar?

A aplicação é voltada ao trabalho de campo, onde a conectividade não pode ser considerada confiável.

A estratégia adotada é:

```text
salvar trabalho
→ continuar operação
→ sincronizar posteriormente
```

em vez de:

```text
sem internet
→ bloquear usuário
```

---

## Por que `clientId`?

O identificador local permite que a mesma inspeção seja reenviada sem que cada tentativa represente conceitualmente uma nova inspeção.

Isso é importante em cenários com:

* timeout;
* perda de conexão;
* retries;
* encerramento inesperado do aplicativo.

---

## Por que `connectivity_plus` não determina se a API está online?

Ter Wi-Fi ou dados móveis disponíveis não significa necessariamente possuir acesso ao servidor.

Por isso, `connectivity_plus` é utilizado como gatilho para uma tentativa.

A resposta HTTP continua sendo a fonte de verdade.

---

# Validação final

Antes da entrega:

```bash
dart format lib test
flutter analyze
flutter test
```

Fluxo principal esperado:

```text
Tela de abertura
 ↓
Login
 ↓
Ordens de Serviço
 ↓
Detalhe
 ↓
Inspeção
 ↓
Rascunho
 ↓
Foto + GPS
 ↓
Conclusão
 ↓
Pending
 ↓
Retorno à lista de OS
 ↓
Sincronizar (ou gatilho automático)
 ↓
Synced
 ↓
Histórico
```

---

## Autor

**Adam Dias**

Projeto desenvolvido como desafio técnico utilizando Flutter e Dart.
