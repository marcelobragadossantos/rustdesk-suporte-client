# Suporte Hiperfarma — fork branded do RustDesk

Este é um **fork** de [`rustdesk/rustdesk`](https://github.com/rustdesk/rustdesk)
(licença **AGPL-3.0**) usado para gerar o cliente de suporte remoto **"Suporte Hiperfarma"**
das lojas Hiperfarma, com **servidor + chave pública embutidos** (o técnico/loja não digita
endereço de servidor).

> **AGPL-3.0:** mantemos este fork público, preservamos créditos/licença do RustDesk e
> disponibilizamos o fonte das nossas modificações. As mudanças vivem na branch
> `suporte-hiperfarma` e estão listadas abaixo.

## O que muda em relação ao upstream

1. **`ci/customize-suporte.sh`** — injeta, em tempo de build, no submódulo
   `libs/hbb_common/src/config.rs`:
   - `RENDEZVOUS_SERVERS` → host do nosso ID/relay (hbbs/hbbr).
   - `RS_PUB_KEY` → nossa chave pública Ed25519.
   O submódulo continua apontando pro upstream — nada é forkado nele; a config é injetada
   no checkout do CI.
2. **`.github/workflows/build-suporte-windows.yml`** — workflow `workflow_dispatch` que
   builda só Windows x64 (reusa os jobs `bridge.yml` e `third-party-RustDeskTempTopMostWindow.yml`
   do upstream), roda a customização e sobe o `.msi`/`.exe` como artifact. Não assina nem
   publica release (assinatura é passo posterior).

## Como gerar um build

GitHub → Actions → **Build Suporte Hiperfarma (Windows)** → *Run workflow*, informando:
- `rendezvous_server`: host do servidor (default = servidor **local** de teste; em produção,
  o host da VPS).
- `rs_pub_key`: a chave pública (`data/id_ed25519.pub` do servidor).
- `product_name`: nome de exibição (default "Suporte Hiperfarma").

O artifact `SuporteHiperfarma-windows-x86_64` traz o `.msi` (usado pelo
`deploy/install-silent.ps1` do repo de infra) e o `.exe` portável.

## Pendente (branding visual)

A injeção de **servidor + chave** está pronta. O branding **visual pesado** (ícone, logo,
strings "RustDesk"→"Suporte Hiperfarma" na UI) envolve assets binários e edições em
`flutter/` + `res/` — entra como commits adicionais nesta branch:
- ícone: `flutter/windows/runner/resources/app_icon.ico`
- nome/strings: `flutter/lib/...`, `res/` (manifest/instalador)

## Status

- [x] Embedding de servidor + chave (config injection no CI)
- [x] Workflow de build Windows (estrutura do upstream + customização)
- [ ] **Primeiro build verde** (validação do pipeline — pode exigir ajuste de versões)
- [ ] Branding visual (ícone/logo/strings)
- [ ] Assinatura de código (cert) + release
