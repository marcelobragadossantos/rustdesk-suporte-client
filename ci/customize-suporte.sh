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
APP_PRODUCT_NAME="${APP_PRODUCT_NAME:-SuporteHiperfarma}"

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

# Nome de exibição do app (UI/título de janela). APP_NAME é static no config.rs;
# só é sobrescrito em runtime por custom client config assinado — então editar aqui pega.
echo ">> Nome de exibição (APP_NAME) = $APP_PRODUCT_NAME"
sed -i -E "s|(APP_NAME: RwLock<String> = RwLock::new\\()\"RustDesk\"|\\1\"${APP_PRODUCT_NAME}\"|" "$CFG"
grep -E 'APP_NAME: RwLock' "$CFG" || true

# --- Trava da tela de configuração (hardening de fleet) -------------------
# HARD_SETTINGS["disable-settings"]=Y  -> desabilita o menu de Ajustes inteiro.
# BUILTIN_SETTINGS["hide-server-settings"]=Y -> esconde ID/Relay/Key (servidor).
# Assim o usuário da loja não vê nem altera servidor/chave; só o suporte controla.
echo ">> Travando a tela de configuração (disable-settings + hide-server-settings)"
sed -i -E 's@(pub static ref HARD_SETTINGS: RwLock<HashMap<String, String>> =) Default::default\(\);@\1 RwLock::new(HashMap::from([("disable-settings".to_string(), "Y".to_string())]));@' "$CFG"
sed -i -E 's@(pub static ref BUILTIN_SETTINGS: RwLock<HashMap<String, String>> =) Default::default\(\);@\1 RwLock::new(HashMap::from([("hide-server-settings".to_string(), "Y".to_string())]));@' "$CFG"
grep -E '(HARD_SETTINGS|BUILTIN_SETTINGS): RwLock<HashMap' "$CFG" || true

# --- Branding de cores (identidade Hiperfarma) ----------------------------
# Paleta da marca (design-system): primary-600 #dc2626 (CTA/header), primary-500 #ef4444.
# RustDesk usa azul #0071FF (accent) e #2C8CFF (button) em flutter/lib/common.dart.
BRAND_ACCENT="${BRAND_ACCENT:-DC2626}"   # primary-600 — accent principal
BRAND_BUTTON="${BRAND_BUTTON:-EF4444}"   # primary-500 — botão (tom mais claro)
COMMON="flutter/lib/common.dart"
if [ -f "$COMMON" ]; then
  echo ">> Aplicando cores da marca: accent=#$BRAND_ACCENT button=#$BRAND_BUTTON"
  # accent / accent50 / accent80 (preserva o alfa: FF, 77, AA)
  sed -i -E "s|0xFF0071FF|0xFF${BRAND_ACCENT}|g; s|0x770071FF|0x77${BRAND_ACCENT}|g; s|0xAA0071FF|0xAA${BRAND_ACCENT}|g" "$COMMON"
  # button
  sed -i -E "s|0xFF2C8CFF|0xFF${BRAND_BUTTON}|g" "$COMMON"
  # ColorScheme primary dos temas (claro/escuro): azul -> vermelho
  sed -i -E "s|primary: Colors\.blue|primary: Colors.red|g" "$COMMON"
  echo ">> Conferência das cores resultantes:"
  grep -nE "static const Color (accent|button)" "$COMMON" || true
else
  echo ">> AVISO: $COMMON não encontrado — pulando cores."
fi

# --- Branding leve do nome de produto (Windows) ---------------------------
# O nome de exibição/empacotamento. Branding pesado (ícone/logo) é binário e
# entra como assets versionados no fork (ver CUSTOMIZATION-HIPERFARMA.md).
if [ -f "Cargo.toml" ]; then
  echo ">> (branding) nome do produto = $APP_PRODUCT_NAME"
fi

echo ">> customize-suporte.sh concluído."
