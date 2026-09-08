# Orbytis Atlas

![Preview do projeto](https://i.imgur.com/f8JGy3W.png)

> Aplicativo mobile desenvolvido em Flutter para gerenciamento de **Ordens de Serviço e Inspeções em campo**, com suporte a operação offline, persistência local e sincronização automática com uma API. O projeto foi desenvolvido como desafio técnico para uma vaga de **Desenvolvedor Mobile Flutter**.

---
## Tecnologias

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![flutter_bloc](https://img.shields.io/badge/flutter__bloc-5A45FF?style=for-the-badge&logo=bloc&logoColor=white)
![Dio](https://img.shields.io/badge/Dio-5A64D8?style=for-the-badge&logo=dart&logoColor=white)
![Hive CE](https://img.shields.io/badge/Hive%20CE-FFCA28?style=for-the-badge&logo=dart&logoColor=black)
![flutter_secure_storage](https://img.shields.io/badge/flutter__secure__storage-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![GoRouter](https://img.shields.io/badge/GoRouter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Geolocator](https://img.shields.io/badge/Geolocator-4285F4?style=for-the-badge&logo=googlemaps&logoColor=white)
![ImagePicker](https://img.shields.io/badge/ImagePicker-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![connectivity_plus](https://img.shields.io/badge/connectivity__plus-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![UUID](https://img.shields.io/badge/UUID-6A53F6?style=for-the-badge&logo=dart&logoColor=white)
![Mocktail](https://img.shields.io/badge/Mocktail-E91E63?style=for-the-badge&logo=dart&logoColor=white)
![bloc_test](https://img.shields.io/badge/bloc__test-5A45FF?style=for-the-badge&logo=bloc&logoColor=white)
---

## Visão geral

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
* consulte o histórico de inspeções;
* tente novamente sincronizações rejeitadas pelo servidor.

---

# Arquitetura

O projeto utiliza uma organização baseada em **features**, com responsabilidades separadas entre apresentação, regras de coordenação de dados e infraestrutura.

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

A camada de apresentação não acessa diretamente Dio, Hive, ImagePicker ou Geolocator.

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

Exemplo:

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

Os contratos são definidos utilizando `abstract interface class`, enquanto as implementações concretas permanecem `final`.

Exemplo:

```dart
abstract interface class InspectionsRemoteDataSource {
  Future<String> submitInspection(
    Inspection inspection,
  );
}

final class InspectionsRemoteDataSourceImpl
    implements InspectionsRemoteDataSource {
  // implementação com Dio
}
```

Essa abordagem reduz o acoplamento das regras da aplicação com tecnologias específicas e facilita a substituição das implementações e a criação de testes automatizados.

---

# Clean Architecture e SOLID

O projeto busca aplicar princípios de Clean Architecture sem introduzir complexidade desnecessária para o escopo da aplicação.

Um dos princípios utilizados é o **Dependency Inversion Principle**.

Os repositories dependem de abstrações:

```text
Repository
   ↓
Interface
   ↑
Implementação
```

e não diretamente de detalhes de infraestrutura:

```text
Repository
   ✕
Hive / Dio / Geolocator / ImagePicker
```

O `main.dart` funciona como **Composition Root**, sendo responsável por construir e conectar as implementações concretas:

```text
main.dart
 ↓
cria implementações
 ↓
injeta nos repositories
 ↓
injeta nos BLoCs
```

Isso mantém os detalhes de infraestrutura fora das regras de coordenação da aplicação.

---

# Gerenciamento de estado

Foi utilizado `flutter_bloc`.

Exemplo de fluxo:

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

Os BLoCs não conhecem detalhes de:

* requisições HTTP;
* Dio;
* Hive;
* ImagePicker;
* Geolocator.

Eles trabalham apenas com os repositories e os estados necessários para a interface.

---

# Autenticação

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

O token não é armazenado em Hive ou SharedPreferences.

Foi utilizado:

```text
flutter_secure_storage
```

para armazenar informações sensíveis da sessão.

---

## Sessão expirada

O cliente HTTP trata respostas `401 Unauthorized`.

Quando isso ocorre:

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

Por exemplo, uma tentativa de carregar uma OS que resulte em `401` não retorna silenciosamente dados antigos do Hive.

---

# Ordens de Serviço

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

O retorno remoto é utilizado para atualizar o cache local.

---

## Ordens de Serviço offline

Quando ocorre uma falha de conexão:

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

Assim, ordens previamente carregadas continuam disponíveis offline.

O mesmo comportamento é utilizado na tela de detalhes:

```text
GET /work-orders/:id
 ↓
sem conexão
 ↓
cache local pelo id
 ↓
detalhe da OS
```

Falhas de autenticação não utilizam esse fallback.

---

# Inspeções

Uma inspeção possui estados locais de sincronização:

```text
draft
pending
synced
failed
```

### `draft`

Inspeção ainda em edição.

Não deve ser enviada para a API.

### `pending`

Inspeção concluída e persistida localmente, aguardando sincronização.

### `synced`

Inspeção aceita e armazenada pelo servidor.

### `failed`

O servidor recebeu a requisição, mas rejeitou a inspeção por algum erro que exige atenção ou nova tentativa manual.

---

# Estratégia Offline-First

Uma das principais decisões do projeto foi tratar a persistência local como parte do fluxo principal da aplicação, e não apenas como fallback.

Ao concluir uma inspeção:

```text
Usuário conclui
 ↓
validação local
 ↓
Hive
 ↓
status = pending
 ↓
tentativa de sincronização
```

A inspeção é persistida **antes** da tentativa de comunicação com a API.

Isso permite que o técnico continue trabalhando mesmo quando estiver sem conexão.

---

## Fluxo de sincronização

```text
Inspeção concluída
 ↓
pending
 ↓
POST /inspections
 ↓
┌───────────────────────────┐
│                           │
sucesso                 erro de conexão
│                           │
synced                    pending
│                           │
serverId                aguarda rede
```

Se a API rejeitar os dados:

```text
POST /inspections
 ↓
HTTP 4xx
 ↓
failed
 ↓
syncError
```

O erro é persistido para que possa ser exibido posteriormente ao usuário.

---

# Idempotência

Cada inspeção recebe um:

```text
clientId
```

gerado localmente através de UUID.

Esse identificador não muda entre tentativas de sincronização.

Exemplo:

```text
clientId = A
 ↓
tentativa 1
 ↓
falha de rede
 ↓
retry
 ↓
clientId = A
```

O mesmo identificador é reutilizado em todas as tentativas.

Isso permite que o backend utilize o `clientId` como chave de idempotência e reduz o risco de criação de registros duplicados em cenários como:

* perda de conexão;
* timeout;
* fechamento inesperado do aplicativo;
* retry da mesma inspeção.

---

# Sincronização automática

A sincronização não depende de um botão manual para o fluxo normal.

Inspeções `pending` são verificadas automaticamente quando:

* o aplicativo é iniciado;
* uma conexão de rede volta a ficar disponível;
* o aplicativo retorna ao estado ativo.

Fluxo:

```text
pending
 ↓
rede disponível
 ↓
InspectionSyncCoordinator
 ↓
InspectionsRepository
 ↓
POST /inspections
```

Foi utilizado `connectivity_plus` como um **gatilho para tentar sincronizar**, mas ele não é considerado fonte definitiva para determinar se a API está acessível.

A confirmação real vem da própria requisição HTTP.

Isso evita assumir que possuir Wi-Fi ou rede móvel significa necessariamente possuir acesso ao servidor.

---

## Diferença entre `pending` e `failed`

O projeto diferencia falhas de conectividade de rejeições do servidor.

### Problema de rede

```text
pending
```

A aplicação tenta novamente automaticamente.

### Rejeição da API

```text
failed
```

A inspeção não entra em um loop infinito de tentativas automáticas.

O usuário pode utilizar a ação:

```text
Tentar novamente
```

no histórico.

---

# Rascunhos e autosave

Uma inspeção iniciada é persistida como:

```text
draft
```

Se o usuário voltar posteriormente para a mesma OS, o rascunho existente é recuperado em vez de criar automaticamente uma nova inspeção.

---

## Autosave

A observação utiliza autosave com debounce.

Fluxo simplificado:

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

Isso reduz operações excessivas de escrita sem exigir que o usuário pressione um botão a cada alteração.

A interface também possui a ação:

```text
Salvar e sair
```

para garantir a persistência antes de deixar a inspeção.

---

# Fotos

As fotos são capturadas utilizando:

```text
image_picker
```

A imagem retornada pela câmera pode inicialmente estar em uma localização temporária.

Por isso, o arquivo é copiado para o diretório permanente da aplicação:

```text
application documents/
└── inspection_photos/
```

O Hive armazena apenas o caminho local da imagem.

Isso evita depender do cache temporário do sistema operacional.

---

# Localização

A localização é obtida através do:

```text
geolocator
```

O fluxo verifica:

* serviço de localização;
* permissão atual;
* solicitação de permissão;
* permissão negada;
* permissão permanentemente negada.

As coordenadas são persistidas junto à inspeção.

---

# Validação para conclusão

Antes de uma inspeção sair de `draft`, são validados os dados obrigatórios.

Entre as validações estão:

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

Somente então ela entra na fila de sincronização.

---

# Histórico de inspeções

O histórico utiliza os dados persistidos localmente.

Por isso, também pode ser consultado offline.

Os estados são apresentados com texto e ícone, evitando depender apenas de cores:

```text
✎ Rascunho
⏳ Aguardando sincronização
✓ Sincronizada
⚠ Falha na sincronização
```

Filtros disponíveis:

* Todas
* Rascunhos
* Pendentes
* Sincronizadas
* Falhas

Inspeções em estado `failed` permitem nova tentativa manual.

---

# Persistência local

Foi utilizado:

```text
Hive CE
```

Os objetos são serializados como JSON e armazenados em `Box<String>`.

Essa decisão evita geração adicional de adapters para o escopo do desafio e mantém a persistência simples.

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

Erros de infraestrutura são convertidos antes de chegar à camada de apresentação.

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

Isso evita que BLoCs e widgets dependam diretamente do Dio.

São diferenciados cenários como:

* timeout;
* erro de conexão;
* `401 Unauthorized`;
* respostas inválidas;
* erros de validação do servidor.

---

# Interface

A aplicação utiliza Material 3 e identidade visual própria do Orbytis Atlas.

Foram priorizados aspectos importantes para uso em campo:

* contraste;
* textos legíveis;
* áreas de toque maiores;
* ações principais visíveis;
* feedback de carregamento;
* feedback de erro;
* identificação textual dos estados;
* suporte a tema claro e escuro.

---

# Testes

O projeto possui testes automatizados focados principalmente nas regras críticas do fluxo offline e de sincronização.

Para executar:

```bash
flutter test
```

---

## Testes do `InspectionsRepository`

Entre os cenários testados:

```text
pending + sucesso
→ synced
```

```text
serverId retornado pela API
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
→ não é enviado para API
```

```text
synced
→ não é enviado novamente
```

---

## Testes do `InspectionBloc`

São validados cenários como:

* carregamento do rascunho;
* alteração da observação;
* autosave;
* estados `unsaved`, `saving` e `saved`;
* conclusão válida;
* transição `draft → pending`;
* bloqueio de conclusão de inspeção incompleta.

---

## Testes do `WorkOrdersRepository`

São validados:

```text
API disponível
→ dados remotos
→ atualização do cache
```

```text
API indisponível
→ dados do Hive
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

## Widget tests

Também são utilizados testes de widgets para validar a representação visual dos estados importantes da aplicação, como os estados de sincronização no histórico.

---

# Como executar

## Pré-requisitos

Tenha instalado:

* Flutter
* Dart
* Android SDK
* Node.js
* dispositivo Android ou emulador

Verifique o ambiente:

```bash
flutter doctor
```

Instale as dependências:

```bash
flutter pub get
```

---

API Mock

A API mock utilizada pelo aplicativo faz parte dos materiais oficiais fornecidos para o desafio técnico.

O pacote original do desafio, contendo a API mock, contrato da API e demais arquivos de apoio, foi disponibilizado pela empresa através do seguinte link:
[
Materiais oficiais do Desafio Flutter](https://engeselt-my.sharepoint.com/personal/demesio_oliveira_engeselt_onmicrosoft_com/_layouts/15/onedrive.aspx?id=%2Fpersonal%2Fdemesio%5Foliveira%5Fengeselt%5Fonmicrosoft%5Fcom%2FDocuments%2FDesafio%20Flutter%2Fdesafio%2Dflutter%2Ezip&parent=%2Fpersonal%2Fdemesio%5Foliveira%5Fengeselt%5Fonmicrosoft%5Fcom%2FDocuments%2FDesafio%20Flutter&ga=1&LOF=1)

A API mock não foi desenvolvida como parte deste aplicativo. Ela foi fornecida pela empresa exclusivamente como suporte para desenvolvimento e validação do desafio técnico.

Executando a API mock

Após baixar e extrair o pacote fornecido pela empresa, acesse o diretório da API:

cd mock-api

Instale as dependências:

npm install

Inicie o servidor:

npm run start

Por padrão, a API será disponibilizada em:

http://localhost:3000
Android Emulator

No Android Emulator, utilize:

http://10.0.2.2:3000

pois localhost dentro do emulador referencia o próprio dispositivo virtual.

Dispositivo Android físico

Para desenvolvimento utilizando um dispositivo Android conectado via USB, é possível redirecionar a porta da máquina para o dispositivo:

adb reverse tcp:3000 tcp:3000

Nesse cenário, o aplicativo pode utilizar:

http://localhost:3000

Para remover o redirecionamento:

adb reverse --remove tcp:3000

Esse comando também pode ser utilizado durante a validação do comportamento offline da aplicação.

---

# Testando o comportamento offline

Uma forma de validar o fluxo em dispositivo físico é:

1. iniciar a API;
2. executar `adb reverse tcp:3000 tcp:3000`;
3. realizar login;
4. carregar as ordens de serviço;
5. remover o reverse:

```bash
adb reverse --remove tcp:3000
```

6. confirmar que as ordens previamente carregadas continuam disponíveis;
7. abrir o detalhe de uma OS;
8. criar uma inspeção;
9. preencher observação;
10. registrar foto;
11. registrar localização;
12. concluir a inspeção;
13. confirmar que o estado permanece `pending`;
14. restaurar a comunicação:

```bash
adb reverse tcp:3000 tcp:3000
```

15. retornar ao aplicativo;
16. confirmar a sincronização automática;
17. verificar o estado `synced` no histórico.

---

# Análise estática

Para executar o analyzer:

```bash
flutter analyze
```

O projeto utiliza regras adicionais de lint e análise mais estrita, incluindo:

* `strict-casts`
* `strict-inference`
* `strict-raw-types`
* `prefer_const_constructors`
* `prefer_const_declarations`
* `always_declare_return_types`
* `avoid_print`
* `close_sinks`
* `prefer_final_locals`

---

# Formatação

Para formatar o código:

```bash
dart format lib test
```

---

# Decisões técnicas

## Por que BLoC?

Foi escolhido para tornar explícitas as transições de estado e separar eventos da interface das regras executadas pela aplicação.

Também facilita testes de estados sem depender diretamente da UI.

---

## Por que Hive?

O escopo exige persistência local e funcionamento offline.

Hive fornece uma solução simples e adequada para o volume de dados da aplicação, sem exigir banco relacional ou migrations complexas.

Para uma aplicação de produção com relacionamentos mais complexos e grande volume de dados, uma evolução possível seria utilizar SQLite ou Drift.

---

## Por que FlutterSecureStorage?

O token JWT é uma informação sensível e não deve ser salvo junto aos demais dados da aplicação.

Por isso, ele é armazenado utilizando mecanismos seguros fornecidos pelo sistema operacional.

---

## Por que sincronizar depois de salvar localmente?

Porque a rede não pode ser considerada confiável em um aplicativo destinado a trabalho de campo.

Persistir primeiro permite:

```text
salvar trabalho
→ continuar operação
→ sincronizar posteriormente
```

em vez de:

```text
sem internet
→ usuário bloqueado
```

---

## Por que `clientId`?

Para permitir que a mesma inspeção possa ser reenviada sem que cada tentativa represente conceitualmente uma nova inspeção.

Isso é especialmente importante em cenários com timeout, perda de conexão ou retry.

---

## Por que `connectivity_plus` não decide se a API está online?

Porque uma conexão Wi-Fi ou móvel não garante acesso ao servidor.

Por isso, o estado de conectividade é utilizado apenas como gatilho para uma nova tentativa.

A resposta HTTP continua sendo a fonte de verdade.

---

# Possíveis evoluções

Com mais tempo, algumas evoluções possíveis seriam:

* maior cobertura de testes;
* integration tests completos;
* CI com GitHub Actions;
* banco relacional com Drift/SQLite para cenários mais complexos;
* política de retry com backoff;
* telemetria e observabilidade;
* compressão/configuração avançada de imagens;
* melhor gerenciamento de conflitos de sincronização;
* paginação de ordens de serviço;
* abstração de configuração por ambiente;
* internacionalização;
* acessibilidade automatizada;
* testes Golden para componentes visuais.

---

# Validação final

Antes da entrega, podem ser executados:

```bash
dart format lib test
flutter analyze
flutter test
```

E então validar manualmente o fluxo:

```text
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
Sincronização
 ↓
Synced
 ↓
Histórico
```

---

## Autor

**Adam Dias**

Projeto desenvolvido como desafio técnico utilizando Flutter e Dart.
