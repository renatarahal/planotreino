// Junta os exercícios do mesmo bloco. Os blocos ficam na ordem em que aparecem
// pela primeira vez, e os exercícios mantêm a ordem dentro de cada bloco.
// Ex.: um exercício novo de "Treino Principal" colocado no fim da lista vai
// para depois do último exercício de "Treino Principal".
//
// Blocos com a mesma escrita, ignorando maiúsculas e espaços, contam como um só
// e passam a usar a escrita da primeira vez em que aparecem.
export function agruparPorBloco(exercicios) {
  const grupos = new Map()
  for (const ex of exercicios) {
    const chave = (ex.bloco ?? '').trim().toLowerCase()
    if (!grupos.has(chave)) grupos.set(chave, { nome: ex.bloco, itens: [] })
    const grupo = grupos.get(chave)
    grupo.itens.push({ ...ex, bloco: grupo.nome })
  }
  return [...grupos.values()].flatMap((g) => g.itens)
}
