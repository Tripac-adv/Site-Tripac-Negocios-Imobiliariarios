const {Client}=require("pg");(async()=>{const c=new Client({connectionString:process.env.BANCO_URL,ssl:{rejectUnauthorized:false}});await c.connect();
const a=await c.query("SELECT * FROM auditoria ORDER BY 1 DESC LIMIT 8");for(const r of a.rows){const x={...r};delete x.antes;delete x.depois;console.log("AUD",JSON.stringify(x))}
const s=await c.query("SELECT sid, expire, left(sess::text,160) s FROM sessoes ORDER BY expire DESC LIMIT 5");for(const r of s.rows)console.log("SES",r.expire,r.s)
await c.end()})().catch(e=>console.log("ERRO",e.message));
