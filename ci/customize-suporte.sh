#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Customização do cliente "Suporte Hiperfarma" (fork AGPL de rustdesk/rustdesk).
# Roda em CI, APÓS o checkout com submódulos e ANTES do build.
#
# Injeta servidor + chave EMBUTIDOS nas constantes do submódulo hbb_common
# (libs/hbb_common/src/config.rs) e ajusta o nome do produto.
#
# Variáveis de ambiente (passadas pelo workflow, com default local de teste):
#   RENDEZVOUS_SERVER  host do ID/relay (ex.: 10.160.200.183 local; host da VPS em prod)
#   RS_PUB_KEY         chave pública Ed25519 (conteúdo de data/id_ed25519.pub)
#   APP_PRODUCT_NAME   nome de exibição (default "Suporte Hiperfarma")
# ---------------------------------------------------------------------------
set -euo pipefail

RENDEZVOUS_SERVER="${RENDEZVOUS_SERVER:-10.160.200.183}"
RS_PUB_KEY="${RS_PUB_KEY:-ijUj5Cq3LrVdV8Q3tgeByteOmf4VrhQSktdW1Bep8dc=}"
APP_PRODUCT_NAME="${APP_PRODUCT_NAME:-Suporte Hiperfarma}"

CFG="libs/hbb_common/src/config.rs"
[ -f "$CFG" ] || { echo "ERRO: $CFG não encontrado (checkout com submódulos?)"; exit 1; }

echo ">> Injetando servidor: $RENDEZVOUS_SERVER"
# RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];
sed -i -E "s|pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[\"[^\"]*\"\];|pub const RENDEZVOUS_SERVERS: \&[\&str] = \&[\"${RENDEZVOUS_SERVER}\"];|" "$CFG"

echo ">> Injetando chave pública"
# RS_PUB_KEY: &str = "....";  (a chave tem +,/,= → escapamos com | como delimitador do sed)
ESC_KEY=$(printf '%s' "$RS_PUB_KEY" | sed -e 's/[&|\\]/\\&/g')
sed -i -E "s|pub const RS_PUB_KEY: &str = \"[^\"]*\";|pub const RS_PUB_KEY: \&str = \"${ESC_KEY}\";|" "$CFG"

echo ">> Conferência das constantes resultantes:"
grep -E 'pub const (RENDEZVOUS_SERVERS|RS_PUB_KEY)' "$CFG"

# --- Branding leve do nome de produto (Windows) ---------------------------
# O nome de exibição/empacotamento. Branding pesado (ícone/logo) é binário e
# entra como assets versionados no fork (ver CUSTOMIZATION-HIPERFARMA.md).
if [ -f "Cargo.toml" ]; then
  echo ">> (branding) nome do produto = $APP_PRODUCT_NAME"
fi

echo ">> customize-suporte.sh concluído."
