# Política de Versionamento (Semantic Versioning)

Este projeto adota as regras de **Versionamento Semântico (SemVer)** para controle de versões.

O formato básico do número da versão é:
`MAIOR.MENOR.CORREÇÃO` (ou `MAJOR.MINOR.PATCH`)

## Regras de Incremento

### 1. Correções e Ajustes Mínimos (`+0.0.1`)
O número de **Correção** (Patch) deve ser incrementado ao realizar:
- Correções de bugs (bug fixes).
- Correções de digitação (typos).
- Atualizações mínimas ou melhorias internas invisíveis ao usuário final.
- Atualização ou bump de dependências.

*Exemplo:* `1.1.1` -> `1.1.2`

### 2. Implementação de Feature (`+0.1.0`)
O número **Menor** (Minor) deve ser incrementado ao realizar:
- Lançamento de novas funcionalidades ou novos modos de jogo.
- Adições significativas à interface visual (novas telas, animações de branding).
- Refatorações de arquitetura que não quebrem compatibilidade.
- *Nota:* Ao incrementar o número Menor, o número de Correção deve retornar a `0`.

*Exemplo:* `1.1.2` -> `1.2.0`

### 3. Alterações Incompatíveis / Breaking Changes (`+1.0.0`)
O número **Maior** (Major) deve ser incrementado quando houver:
- Mudanças que quebram a compatibilidade ou o funcionamento para instalações anteriores.
- Reformulações completas da dinâmica do aplicativo.
- Alterações drásticas de contratos da API que impeçam o funcionamento do app antigo sem atualização.
- *Nota:* Ao incrementar o número Maior, os números Menor e Correção devem retornar a `0`.

*Exemplo:* `1.2.3` -> `2.0.0`

---

## Como Atualizar no Aplicativo (Flutter)

A versão do aplicativo é gerenciada centralizadamente no arquivo [pubspec.yaml](pubspec.yaml):

```yaml
version: 1.1.2
```

O aplicativo recupera dinamicamente esse metadado em tempo de execução via `package_info_plus` e o exibe no rodapé/telas pertinentes.
Ao atualizar a versão, lembre-se de rodar:
```bash
flutter pub get
```
