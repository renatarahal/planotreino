import { supabase } from '../lib/supabase'
import { MODO_DEMO, demo } from '../lib/demo'

// Limite de segurança: cerca de 3 anos treinando todo dia.
const LIMITE = 1000

// Treinos finalizados do perfil, do mais recente para o mais antigo.
export async function listarHistorico(perfilId) {
  if (MODO_DEMO) return demo.listarHistorico(perfilId)
  const { data, error } = await supabase
    .from('historico')
    .select('id, treino_nome, iniciado_em, finalizado_em, duracao_segundos, exercicios_feitos, exercicios_total, exercicios')
    .eq('perfil_id', perfilId)
    .order('finalizado_em', { ascending: false })
    .limit(LIMITE)
  if (error) throw error
  return data
}

export async function excluirRegistro(registroId) {
  if (MODO_DEMO) return demo.excluirRegistro(registroId)
  const { error } = await supabase.from('historico').delete().eq('id', registroId)
  if (error) throw error
}
