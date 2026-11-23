<script setup>
import { computed, onMounted, ref } from 'vue'
import TreinoEditor from '../components/TreinoEditor.vue'
import {
  excluirTreino,
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

async function carregar() {
  carregando.value = true
  erro.value = ''
  try {
    const [lista, atual] = await Promise.all([listarTreinos(perfil.id), obterTreinoAtualId(perfil.id)])
    treinos.value = lista
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
  try {
    await finalizarTreino(perfil.id, treino.id, proximo)
  } catch {
    erro.value = 'Não foi possível finalizar o treino.'
    return
  }
  treino.exercicios.forEach((e) => (e.feito = false))
  atualIdSalvo.value = proximo
  abaId.value = proximo
  const nomeProximo = treinos.value.find((t) => t.id === proximo).nome
  mostrarAviso(proximo === treino.id ? `🎉 ${treino.nome} finalizado!` : `🎉 ${treino.nome} finalizado! Próximo: ${nomeProximo}`)
}

function mostrarAviso(texto) {
  aviso.value = texto
  setTimeout(() => (aviso.value = ''), 4000)
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
  editando.value = null
  abaId.value = null
  await carregar()
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

onMounted(carregar)
</script>

<template>
  <main class="pagina">
    <header class="topo">
      <span class="mini-avatar" :style="{ background: perfil.cor }">{{ perfil.avatar }}</span>
      <h1>Treinos de {{ perfil.nome }}</h1>
      <RouterLink to="/perfis" class="trocar">Trocar perfil</RouterLink>
    </header>

    <p v-if="erro" class="erro">{{ erro }}</p>
    <p v-if="aviso" class="aviso" role="status">{{ aviso }}</p>

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

          <div v-if="total" class="progresso">
            <div class="barra"><div class="preenchido" :style="{ width: `${(feitos / total) * 100}%` }" /></div>
            <span>{{ feitos }} de {{ total }}</span>
          </div>

          <p v-if="!total" class="vazio-texto">Sem exercícios. Clique em Editar para adicionar.</p>

          <ul class="lista">
            <template v-for="(ex, i) in treinoAba.exercicios" :key="ex.id">
            <li v-if="ex.bloco && ex.bloco !== treinoAba.exercicios[i - 1]?.bloco" class="bloco">{{ ex.bloco }}</li>
            <li class="item" :class="{ feito: ex.feito }">
              <label class="check">
                <input type="checkbox" :checked="ex.feito" @change="alternar(ex)" />
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
            </li>
            </template>
          </ul>

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
.trocar {
  font-size: 0.9rem;
}
.aviso {
  margin: 0;
  padding: 12px 16px;
  border-radius: 12px;
  background: rgb(43 255 136 / 0.12);
  border: 1px solid var(--verde);
  color: var(--verde);
  font-weight: 700;
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
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.bloco {
  margin-top: 12px;
  padding-bottom: 6px;
  border-bottom: 1px solid var(--borda);
  font-weight: 800;
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--verde);
}
.bloco:first-child {
  margin-top: 0;
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
