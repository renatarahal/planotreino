import { novoId } from './uuid'

// Modo demonstração: só funciona no `npm run dev` com VITE_DEMO=true no .env.local.
// No build de produção (`npm run build`) fica sempre desligado.
export const MODO_DEMO = import.meta.env.DEV && import.meta.env.VITE_DEMO === 'true'
export const SENHA_DEMO = MODO_DEMO ? 'treino123' : ''

const CHAVE_LOGADO = 'planotreino:demo:logado'
const CHAVE_PERFIS = 'planotreino:demo:perfis'

const PERFIS_EXEMPLO = [
  { id: 'demo-1', nome: 'Renata', avatar: '💪', cor: '#9d4dff' },
  { id: 'demo-2', nome: 'Papai', avatar: '🏋️', cor: '#2bff88' },
  { id: 'demo-3', nome: 'Lucas', avatar: '⚽', cor: '#00e5ff' },
  { id: 'demo-4', nome: 'Bia', avatar: '🤸', cor: '#ff3df2' },
]

export const demo = {
  entrar(senha) {
    if (senha !== SENHA_DEMO) throw new Error('Senha incorreta')
    localStorage.setItem(CHAVE_LOGADO, '1')
  },
  sair() {
    localStorage.removeItem(CHAVE_LOGADO)
  },
  estaLogado() {
    return localStorage.getItem(CHAVE_LOGADO) === '1'
  },
  listarPerfis() {
    const salvos = localStorage.getItem(CHAVE_PERFIS)
    return salvos ? JSON.parse(salvos) : PERFIS_EXEMPLO
  },
  criarPerfil(perfil) {
    const perfis = [...demo.listarPerfis(), { ...perfil, id: novoId() }]
    localStorage.setItem(CHAVE_PERFIS, JSON.stringify(perfis))
  },

  // Treinos: guardados no navegador como { perfil_id, ...treino, exercicios: [] }
  listarTreinos(perfilId) {
    return lerTreinos()
      .filter((t) => t.perfil_id === perfilId)
      .sort((a, b) => a.ordem - b.ordem)
  },
  obterTreinoAtualId(perfilId) {
    return lerAtuais()[perfilId] ?? null
  },
  salvarTreino(perfilId, treino) {
    const outros = lerTreinos().filter((t) => t.id !== treino.id)
    gravarTreinos([...outros, structuredClone({ ...treino, perfil_id: perfilId })])
  },
  excluirTreino(treinoId) {
    gravarTreinos(lerTreinos().filter((t) => t.id !== treinoId))
  },
  marcarExercicio(exercicioId, feito) {
    const treinos = lerTreinos()
    for (const t of treinos) for (const ex of t.exercicios) if (ex.id === exercicioId) ex.feito = feito
    gravarTreinos(treinos)
  },
  finalizarTreino(perfilId, treinoId, proximoId) {
    const treinos = lerTreinos()
    for (const ex of treinos.find((t) => t.id === treinoId)?.exercicios ?? []) ex.feito = false
    gravarTreinos(treinos)
    localStorage.setItem(CHAVE_ATUAIS, JSON.stringify({ ...lerAtuais(), [perfilId]: proximoId }))
  },
}

const CHAVE_TREINOS = 'planotreino:demo:treinos'
const CHAVE_ATUAIS = 'planotreino:demo:atuais'

function lerTreinos() {
  return JSON.parse(localStorage.getItem(CHAVE_TREINOS) || '[]')
}
function gravarTreinos(treinos) {
  localStorage.setItem(CHAVE_TREINOS, JSON.stringify(treinos))
}
function lerAtuais() {
  return JSON.parse(localStorage.getItem(CHAVE_ATUAIS) || '{}')
}
