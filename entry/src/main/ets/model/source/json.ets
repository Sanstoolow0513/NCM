/*
 * JSON 解析辅助函数。
 * ArkTS 严格类型下逐层解析 JSON 很繁琐，这里提供带路径的取值工具。
 * 移植自 ncm-core 的 get_val! 宏思路：任意一层缺失返回默认值而不是抛异常。
 */

export function jGet(obj: Object | null, path: string[]): Object | null {
  let cur: Object | null = obj;
  for (const key of path) {
    if (cur === null || cur === undefined) {
      return null;
    }
    const rec = cur as Record<string, Object>;
    const next: Object | undefined = rec[key];
    if (next === undefined || next === null) {
      return null;
    }
    cur = next;
  }
  return cur;
}

export function jStr(obj: Object | null, path: string[], def: string = ''): string {
  const v = jGet(obj, path);
  if (v === null) {
    return def;
  }
  if (typeof v === 'string') {
    return v;
  }
  if (typeof v === 'number' || typeof v === 'boolean') {
    return String(v);
  }
  return def;
}

export function jNum(obj: Object | null, path: string[], def: number = 0): number {
  const v = jGet(obj, path);
  if (v === null) {
    return def;
  }
  if (typeof v === 'number') {
    return v;
  }
  if (typeof v === 'string') {
    const n = Number(v);
    return Number.isNaN(n) ? def : n;
  }
  return def;
}

export function jArr(obj: Object | null, path: string[]): Object[] {
  const v = jGet(obj, path);
  if (v === null) {
    return [];
  }
  if (Array.isArray(v)) {
    return v as Object[];
  }
  return [];
}

/** 解析 JSON 数字数组（如喜欢歌曲 ids），元素不是数字/数字字符串则跳过 */
export function jNumArr(obj: Object | null, path: string[]): number[] {
  const items = jArr(obj, path);
  const out: number[] = [];
  for (const item of items) {
    if (typeof item === 'number') {
      out.push(item as number);
    } else if (typeof item === 'string') {
      const n = Number(item);
      if (!Number.isNaN(n)) {
        out.push(n);
      }
    }
  }
  return out;
}
