import { supabase } from '../lib/supabase'
import { MODO_DEMO, demo } from '../lib/demo'

export async function listarPerfis() {
  if (MODO_DEMO) return demo.listarPerfis()
  const { data, error } = await supabase
    .from('perfis')
    .select('id, nome, avatar, cor')
    .order('criado_em')
  if (error) throw error
  return data
}

export async function criarPerfil(perfil) {
  if (MODO_DEMO) return demo.criarPerfil(perfil)
  const { error } = await supabase.from('perfis').insert(perfil)
  if (error) throw error
}
