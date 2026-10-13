# knoten

[English](README.md) | [Português (BR)](README.pt-BR.md)

![iOS](https://img.shields.io/badge/iOS-18%2B-black.svg)
![Swift](https://img.shields.io/badge/swift-6-orange.svg)
![License](https://img.shields.io/badge/license-MPL--2.0-blue.svg)

Um cliente iOS nativo para o [Tangled](https://tangled.org), a plataforma de
social coding construída sobre o AT Protocol.

O Knoten é uma app view própria. Ele fala com qualquer PDS e qualquer knot, não
depende do cliente do Tangled e não usa a marca deles. Mesma ideia dos clientes
alternativos do Bluesky: o protocolo é a plataforma, o app é uma forma de
entrar nela.

O login é OAuth do atproto: PAR, PKCE e DPoP, sem app password. A sessão é
vinculada ao DPoP, então as requisições carregam uma prova assinada em vez de um
bearer token, e a rotação de nonce é resolvida por baixo. Tudo retorna erro
tipado, nada lança exceção através de uma fronteira onde não deveria.

## Compilar

Precisa do Xcode 27 (Swift 6.4, SDK do iOS 27) e do XcodeGen.

```bash
brew install xcodegen

cd KnotenCore && swift test        # core do protocolo, sem UI
cd ../App && xcodegen generate     # gera Knoten.xcodeproj
open Knoten.xcodeproj
```

O projeto do Xcode é gerado, não versionado. O `project.yml` é a fonte da
verdade. Os produtos do StoreKit ficam em `App/StoreKit/Knoten.storekit`, então
o fluxo de compra funciona no simulador sem App Store Connect.

## Estrutura

```
KnotenCore/    core do protocolo: DPoP, PKCE, OAuth, identidade, XRPC
App/           app SwiftUI, um alvo
web/           metadata de cliente publicada para o OAuth
docs/          notas de design
```

O `KnotenCore` não depende de UI de propósito. Ele compila e testa sozinho, e é
isso que faz um port futuro ser um port e não uma reescrita.

## Estado

O 0.1.0 está em andamento. Somente leitura: feed, repositórios, pull requests,
inbox, mais a compra do Pro e o tip jar. Push, widgets e multi-conta vêm depois
que o relay de notificações existir. O escopo completo e os riscos abertos
estão em [docs/DESIGN.md](docs/DESIGN.md).

## Contribuindo

Faça fork, crie um branch, escreva testes, rode `swift test` e abra um PR.
Mantenha o `KnotenCore` sem imports de UI e os tipos de wire em um só lugar.

## Licença

[MPL-2.0](LICENSE). Use, faça fork, publique. Mudanças nos arquivos que a gente
escreveu voltam sob a mesma licença; o que você construir ao lado é seu.
