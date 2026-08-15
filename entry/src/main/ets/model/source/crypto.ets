/*
 * 网易云音乐 weapi / eapi 加密的 ArkTS 移植。
 * 算法与桌面版使用的 Rust crate ncm-api (gmg137/netease-cloud-music-api 2.0.0) 完全一致：
 *  - weapi: AES-128-CBC(预设密钥) -> AES-128-CBC(随机密钥)，随机密钥倒序后做无填充 RSA 加密
 *  - eapi : "nobody{path}use{text}md5forencrypt" 取 MD5 拼接后 AES-128-ECB，hex 大写
 * AES 与 MD5 使用系统 cryptoFramework，RSA(1024 位、固定公钥、e=65537、无填充) 用 BigInt 模幂实现。
 */
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

const IV_TEXT = '0102030405060708';
const PRESET_KEY = '0CoJUm6Qyw8W8jud';
const EAPI_KEY = 'e82ckenh8dichen8';
const BASE62 = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
// weapi RSA 公钥模数（从 ncm-api encrypt.rs 内 PEM 的 DER 中解析验证过）
const RSA_MODULUS_HEX =
  'e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725152b3ab17a876aea8a5aa76d2e417629' +
  'ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b4' +
  '24d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7';

function strToBytes(text: string): Uint8Array {
  return util.TextEncoder.create('utf-8').encodeInto(text);
}

function bytesToHex(data: Uint8Array): string {
  let out = '';
  for (let i = 0; i < data.length; i++) {
    out += data[i].toString(16).padStart(2, '0');
  }
  return out;
}

function base64Encode(data: Uint8Array): string {
  return new util.Base64Helper().encodeToStringSync(data);
}

async function aesEncrypt(data: Uint8Array, keyText: string, cbc: boolean): Promise<Uint8Array> {
  const generator = cryptoFramework.createSymKeyGenerator('AES128');
  const keyBlob: cryptoFramework.DataBlob = { data: strToBytes(keyText) };
  const symKey = await generator.convertKey(keyBlob);
  const cipher = cryptoFramework.createCipher(cbc ? 'AES128|CBC|PKCS7' : 'AES128|ECB|PKCS7');
  if (cbc) {
    const ivSpec: cryptoFramework.IvParamsSpec = {
      algName: 'IvParamsSpec',
      iv: { data: strToBytes(IV_TEXT) }
    };
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, ivSpec);
  } else {
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, null);
  }
  const out = await cipher.doFinal({ data: data });
  return out.data;
}

async function md5Hex(text: string): Promise<string> {
  const md = cryptoFramework.createMd('MD5');
  await md.update({ data: strToBytes(text) });
  const digest = await md.digest();
  return bytesToHex(digest.data);
}

async function randomSecretKey(): Promise<string> {
  const rand = cryptoFramework.createRandom();
  const blob = await rand.generateRandom(16);
  let key = '';
  for (let i = 0; i < 16; i++) {
    key += BASE62.charAt(blob.data[i] % 62);
  }
  return key;
}

function modPow(base: bigint, exp: bigint, mod: bigint): bigint {
  const zero = BigInt(0);
  const one = BigInt(1);
  const two = BigInt(2);
  let result = BigInt(1);
  let b = base % mod;
  let e = exp;
  while (e > zero) {
    if (e % two === one) {
      result = (result * b) % mod;
    }
    b = (b * b) % mod;
    e = e / two;
  }
  return result;
}

/** 无填充 RSA：c = m^e mod n，输出 256 位 hex（128 字节） */
function rsaEncrypt(reversedKey: string): string {
  const n = BigInt('0x' + RSA_MODULUS_HEX);
  const e = BigInt(65537);
  const m = BigInt('0x' + bytesToHex(strToBytes(reversedKey)));
  const c = modPow(m, e, n);
  return c.toString(16).padStart(256, '0');
}

/** weapi：返回 application/x-www-form-urlencoded 请求体 */
export async function weapi(paramsJson: string): Promise<string> {
  const secretKey = await randomSecretKey();
  const first = await aesEncrypt(strToBytes(paramsJson), PRESET_KEY, true);
  const second = await aesEncrypt(strToBytes(base64Encode(first)), secretKey, true);
  const params = base64Encode(second);
  const reversed = secretKey.split('').reverse().join('');
  const encSecKey = rsaEncrypt(reversed);
  return `params=${encodeURIComponent(params)}&encSecKey=${encSecKey}`;
}

/** eapi：path 为原始 /api/... 路径（摘要与加密都用它，与实际请求的 /eapi/ 主机头无关） */
export async function eapi(path: string, paramsJson: string): Promise<string> {
  const message = `nobody${path}use${paramsJson}md5forencrypt`;
  const digest = await md5Hex(message);
  const data = `${path}-36cd479b6b5-${paramsJson}-36cd479b6b5-${digest}`;
  const encrypted = await aesEncrypt(strToBytes(data), EAPI_KEY, false);
  return `params=${bytesToHex(encrypted).toUpperCase()}`;
}
