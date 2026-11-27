// 45s | 32min 10s | 1h 05min
export function formatarDuracao(ms) {
  const total = Math.round(ms / 1000)
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  const s = total % 60
  if (h) return `${h}h ${String(m).padStart(2, '0')}min`
  if (m) return s ? `${m}min ${s}s` : `${m}min`
  return `${s}s`
}
