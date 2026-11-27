<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { VueDraggable } from 'vue-draggable-plus'
import ExercicioCampos from '../components/ExercicioCampos.vue'
import SugestoesExercicio from '../components/SugestoesExercicio.vue'
import TreinoEditor from '../components/TreinoEditor.vue'
import { agruparPorBloco, nomesDosBlocos } from '../lib/blocos'
import { limparExercicio, validarExercicio } from '../lib/exercicio'
import { formatarDuracao } from '../lib/tempo'
import {
  excluirExercicio,
  excluirTreino,
  salvarExercicios,
  finalizarTreino,
  listarTreinos,
  marcarExercicio,
  obterTreinoAtualId,
  salvarTreino,
} from '../api/treinos'
import { novoId } from '../lib/uuid'
import { perfilAtual } from '../session'

const perfil = perfilAtual.value
const treinos = ref([])
const atualIdSalvo = ref(null)
const abaId = ref(null)
const carregando = ref(true)
const erro = ref('')
const aviso = ref('')
const editando = ref(null) // { treino, novo }
const salvando = ref(false)

// "O da vez": o salvo no banco, ou o primeiro treino se ainda não houver.
const atualId = computed(() =>
  treinos.value.some((t) => t.id === atualIdSalvo.value) ? atualIdSalvo.value : treinos.value[0]?.id ?? null,
)
const treinoAba = computed(() => treinos.value.find((t) => t.id === abaId.value) ?? null)
const feitos = computed(() => treinoAba.value?.exercicios.filter((e) => e.feito).length ?? 0)
const total = computed(() => treinoAba.value?.exercicios.length ?? 0)

// Cronômetro: guarda no navegador a hora em que o treino começou. Por isso ele
// continua contando se a página for recarregada ou a tela do celular apagar.
const chaveInicio = (treinoId) => `planotreino:inicio:${treinoId}`
const inicios = ref({}) // treinoId -> horário de início (ms)
const agora = ref(Date.now())
let relogio = null

function lerInicio(treinoId) {
  const valor = Number(localStorage.getItem(chaveInicio(treinoId)))
  return Number.isFinite(valor) && valor > 0 ? valor : null
}

function gravarInicio(treinoId, inicio) {
  if (inicio) localStorage.setItem(chaveInicio(treinoId), String(inicio))
  else localStorage.removeItem(chaveInicio(treinoId))
  inicios.value = { ...inicios.value, [treinoId]: inicio }
}

const inicioAba = computed(() => inicios.value[abaId.value] ?? null)
const decorrido = computed(() => (inicioAba.value ? Math.max(0, agora.value - inicioAba.value) : 0))

function iniciar() {
  aviso.value = ''
  agora.value = Date.now()
  gravarInicio(treinoAba.value.id, agora.value)
}

function cancelarCronometro() {
  if (confirm('Zerar o cronômetro? Os exercícios marcados continuam marcados.')) gravarInicio(treinoAba.value.id, null)
}

// 5:07 | 1:02:09
function formatarRelogio(ms) {
  const total = Math.floor(ms / 1000)
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  const s = String(total % 60).padStart(2, '0')
  return h ? `${h}:${String(m).padStart(2, '0')}:${s}` : `${m}:${s}`
}


async function carregar() {
  carregando.value = true
  erro.value = ''
  try {
    const [lista, atual] = await Promise.all([listarTreinos(perfil.id), obterTreinoAtualId(perfil.id)])
    treinos.value = lista.map((t) => ({ ...t, exercicios: agruparPorBloco(t.exercicios) }))
    inicios.value = Object.fromEntries(lista.map((t) => [t.id, lerInicio(t.id)]))
    atualIdSalvo.value = atual
    if (!treinos.value.some((t) => t.id === abaId.value)) abaId.value = atualId.value
  } catch {
    erro.value = 'Não foi possível carregar os treinos.'
  } finally {
    carregando.value = false
  }
}

function proximoDe(id) {
  const i = treinos.value.findIndex((t) => t.id === id)
  return treinos.value[(i + 1) % treinos.value.length].id
}

