import { supabase } from '../lib/supabase'
import { MODO_DEMO, demo } from '../lib/demo'

export const CAMPOS_EXERCICIO = [
  'bloco',
  'nome',
  'grupo_muscular',
  'equipamento',
  'series',
  'repeticoes',
  'carga',
  'descanso_segundos',
  'metodo',
  'observacoes',
  'video_url',
]

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

  const exercicios = treino.exercicios.map((ex, i) => ({
    id: ex.id,
    treino_id: treino.id,
    ordem: i,
    feito: ex.feito ?? false,
    ...Object.fromEntries(CAMPOS_EXERCICIO.map((c) => [c, ex[c]])),
  }))

  let remover = supabase.from('exercicios').delete().eq('treino_id', treino.id)
  if (exercicios.length) remover = remover.not('id', 'in', `(${exercicios.map((e) => e.id).join(',')})`)
  checar(await remover)

  if (exercicios.length) checar(await supabase.from('exercicios').upsert(exercicios))
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
