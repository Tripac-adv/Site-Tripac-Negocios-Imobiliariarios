# Hospedagem no Google (desde 18/11/2026)

O Render foi abandonado em 18/11/2026: o banco gratuito dele expirou e o serviço
ficou reiniciando sem parar. O site passou para:

| Parte | Onde |
|---|---|
| Programa | Google Cloud Run, serviço `site-tripac`, região `southamerica-east1` (São Paulo), projeto próprio `tripac-imoveis-site`, separado do publicador do Instagram |
| Banco (imóveis, fotos, contatos, usuários, sessões) | Neon, projeto `site-tripac-imoveis`, região AWS São Paulo, conta do GitHub Tripac-adv |
| Domínio `tripacimoveis.com.br` | Firebase Hosting do mesmo projeto, que só repassa tudo ao Cloud Run (`firebase.json`) |

## Regras que nascem desta troca

- O cookie de sessão se chama `__session`. O Firebase Hosting apaga qualquer
  outro cookie antes de repassar o pedido ao Cloud Run; com outro nome o login
  não fica de pé.
- A pasta `hosting-vazio` existe só porque o Firebase exige uma pasta pública.
  Nada de `index.html` nela: arquivo ali passaria na frente do site.
- Segredos (`BANCO_URL`, `SESSION_SECRET`, `ADMIN_*`) ficam no Secret Manager
  do projeto, nunca no repositório.

## Atualizar o site depois de mudar o código

No Cloud Shell do projeto:

```bash
cd site-tripac-negocios-imobiliariarios && git pull
gcloud run deploy site-tripac --source . --region southamerica-east1
```

O banco não é tocado no deploy.