async function alternar(ex) {
  ex.feito = !ex.feito
  try {
    await marcarExercicio(ex.id, ex.feito)
  } catch {
    ex.feito = !ex.feito
    erro.value = 'Não foi possível salvar o checkbox. Tente de novo.'
  }
}

async function finalizar() {
  const treino = treinoAba.value
  if (feitos.value < total.value && !confirm(`Faltam ${total.value - feitos.value} exercício(s). Finalizar mesmo assim?`))
    return
  const proximo = proximoDe(treino.id)
  const inicio = inicios.value[treino.id]
  const duracao = inicio ? Date.now() - inicio : null
  try {
    await finalizarTreino(perfil.id, treino.id, proximo, {
      duracaoSegundos: duracao != null ? Math.round(duracao / 1000) : null,
      iniciadoEm: inicio ? new Date(inicio).toISOString() : null,
    })
  } catch {
    erro.value = 'Não foi possível finalizar o treino.'
    return
  }
  treino.exercicios.forEach((e) => (e.feito = false))
  gravarInicio(treino.id, null)
  atualIdSalvo.value = proximo
  abaId.value = proximo

  const nomeProximo = treinos.value.find((t) => t.id === proximo).nome
  const tempo = duracao != null ? ` em ${formatarDuracao(duracao)}` : ''
  const seguinte = proximo === treino.id ? '' : ` Próximo: ${nomeProximo}.`
  // Fica na tela até a pessoa fechar, para dar tempo de ver o tempo total.
  aviso.value = `🎉 ${treino.nome} finalizado${tempo}!${seguinte}`
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function novoTreino() {
  const n = treinos.value.length
  editando.value = {
    novo: true,
    treino: {
      id: novoId(),
      nome: n < 26 ? `Treino ${String.fromCharCode(65 + n)}` : '',
      foco: '',
      observacoes: '',
      ordem: Math.max(-1, ...treinos.value.map((t) => t.ordem)) + 1,
      exercicios: [],
    },
  }
}

function editar() {
  editando.value = { novo: false, treino: JSON.parse(JSON.stringify(treinoAba.value)) }
}

async function salvar(treino) {
  salvando.value = true
  try {
    await salvarTreino(perfil.id, treino)
    abaId.value = treino.id
    editando.value = null
    await carregar()
  } catch {
    erro.value = 'Não foi possível salvar o treino.'
  } finally {
    salvando.value = false
  }
}

async function excluir() {
  const id = editando.value.treino.id
  try {
    await excluirTreino(id)
  } catch {
    erro.value = 'Não foi possível excluir o treino.'
    return
  }
  gravarInicio(id, null)
  editando.value = null
  abaId.value = null
  await carregar()
}

// ---------------------------------------------------------------------------
// Lista agrupada por bloco, com arrastar e editar um exercício só
// ---------------------------------------------------------------------------
// Cada bloco é uma lista própria. Arrastar um card para outro bloco faz o
// exercício passar a ser daquele bloco.
const grupos = ref([]) // [{ chave, nome, itens: [exercício] }]
const editandoEx = ref(null) // cópia do exercício em edição
const erroEx = ref('')
const salvandoEx = ref(false)

const normalizar = (bloco) => (bloco ?? '').trim().toLowerCase()

function montarGrupos() {
  const lista = []
  for (const ex of treinoAba.value?.exercicios ?? []) {
    const ultimo = lista.at(-1)
    if (ultimo && normalizar(ultimo.nome) === normalizar(ex.bloco)) ultimo.itens.push(ex)
    else lista.push({ chave: normalizar(ex.bloco) || '__sem-bloco__', nome: ex.bloco || null, itens: [ex] })
  }
  grupos.value = lista
}

watch(
  treinoAba,
  () => {
    editandoEx.value = null
    montarGrupos()
  },
  { immediate: true },
)

const assinatura = (lista) => lista.map((ex) => `${ex.id}:${ex.bloco ?? ''}`).join('|')

async function aoSoltar() {
  await nextTick() // espera a biblioteca atualizar as listas
  const treino = treinoAba.value
  const antes = assinatura(treino.exercicios)
  const lista = grupos.value.flatMap((g) =>
    g.itens.map((ex) => {
      ex.bloco = g.nome
      return ex
    }),
  )
  if (assinatura(lista) === antes) return // soltou no mesmo lugar
  treino.exercicios = lista
  montarGrupos() // some com blocos que ficaram vazios
  try {
    await salvarExercicios(treino.id, lista)
  } catch {
    erro.value = 'Não foi possível salvar a nova ordem. O treino foi recarregado.'
    await carregar()
  }
}

function editarExercicio(ex) {
  erroEx.value = ''
  editandoEx.value = JSON.parse(JSON.stringify(ex))
}

// Se o bloco mudou, o exercício vai para o fim do novo bloco.
function posicionar(exercicios, editado) {
  const original = exercicios.find((ex) => ex.id === editado.id)
  if (normalizar(original?.bloco) === normalizar(editado.bloco))
    return exercicios.map((ex) => (ex.id === editado.id ? editado : ex))

  const outros = exercicios.filter((ex) => ex.id !== editado.id)
  const ultimoDoBloco = outros.findLastIndex((ex) => normalizar(ex.bloco) === normalizar(editado.bloco))
  const posicao = ultimoDoBloco === -1 ? outros.length : ultimoDoBloco + 1
  return [...outros.slice(0, posicao), editado, ...outros.slice(posicao)]
}

async function salvarExercicio() {
  erroEx.value = ''
  const editado = limparExercicio(editandoEx.value)
  const problema = validarExercicio(editado)
  if (problema) return (erroEx.value = `Confira: ${problema}`)

  const treino = treinoAba.value
  const lista = agruparPorBloco(posicionar(treino.exercicios, editado))
  salvandoEx.value = true
  try {
    await salvarExercicios(treino.id, lista)
  } catch {
    erroEx.value = 'Não foi possível salvar o exercício.'
    return
  } finally {
    salvandoEx.value = false
  }
  treino.exercicios = lista
  editandoEx.value = null
  montarGrupos()
}

async function removerExercicio() {
  const ex = editandoEx.value
  if (!confirm(`Remover "${ex.nome || 'este exercício'}" do treino?`)) return
  const treino = treinoAba.value
  try {
    await excluirExercicio(ex.id)
  } catch {
    erroEx.value = 'Não foi possível remover o exercício.'
    return
  }
  treino.exercicios = treino.exercicios.filter((e) => e.id !== ex.id)
  editandoEx.value = null
  montarGrupos()
}

function formatarDescanso(seg) {
  if (seg == null) return null
  if (seg < 60) return `${seg}s`
  const m = Math.floor(seg / 60)
  const s = seg % 60
  return s ? `${m}min${String(s).padStart(2, '0')}` : `${m}min`
}

function linkSeguro(url) {
  return url && /^https?:\/\//i.test(url) ? url : null
}

onMounted(() => {
  carregar()
  relogio = setInterval(() => (agora.value = Date.now()), 1000)
})
onUnmounted(() => clearInterval(relogio))
</script>

<template>
  <main class="pagina">
    <header class="topo">
      <span class="mini-avatar" :style="{ background: perfil.cor }">{{ perfil.avatar }}</span>
      <h1>Treinos de {{ perfil.nome }}</h1>
      <nav class="links">
        <RouterLink to="/historico">📅 Histórico</RouterLink>
        <RouterLink to="/perfis">Trocar perfil</RouterLink>
      </nav>
    </header>

    <p v-if="erro" class="erro">{{ erro }}</p>
    <div v-if="aviso" class="aviso" role="status">
      <span>{{ aviso }}</span>
      <button class="fechar" aria-label="Fechar aviso" @click="aviso = ''">✕</button>
    </div>

    <TreinoEditor
      v-if="editando"
      :treino="editando.treino"
      :novo="editando.novo"
      :salvando="salvando"
      @salvar="salvar"
      @cancelar="editando = null"
      @excluir="excluir"
    />

    <template v-else-if="!carregando">
      <div v-if="!treinos.length" class="vazio">
        <p>{{ perfil.nome }} ainda não tem treinos.</p>
        <button @click="novoTreino">Criar o primeiro treino</button>
      </div>

      <template v-else>
        <nav class="abas" role="tablist">
          <button
            v-for="t in treinos"
            :key="t.id"
            role="tab"
            class="aba"
            :class="{ ativa: t.id === abaId }"
            :aria-selected="t.id === abaId"
            @click="abaId = t.id"
          >
            {{ t.nome }}
            <span v-if="t.id === atualId" class="da-vez">da vez</span>
          </button>
          <button class="aba nova" aria-label="Novo treino" @click="novoTreino">+</button>
        </nav>

        <section v-if="treinoAba" class="treino">
          <div class="treino-topo">
            <div>
              <h2>{{ treinoAba.nome }}</h2>
              <p v-if="treinoAba.foco" class="foco">{{ treinoAba.foco }}</p>
            </div>
            <button class="secundario" @click="editar">✏️ Editar</button>
          </div>

          <p v-if="treinoAba.observacoes" class="obs-geral">{{ treinoAba.observacoes }}</p>

          <button v-if="total && !inicioAba" class="iniciar" @click="iniciar">▶ Iniciar treino</button>

          <div v-if="total" class="painel" :class="{ rodando: inicioAba }">
            <div v-if="inicioAba" class="cronometro">
              <span class="tempo" role="timer">⏱️ {{ formatarRelogio(decorrido) }}</span>
              <button class="zerar" @click="cancelarCronometro">Zerar</button>
            </div>
            <div class="progresso">
              <div class="barra"><div class="preenchido" :style="{ width: `${(feitos / total) * 100}%` }" /></div>
              <span>{{ feitos }} de {{ total }}</span>
            </div>
          </div>

          <p v-if="!total" class="vazio-texto">Sem exercícios. Clique em Editar para adicionar.</p>

          <p v-if="total > 1" class="dica">Arraste pelo ⠿ para mudar a ordem, ou para outro bloco.</p>

          <div class="lista">
            <section v-for="g in grupos" :key="g.chave" class="grupo">
            <h3 v-if="g.nome" class="bloco">{{ g.nome }}</h3>
            <VueDraggable
              v-model="g.itens"
              tag="ul"
              class="itens"
              handle=".alca"
              :group="`exercicios-${treinoAba.id}`"
              :animation="180"
              :disabled="!!editandoEx"
              ghostClass="fantasma"
              chosenClass="escolhido"
              @end="aoSoltar"
            >
            <li v-for="ex in g.itens" :key="ex.id" class="item" :class="{ feito: ex.feito && editandoEx?.id !== ex.id, editando: editandoEx?.id === ex.id }">
              <form v-if="editandoEx?.id === ex.id" class="edicao" @submit.prevent="salvarExercicio">
                <input v-model="editandoEx.nome" class="nome-edicao" maxlength="80" placeholder="Nome do exercício *" required aria-label="Nome do exercício" />
                <ExercicioCampos v-model="editandoEx" />
                <p v-if="erroEx" class="erro">{{ erroEx }}</p>
                <div class="acoes-edicao">
                  <button type="button" class="secundario perigo" @click="removerExercicio">Remover</button>
                  <span class="espaco" />
                  <button type="button" class="secundario" @click="editandoEx = null">Cancelar</button>
                  <button type="submit" :disabled="salvandoEx">{{ salvandoEx ? 'Salvando...' : 'Salvar' }}</button>
                </div>
              </form>

              <template v-else>
              <span v-if="total > 1" class="alca" title="Arraste para mudar a ordem" aria-hidden="true">⠿</span>
              <label class="check">
                <input type="checkbox" :checked="ex.feito" :aria-label="`Feito: ${ex.nome}`" @change="alternar(ex)" />
                <span class="caixa" aria-hidden="true">✓</span>
              </label>
              <div class="info">
                <strong class="nome">{{ ex.nome }}</strong>
                <div class="etiquetas">
                  <span v-if="ex.series || ex.repeticoes" class="etiqueta destaque">
                    {{ [ex.series, ex.repeticoes].filter(Boolean).join(' × ') }}
                  </span>
                  <span v-if="ex.carga" class="etiqueta">🏋️ {{ ex.carga }}</span>
                  <span v-if="ex.descanso_segundos != null" class="etiqueta">⏱️ {{ formatarDescanso(ex.descanso_segundos) }}</span>
                  <span v-if="ex.metodo" class="etiqueta roxa">{{ ex.metodo }}</span>
                  <span v-if="ex.grupo_muscular" class="etiqueta">{{ ex.grupo_muscular }}</span>
                  <span v-if="ex.equipamento" class="etiqueta">{{ ex.equipamento }}</span>
                </div>
                <p v-if="ex.observacoes" class="obs">{{ ex.observacoes }}</p>
                <a v-if="linkSeguro(ex.video_url)" :href="linkSeguro(ex.video_url)" target="_blank" rel="noopener noreferrer" class="video">▶ Ver vídeo</a>
              </div>
              <button class="editar-ex" :disabled="!!editandoEx" :aria-label="`Editar ${ex.nome}`" @click="editarExercicio(ex)">✏️</button>
              </template>
            </li>
            </VueDraggable>
            </section>
          </div>

          <SugestoesExercicio :blocos="nomesDosBlocos(treinoAba.exercicios)" />

          <button v-if="total" class="finalizar" @click="finalizar">Finalizar treino</button>
        </section>
      </template>
    </template>
  </main>
</template>

<style scoped>
.pagina {
  max-width: 860px;
  margin: 0 auto;
  padding: 24px 16px 64px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.topo {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}
.topo h1 {
  flex: 1;
  font-size: 1.6rem;
}
.mini-avatar {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 26px;
  box-shadow: 0 0 0 3px var(--preto), 0 0 0 5px var(--verde);
}
.links {
  display: flex;
  gap: 16px;
  font-size: 0.9rem;
  font-weight: 600;
}
.aviso {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 12px;
  background: rgb(43 255 136 / 0.12);
  border: 1px solid var(--verde);
  color: var(--verde);
  font-weight: 700;
}
.aviso span {
  flex: 1;
}
.fechar {
  flex: none;
  width: 36px;
  height: 36px;
  padding: 0;
  background: transparent;
  color: var(--verde);
}
.iniciar {
  align-self: stretch;
  padding: 16px;
  font-size: 1.15rem;
}
.painel {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.painel.rodando {
  position: sticky;
  top: 8px;
  z-index: 5;
  padding: 12px 16px;
  border-radius: 16px;
  background: rgb(20 20 31 / 0.92);
  backdrop-filter: blur(8px);
  border: 1px solid var(--verde);
  box-shadow: 0 0 24px rgb(43 255 136 / 0.2);
}
.cronometro {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.tempo {
  font-size: 1.8rem;
  font-weight: 800;
  font-variant-numeric: tabular-nums;
  color: var(--verde);
}
.zerar {
  padding: 6px 14px;
  font-size: 0.85rem;
  font-weight: 500;
  background: transparent;
  border: 1px solid var(--borda);
  color: var(--texto-suave);
}
.vazio {
  text-align: center;
  padding: 48px 0;
  color: var(--texto-suave);
}
.abas {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 4px;
}
.aba {
  flex: none;
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--superficie);
  border: 1px solid var(--borda);
  color: var(--texto-suave);
}
.aba:hover:not(:disabled) {
  box-shadow: none;
  color: var(--texto);
}
.aba.ativa {
  background: var(--gradiente);
  color: var(--preto);
  border-color: transparent;
}
.aba.nova {
  border-style: dashed;
  border-color: var(--roxo);
  color: var(--roxo);
}
.da-vez {
  font-size: 0.7rem;
  text-transform: uppercase;
  padding: 2px 8px;
  border-radius: 999px;
  background: var(--preto);
  color: var(--verde);
}
.treino {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.treino-topo {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}
.treino-topo h2 {
  margin: 0;
}
.foco {
  margin: 4px 0 0;
  color: var(--verde);
  font-weight: 600;
}
.obs-geral {
  margin: 0;
  padding: 12px 16px;
  border-left: 3px solid var(--roxo);
  background: var(--superficie);
  border-radius: 0 10px 10px 0;
  color: var(--texto-suave);
  white-space: pre-line;
}
.progresso {
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 700;
  color: var(--texto-suave);
}
.barra {
  flex: 1;
  height: 10px;
  border-radius: 999px;
  background: var(--superficie);
  overflow: hidden;
}
.preenchido {
  height: 100%;
  background: var(--gradiente);
  transition: width 0.3s;
}
.vazio-texto {
  margin: 0;
  color: var(--texto-suave);
}
.lista {
  display: flex;
  flex-direction: column;
  gap: 22px;
}
.grupo {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.itens {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 24px; /* deixa soltar mesmo se a lista ficar quase vazia */
}
.bloco {
  margin: 0;
  padding-bottom: 6px;
  border-bottom: 1px solid var(--borda);
  font-weight: 800;
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--verde);
}
.dica {
  margin: 0;
  font-size: 0.85rem;
  color: var(--texto-suave);
}
.alca {
  flex: none;
  align-self: stretch;
  display: grid;
  place-items: center;
  width: 24px;
  margin: -14px 0 -14px -10px;
  font-size: 1.3rem;
  color: var(--texto-suave);
  cursor: grab;
  touch-action: none; /* no celular, arrastar pela alça não rola a página */
  user-select: none;
}
.alca:active {
  cursor: grabbing;
  color: var(--verde);
}
.editar-ex {
  flex: none;
  align-self: flex-start;
  width: 40px;
  height: 40px;
  margin: -6px -8px 0 auto;
  padding: 0;
  background: transparent;
  border: 1px solid transparent;
  font-size: 1rem;
}
@media (hover: hover) {
  .editar-ex:hover:not(:disabled) {
    border-color: var(--roxo);
    box-shadow: none;
  }
}
.fantasma {
  opacity: 0.35;
  border: 2px dashed var(--verde);
}
.escolhido {
  box-shadow: 0 0 24px rgb(157 77 255 / 0.45);
}
.item.editando {
  border-color: var(--roxo);
}
.edicao {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.nome-edicao {
  font-weight: 700;
}
.acoes-edicao {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.espaco {
  flex: 1;
}
.perigo {
  color: #ff7ab8;
}
.item {
  display: flex;
  gap: 14px;
  padding: 14px 16px;
  border-radius: 16px;
  background: var(--superficie);
  border: 1px solid var(--borda);
  transition: border-color 0.2s, opacity 0.2s;
}
.item.feito {
  border-color: var(--verde);
  opacity: 0.65;
}
.item.feito .nome {
  text-decoration: line-through;
}
.check {
  flex: none;
  cursor: pointer;
  /* área de toque de 44px, como recomendado para dedos */
  margin: -6px;
  padding: 6px;
}
.check input {
  position: absolute;
  opacity: 0;
}
.caixa {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  border: 2px solid var(--roxo);
  display: grid;
  place-items: center;
  color: transparent;
  font-weight: 900;
  transition: background 0.15s;
}
.check input:checked + .caixa {
  background: var(--gradiente);
  border-color: transparent;
  color: var(--preto);
}
.check input:focus-visible + .caixa {
  outline: 2px solid var(--verde);
  outline-offset: 2px;
}
.info {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-width: 0;
}
.nome {
  font-size: 1.05rem;
}
.etiquetas {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.etiqueta {
  font-size: 0.8rem;
  padding: 3px 10px;
  border-radius: 999px;
  background: rgb(255 255 255 / 0.06);
  color: var(--texto-suave);
}
.etiqueta.destaque {
  background: rgb(43 255 136 / 0.15);
  color: var(--verde);
  font-weight: 700;
}
.etiqueta.roxa {
  background: rgb(157 77 255 / 0.2);
  color: #c9a2ff;
}
.obs {
  margin: 0;
  font-size: 0.9rem;
  color: var(--texto-suave);
}
.video {
  font-size: 0.9rem;
  font-weight: 600;
}
.finalizar {
  align-self: center;
  padding: 16px 40px;
  font-size: 1.1rem;
  margin-top: 8px;
}
@media (max-width: 560px) {
  .pagina {
    padding: 16px 12px 48px;
    gap: 16px;
  }
  .topo h1 {
    font-size: 1.25rem;
  }
  .mini-avatar {
    width: 44px;
    height: 44px;
    font-size: 22px;
  }
  .item {
    padding: 12px;
    gap: 12px;
  }
  .finalizar {
    align-self: stretch;
  }
}
</style>
