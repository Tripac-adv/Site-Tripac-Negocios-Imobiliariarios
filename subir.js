// uso: BANCO_URL=... node subir.js <imovel_id> [<imovel_id>...]
const { Client } = require("pg"); const fs = require("fs"); const crypto = require("crypto");
(async () => {
  const c = new Client({ connectionString: process.env.BANCO_URL, ssl: { rejectUnauthorized: false } });
  await c.connect();
  for (const id of process.argv.slice(2)) {
    const { rows } = await c.query("SELECT COUNT(*)::int AS n FROM fotos WHERE imovel_id=$1", [id]);
    if (rows[0].n) { console.log(id, "ja tem", rows[0].n, "fotos, pulei"); continue; }
    let ordem = 0;
    for (const n of ["01","02","03","04","05","06","07"]) {
      const buf = fs.readFileSync(__dirname + "/" + n + ".jpg");
      await c.query("INSERT INTO fotos (id, imovel_id, ordem, capa, tipo, bytes, conteudo) VALUES ($1,$2,$3,$4,'image/jpeg',$5,$6)",
        ["ft_" + crypto.randomBytes(10).toString("hex"), id, ordem, ordem === 0, buf.length, buf]);
      ordem++;
    }
    await c.query("UPDATE imoveis SET atualizado_em=now() WHERE id=$1", [id]);
    console.log(id, "fotos:", ordem);
  }
  await c.end();
})().catch(e => { console.error("ERRO", e.message); process.exit(1); });
