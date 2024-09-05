const crypto = require("crypto");

const key1 = "AD7552C821266C8255348F726CAB2330";
const key2 = "AD7552C821266C8255348F726CAB9589";
const key3 = "ERDF64HGD6BNMJHTSDGFSDFKR4AB9589";

const authToken =
  "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJsYXN0TmFtZSI6Imt3S1FpWmhabHh4R2JhNXR1OXhMN0E9PSIsImdlbmRlciI6Ii9Ob0hRNHprdnpnL1BlN2FZTjB6T0E9PSIsInVzZXJfbmFtZSI6IkpPUkdFUk9KQVMyNn4xNjkzNjA0NjUwNjA3IiwiY3J5cHQiOiJ0cnVlIiwibG9naW4iOiIiLCJyb2wiOiIiLCJjbGllbnRfaWQiOiJiZHZlbmxpbmVhIiwic2NvcGUiOlsicmVhZCIsIndyaXRlIiwidHJ1c3QiXSwiY29ycmVvIjoiIiwic29jaWFsTGV2ZWwiOiJQV3RUNVJSMXpnaUwvcVJCM3FyOEZ3PT0iLCJpZCI6ImhRUkNZemR3TFExQnRjWUJlVlF2L3c9PSIsImV4cCI6MTY5MzYwNDgzMCwiY2FyZ28iOiIiLCJqdGkiOiJ0QktESUFBeEF0MGlGREtUYzYwRkdsVlp4bmsiLCJpZFR5cGUiOiJ6M2FDcWFCUnJnOG9wTXhBdXlaMTBnPT0iLCJpcCI6IkFFMjdlcktVelZkbkR1QW50QXl4ZWc9PSIsImxhc3RDb25uZWN0aW9uIjoibG5KN0VmUnJaYXdRblc3Yi9mbHYzZGNIbHNmM1VHUndNdUpzZEt3SGpQQT0iLCJmYWN0b3IzIjoiaEhSeWVlQzZHUXlvZ0dpdWdGckFvUT09IiwiZXN0YXR1c0FjdCI6IjNra240aW1HelN3ZDF4TDlkZGxncFE9PSIsImZlY2hhTmFjIjoiK25jdm96NjNweDVaNFp5cjRaU2NJU282VE5iSUVuUGg4ZisvbzNlUGFsRT0iLCJhdWQiOlsiR0VTVE9SUEFHT1MiLCJCRFZFTkxJTkVBIiwiUkVHSVNUUk9DTElFTlRFIl0sImNvcmQyIjoiIiwibnJvUGVyc29uYSI6IllXbDFTNWo5UlQ5M1pEUHJobkVNM2c9PSIsImNvcmQxIjoiIiwicGhvbmUiOiJ4VHJTRDN1NXNGbGRPWVNsZnA3OCtnPT0iLCJuYW1lIjoiUFdSVUJ2TTR4c2VZakJvcjhkVkVSUT09IiwidW5pY28iOiJUIn0.VzBKQU5HTTJZekZoTkRNNk1tSmpNekJqWVRnNU1XVXdNVEkzWkRSbU5tTTFZalUyTkdOak1tSm1OMkUxWlRCaU5XSTNabUptWTJNd01XVTFOelF6TldFek9EbG1Oamt4TkdNeE1UTm1PVFF4TlRKaE16RmtaRFEzWlRZMlpESXdNRGcwT1RBMU9EVTBNR0UwTXpCallUazJOV05qTUdSaE1tSXhNMk14Tm1Sa09HTTNOVFU0WXpGaE5XUT0";

function hashString(input) {
  const hasher = crypto.createHash("sha512");
  hasher.update(input);
  return hasher.digest("hex");
}

const n = "190.205.218.236";
const i = "JORGEROJAS26~1693600219307";
let t = JSON.stringify({ cuentaCliente: "01020431310000298045" });
const l = authToken.split(".")[2];

const inputString = n + i + t + l;
console.log("hash", hashString(inputString));

console.log("encripted body", encrypt(t, key1));
console.log(
  "decrypted body",
  decrypt(
    "XqOdrEWmFFhfnIHGsy54rit2jtl1dWNYt0gQI/jQpakAA5ieSo5xWy3aIIv37OnR",
    key1
  )
);
console.log("t", t);

// Decrypt an aes-256-ecb base64 toString
function decrypt(encrypted, key) {
  const decipher = crypto.createDecipheriv("aes-256-ecb", key, "");
  let decrypted = decipher.update(encrypted, "base64", "utf8");
  decrypted += decipher.final("utf8");

  return decrypted;
}

// Encrypt a string to aes-256-ecb base64 toString
function encrypt(text, key) {
  const cipher = crypto.createCipheriv("aes-256-ecb", key, "");
  let encrypted = cipher.update(text, "utf8", "base64");
  encrypted += cipher.final("base64");

  return encrypted;
}

console.log(decrypt("AE27erKUzVdnDuAntAyxeg==", key2));

//d3155f2e16c79aa236908eaf1fe704079fdb20d8d8476be15c26d11de85c89377ac632c291455055db23ddf0ef3400e33c207fe22ff7fb95408588d4c7196a03
