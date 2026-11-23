import { ref, watch } from 'vue'
import { supabase } from './lib/supabase'
import { MODO_DEMO, demo } from './lib/demo'

const CHAVE_PERFIL = 'planotreino:perfil'

// Perfil escolhido na tela "Quem vai treinar?". Fica salvo no navegador.
export const perfilAtual = ref(JSON.parse(localStorage.getItem(CHAVE_PERFIL) || 'null'))

watch(perfilAtual, (perfil) => {
  if (perfil) localStorage.setItem(CHAVE_PERFIL, JSON.stringify(perfil))
  else localStorage.removeItem(CHAVE_PERFIL)
})

export async function entrar(senha) {
  if (MODO_DEMO) return demo.entrar(senha)
  const { error } = await supabase.auth.signInWithPassword({
    // trim: ignora espaços ou tabulações coladas sem querer no Vercel / .env
    email: (import.meta.env.VITE_FAMILY_EMAIL ?? '').trim(),
    password: senha,
  })
  if (error) throw error
}

export async function sair() {
  perfilAtual.value = null
  if (MODO_DEMO) return demo.sair()
  await supabase.auth.signOut()
}

export async function estaLogado() {
  if (MODO_DEMO) return demo.estaLogado()
  const { data } = await supabase.auth.getSession()
  return !!data.session
}
