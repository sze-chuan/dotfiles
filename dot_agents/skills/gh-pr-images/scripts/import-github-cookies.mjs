// Load git.illumina.com (or another host) session cookies from the local
// Chromium profile into the current agent-browser session. Prints cookie
// names and set/fail only. Never prints values, the keyring secret, or tokens.
//
// Requires AGENT_BROWSER_SESSION and `secret-tool lookup application chromium`.

import { execFileSync, spawnSync } from "node:child_process";
import { createDecipheriv, pbkdf2Sync } from "node:crypto";
import { DatabaseSync } from "node:sqlite";
import os from "node:os";
import path from "node:path";

const CHROME_EPOCH_OFFSET_SECONDS = 11644473600n;
const SAME_SITE = { 0: "None", 1: "Lax", 2: "Strict" };

function argValue(flag, fallback) {
  const index = process.argv.indexOf(flag);
  if (index === -1) return fallback;
  const value = process.argv[index + 1];
  if (!value || value.startsWith("--")) {
    throw new Error(`${flag} needs a value`);
  }
  return value;
}

const host = argValue("--host", "git.illumina.com");
const checkOnly = process.argv.includes("--check");
const cookieDb =
  process.env.CHROMIUM_COOKIES ??
  path.join(os.homedir(), ".config/chromium/Default/Cookies");

function keyringPassword() {
  return execFileSync("secret-tool", ["lookup", "application", "chromium"], {
    encoding: "utf8",
  }).trim();
}

function decryptCookie(encryptedValue, key) {
  const blob = Buffer.from(encryptedValue);
  if (blob.subarray(0, 3).toString() !== "v11") {
    throw new Error("unsupported cookie prefix");
  }
  const decipher = createDecipheriv("aes-128-cbc", key, Buffer.alloc(16, " "));
  decipher.setAutoPadding(false);
  const plain = Buffer.concat([decipher.update(blob.subarray(3)), decipher.final()]);
  const pad = plain[plain.length - 1];
  const padOk =
    pad > 0 &&
    pad <= 16 &&
    plain.subarray(plain.length - pad).every((byte) => byte === pad);
  if (!padOk) throw new Error("bad padding");
  let value = plain.subarray(0, plain.length - pad);
  const printable = (buf) => buf.every((byte) => byte >= 32 && byte < 127);
  // Chromium 152 on Linux prepends a 32-byte prefix. Older writeups say Linux
  // cookies have none; only strip when the raw plaintext is not text.
  if (!printable(value)) {
    if (value.length <= 32 || !printable(value.subarray(32))) {
      throw new Error("cookie plaintext is not text");
    }
    value = value.subarray(32);
  }
  return value.toString("utf8");
}

function loadRows(password) {
  const key = pbkdf2Sync(password, "saltysalt", 1, 16, "sha1");
  const db = new DatabaseSync(cookieDb, { readOnly: true });
  const rows = db
    .prepare(
      `SELECT host_key, name, path, is_secure, is_httponly, samesite,
              CAST(expires_utc AS TEXT) AS exp, has_expires, encrypted_value
       FROM cookies
       WHERE host_key = ? OR host_key = ?`,
    )
    .all(host, `.${host}`);
  return rows.map((row) => ({
    ...row,
    value: decryptCookie(row.encrypted_value, key),
  }));
}

function setCookie(row) {
  const args = [
    "cookies",
    "set",
    row.name,
    row.value,
    "--url",
    `https://${host}`,
    "--path",
    row.path || "/",
  ];
  if (String(row.host_key).startsWith(".")) args.push("--domain", host);
  if (row.is_secure) args.push("--secure");
  if (row.is_httponly) args.push("--httpOnly");
  const sameSite = SAME_SITE[row.samesite];
  if (sameSite) args.push("--sameSite", sameSite);
  if (row.has_expires && row.exp !== "0") {
    const unix = Number(BigInt(row.exp) / 1000000n - CHROME_EPOCH_OFFSET_SECONDS);
    if (unix > 0) args.push("--expires", String(unix));
  }
  const result = spawnSync("agent-browser", args, { encoding: "utf8" });
  const output = `${result.stdout || ""}${result.stderr || ""}`.replaceAll(row.value, "<redacted>");
  return { ok: result.status === 0, output: output.trim().slice(0, 180) };
}

if (!checkOnly && !process.env.AGENT_BROWSER_SESSION) {
  console.error("AGENT_BROWSER_SESSION is unset. Refusing to write cookies into the shared browser.");
  process.exit(1);
}

const password = keyringPassword();
const rows = loadRows(password);

if (checkOnly) {
  const loggedIn = rows.find((row) => row.name === "logged_in");
  const ok = loggedIn?.value === "yes" || loggedIn?.value === "no";
  console.log(`host ${host}`);
  console.log(`cookies ${rows.length}`);
  console.log(`logged_in_ok ${Boolean(ok)}`);
  process.exit(ok ? 0 : 1);
}

let setCount = 0;
for (const row of rows) {
  const result = setCookie(row);
  console.log(row.name, result.ok ? "set" : "fail", result.ok ? "" : result.output);
  if (result.ok) setCount += 1;
}
console.log(`set_count ${setCount} of ${rows.length}`);
if (setCount !== rows.length) process.exit(1);
