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
  salvarExercicios(treinoId, exercicios) {
    const treinos = lerTreinos()
    const treino = treinos.find((t) => t.id === treinoId)
    if (treino) treino.exercicios = JSON.parse(JSON.stringify(exercicios))
    gravarTreinos(treinos)
  },
  excluirExercicio(exercicioId) {
    const treinos = lerTreinos()
    for (const t of treinos) t.exercicios = t.exercicios.filter((ex) => ex.id !== exercicioId)
    gravarTreinos(treinos)
  },
  marcarExercicio(exercicioId, feito) {
    const treinos = lerTreinos()
    for (const t of treinos) for (const ex of t.exercicios) if (ex.id === exercicioId) ex.feito = feito
    gravarTreinos(treinos)
  },
  finalizarTreino(perfilId, treinoId, proximoId, { duracaoSegundos = null, iniciadoEm = null } = {}) {
    const treinos = lerTreinos()
    const treino = treinos.find((t) => t.id === treinoId)
    const exercicios = treino?.exercicios ?? []
    const registro = {
      id: novoId(),
      perfil_id: perfilId,
      treino_nome: treino?.nome ?? 'Treino',
      iniciado_em: iniciadoEm,
      finalizado_em: new Date().toISOString(),
      duracao_segundos: duracaoSegundos != null && duracaoSegundos <= 86400 ? duracaoSegundos : null,
      exercicios_feitos: exercicios.filter((ex) => ex.feito).length,
      exercicios_total: exercicios.length,
      exercicios: exercicios.map(({ nome, bloco, series, repeticoes, carga, feito }) => ({
        nome, bloco, series, repeticoes, carga, feito,
      })),
    }
    localStorage.setItem(CHAVE_HISTORICO, JSON.stringify([registro, ...lerHistorico()]))
    for (const ex of exercicios) ex.feito = false
    gravarTreinos(treinos)
    localStorage.setItem(CHAVE_ATUAIS, JSON.stringify({ ...lerAtuais(), [perfilId]: proximoId }))
  },
  listarHistorico(perfilId) {
    return lerHistorico()
      .filter((r) => r.perfil_id === perfilId)
      .sort((a, b) => b.finalizado_em.localeCompare(a.finalizado_em))
  },
  excluirRegistro(registroId) {
    localStorage.setItem(CHAVE_HISTORICO, JSON.stringify(lerHistorico().filter((r) => r.id !== registroId)))
  },
}

const CHAVE_TREINOS = 'planotreino:demo:treinos'
const CHAVE_ATUAIS = 'planotreino:demo:atuais'
const CHAVE_HISTORICO = 'planotreino:demo:historico'

function lerHistorico() {
  return JSON.parse(localStorage.getItem(CHAVE_HISTORICO) || '[]')
}

function lerTreinos() {
  return JSON.parse(localStorage.getItem(CHAVE_TREINOS) || '[]')
}
function gravarTreinos(treinos) {
  localStorage.setItem(CHAVE_TREINOS, JSON.stringify(treinos))
}
function lerAtuais() {
  return JSON.parse(localStorage.getItem(CHAVE_ATUAIS) || '{}')
}
