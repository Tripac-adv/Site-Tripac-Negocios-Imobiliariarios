const {Client}=require("pg");(async()=>{const c=new Client({connectionString:process.env.BANCO_URL,ssl:{rejectUnauthorized:false}});await c.connect();
for(const [id,cod] of [["im_mwtiy1bo_f4f97572","AP-004"],["im_mwtiy2bt_0cff4cab","AP-005"]]){const r=await c.query("UPDATE imoveis SET codigo=$2 WHERE id=$1",[id,cod]);console.log("CODIGO",cod,r.rowCount)}
await c.end()})().catch(e=>console.log("ERRO",e.message));
