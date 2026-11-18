#!/usr/bin/env bash
# Primeira instalacao do site no Google Cloud (Cloud Run em Sao Paulo).
# Roda no Cloud Shell do projeto tripac-imoveis-site, de dentro do repositorio:
#   bash scripts/instalar-google.sh
# Os segredos sao digitados por quem roda (nao aparecem na tela) e vao direto
# para o Secret Manager do projeto. Nada de segredo fica no repositorio.
# Rodar de novo e seguro: o que ja existe e mantido.
set -euo pipefail

PROJETO="${PROJETO:-tripac-imoveis-site}"
REGIAO="southamerica-east1"
SERVICO="site-tripac"

gcloud config set project "$PROJETO" >/dev/null
echo "== projeto: $PROJETO"

echo "== ligando as APIs (leva 1 a 2 minutos na primeira vez)"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com secretmanager.googleapis.com \
  firebasehosting.googleapis.com firebase.googleapis.com

segredo() { # nome, pergunta, oculto(sim/nao)
  if gcloud secrets describe "$1" >/dev/null 2>&1; then
    echo "== segredo $1 ja existe, mantido"; return
  fi
  local valor
  if [ "$3" = "sim" ]; then read -r -s -p "$2: " valor; echo; else read -r -p "$2: " valor; fi
  [ -n "$valor" ] || { echo "vazio, abortado"; exit 1; }
  printf %s "$valor" | gcloud secrets create "$1" --replication-policy=automatic --data-file=- >/dev/null
  echo "== segredo $1 gravado"
}

if ! gcloud secrets describe session-secret >/dev/null 2>&1; then
  openssl rand -hex 32 | tr -d '\n' | gcloud secrets create session-secret --replication-policy=automatic --data-file=- >/dev/null
  echo "== segredo session-secret gerado"
fi
segredo banco-url   "Cole a connection string do Neon (postgresql://...)" sim
segredo admin-email "E-mail do primeiro administrador do site" nao
segredo admin-senha "Senha do primeiro administrador (forte; troque depois no site)" sim

NUM=$(gcloud projects describe "$PROJETO" --format='value(projectNumber)')
CONTA="${NUM}-compute@developer.gserviceaccount.com"
for s in session-secret banco-url admin-email admin-senha; do
  gcloud secrets add-iam-policy-binding "$s" --member="serviceAccount:$CONTA" \
    --role=roles/secretmanager.secretAccessor >/dev/null
done
echo "== o servico pode ler os segredos"

echo "== subindo o site (3 a 6 minutos)"
gcloud run deploy "$SERVICO" --source . --region "$REGIAO" --allow-unauthenticated \
  --memory 512Mi --cpu 1 --min-instances 0 --max-instances 2 --concurrency 40 \
  --set-env-vars NODE_ENV=production,ADMIN_NOME=Allan \
  --set-secrets BANCO_URL=banco-url:latest,SESSION_SECRET=session-secret:latest,ADMIN_EMAIL=admin-email:latest,ADMIN_SENHA=admin-senha:latest

URL=$(gcloud run services describe "$SERVICO" --region "$REGIAO" --format='value(status.url)')
echo "== no ar em $URL"
curl -s "$URL/health" && echo
