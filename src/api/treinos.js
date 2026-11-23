import { supabase } from '../lib/supabase'
import { MODO_DEMO, demo } from '../lib/demo'
import { CAMPOS_EXERCICIO } from '../lib/exercicio'

function checar({ data, error }) {
  if (error) throw error
  return data
}

// Treinos do perfil, já com os exercícios em ordem.
export async function listarTreinos(perfilId) {
  if (MODO_DEMO) return demo.listarTreinos(perfilId)
  return checar(
    await supabase
      .from('treinos')
      .select('id, nome, foco, observacoes, ordem, exercicios(*)')
      .eq('perfil_id', perfilId)
      .order('ordem')
      .order('ordem', { referencedTable: 'exercicios' }),
  )
}

export async function obterTreinoAtualId(perfilId) {
  if (MODO_DEMO) return demo.obterTreinoAtualId(perfilId)
  const data = checar(
    await supabase.from('perfis').select('treino_atual_id').eq('id', perfilId).single(),
  )
  return data.treino_atual_id
}

// Cria ou atualiza o treino e sincroniza a lista de exercícios
// (insere os novos, atualiza os existentes e apaga os removidos).
export async function salvarTreino(perfilId, treino) {
  if (MODO_DEMO) return demo.salvarTreino(perfilId, treino)

  checar(
    await supabase.from('treinos').upsert({
      id: treino.id,
      perfil_id: perfilId,
      nome: treino.nome,
      foco: treino.foco,
      observacoes: treino.observacoes,
      ordem: treino.ordem,
    }),
  )

  const exercicios = linhasExercicios(treino.id, treino.exercicios)

  let remover = supabase.from('exercicios').delete().eq('treino_id', treino.id)
  if (exercicios.length) remover = remover.not('id', 'in', `(${exercicios.map((e) => e.id).join(',')})`)
  checar(await remover)

  if (exercicios.length) checar(await supabase.from('exercicios').upsert(exercicios))
}

// A posição na lista vira a "ordem". Manda a linha completa porque o upsert
// do Postgres confere os campos obrigatórios (como o nome) mesmo ao atualizar.
function linhasExercicios(treinoId, exercicios) {
  return exercicios.map((ex, i) => ({
    id: ex.id,
    treino_id: treinoId,
    ordem: i,
    feito: ex.feito ?? false,
    ...Object.fromEntries(CAMPOS_EXERCICIO.map((c) => [c, ex[c] ?? null])),
  }))
}

// Salva a lista de exercícios de um treino na ordem recebida, sem mexer no
// treino em si. Usado ao arrastar um card e ao editar um exercício só.
export async function salvarExercicios(treinoId, exercicios) {
  if (MODO_DEMO) return demo.salvarExercicios(treinoId, exercicios)
  if (exercicios.length)
    checar(await supabase.from('exercicios').upsert(linhasExercicios(treinoId, exercicios)))
}

export async function excluirExercicio(exercicioId) {
  if (MODO_DEMO) return demo.excluirExercicio(exercicioId)
  checar(await supabase.from('exercicios').delete().eq('id', exercicioId))
}

export async function excluirTreino(treinoId) {
  if (MODO_DEMO) return demo.excluirTreino(treinoId)
  checar(await supabase.from('treinos').delete().eq('id', treinoId))
}

export async function marcarExercicio(exercicioId, feito) {
  if (MODO_DEMO) return demo.marcarExercicio(exercicioId, feito)
  checar(await supabase.from('exercicios').update({ feito }).eq('id', exercicioId))
}

// Desmarca todos os exercícios do treino e define o próximo como "o da vez".
export async function finalizarTreino(perfilId, treinoId, proximoId) {
  if (MODO_DEMO) return demo.finalizarTreino(perfilId, treinoId, proximoId)
  checar(await supabase.from('exercicios').update({ feito: false }).eq('treino_id', treinoId))
  checar(await supabase.from('perfis').update({ treino_atual_id: proximoId }).eq('id', perfilId))
}
