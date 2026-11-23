<script setup>
import { computed, ref, toRaw } from 'vue'
import { CAMPOS_EXERCICIO } from '../api/treinos'
import { novoId } from '../lib/uuid'

const props = defineProps({
  treino: { type: Object, required: true },
  novo: { type: Boolean, default: false },
  salvando: { type: Boolean, default: false },
})
const emit = defineEmits(['salvar', 'cancelar', 'excluir'])

const GRUPOS = ['Peito', 'Costas', 'Ombros', 'Bíceps', 'Tríceps', 'Antebraço', 'Abdômen', 'Lombar',
  'Quadríceps', 'Posterior de coxa', 'Glúteos', 'Panturrilha', 'Corpo inteiro', 'Cardio', 'Mobilidade']
const EQUIPAMENTOS = ['Halteres', 'Barra', 'Anilha', 'Kettlebell', 'Elástico', 'Banco', 'Peso corporal',
  'Bola suíça', 'Corda', 'Step', 'Colchonete', 'Barra fixa', 'Caneleira', 'Bicicleta', 'Esteira']
const METODOS = ['Normal', 'Bi-set', 'Tri-set', 'Drop-set', 'Pirâmide', 'Rest-pause', 'Circuito',
  'Isometria', 'Super-série', 'AMRAP', 'EMOM']

const form = ref(structuredClone(toRaw(props.treino)))
const erro = ref('')

// Blocos já usados neste treino, para sugerir ao digitar.
const blocos = computed(() => [...new Set(form.value.exercicios.map((e) => e.bloco?.trim()).filter(Boolean))])

function exercicioVazio() {
  return {
    id: novoId(),
    // Novo exercício entra no mesmo bloco do último, que é o caso mais comum.
    bloco: form.value.exercicios.at(-1)?.bloco ?? '',
    nome: '',
    grupo_muscular: '',
    equipamento: '',
    series: 3,
    repeticoes: '12',
    carga: '',
    descanso_segundos: 60,
    metodo: '',
    observacoes: '',
    video_url: '',
    feito: false,
  }
}

function adicionarExercicio() {
  form.value.exercicios.push(exercicioVazio())
}

function mover(i, direcao) {
  const lista = form.value.exercicios
  const j = i + direcao
  if (j < 0 || j >= lista.length) return
  ;[lista[i], lista[j]] = [lista[j], lista[i]]
}

function remover(i) {
  form.value.exercicios.splice(i, 1)
}

// Texto vazio vira null; números vazios também.
function limpar(valor) {
  if (typeof valor === 'string') return valor.trim() || null
  return valor === '' || Number.isNaN(valor) ? null : valor
}

function salvar() {
  erro.value = ''
  const t = form.value
  const treino = {
    ...t,
    nome: t.nome.trim(),
    foco: limpar(t.foco),
    observacoes: limpar(t.observacoes),
    exercicios: t.exercicios.map((ex) => ({
      id: ex.id,
      feito: ex.feito,
      ...Object.fromEntries(CAMPOS_EXERCICIO.map((c) => [c, limpar(ex[c])])),
    })),
  }

  if (!treino.nome) return (erro.value = 'Dê um nome ao treino (ex.: Treino A).')
  for (const [i, ex] of treino.exercicios.entries()) {
    const n = `Exercício ${i + 1}`
    if (!ex.nome) return (erro.value = `${n}: falta o nome.`)
    if (ex.series != null && (ex.series < 1 || ex.series > 50)) return (erro.value = `${n}: séries entre 1 e 50.`)
    if (ex.descanso_segundos != null && (ex.descanso_segundos < 0 || ex.descanso_segundos > 3600))
      return (erro.value = `${n}: descanso entre 0 e 3600 segundos.`)
    if (ex.video_url && !/^https?:\/\//i.test(ex.video_url))
      return (erro.value = `${n}: o link do vídeo precisa começar com http:// ou https://`)
  }
  emit('salvar', treino)
}

function excluir() {
  if (confirm(`Excluir o ${form.value.nome || 'treino'} e todos os exercícios dele?`)) emit('excluir')
}
</script>

<template>
  <form class="editor" @submit.prevent="salvar">
    <h2>{{ novo ? 'Novo treino' : `Editar ${treino.nome}` }}</h2>

    <div class="grade">
      <label>Nome do treino *
        <input v-model="form.nome" maxlength="40" placeholder="Treino A" required />
      </label>
      <label>Foco
        <input v-model="form.foco" maxlength="80" placeholder="Peito, ombro e tríceps" />
      </label>
      <label class="largo">Observações gerais
        <textarea v-model="form.observacoes" maxlength="1000" rows="2"
          placeholder="Aquecimento, alongamento, dicas..." />
      </label>
    </div>

    <h3>Exercícios</h3>
    <p v-if="!form.exercicios.length" class="vazio">Nenhum exercício ainda.</p>

    <ol class="exercicios">
      <li v-for="(ex, i) in form.exercicios" :key="ex.id" class="exercicio">
        <div class="cabecalho">
          <span class="numero">{{ i + 1 }}</span>
          <input v-model="ex.nome" class="nome" maxlength="80" placeholder="Nome do exercício *" required />
          <div class="botoes">
            <button type="button" class="icone" :disabled="i === 0" aria-label="Subir" @click="mover(i, -1)">↑</button>
            <button type="button" class="icone" :disabled="i === form.exercicios.length - 1" aria-label="Descer" @click="mover(i, 1)">↓</button>
            <button type="button" class="icone perigo" aria-label="Remover exercício" @click="remover(i)">✕</button>
          </div>
        </div>

        <div class="grade">
          <label class="largo">Bloco / seção
            <input v-model="ex.bloco" list="blocos" maxlength="60" placeholder="Aquecimento, Treino principal, Core..." />
          </label>
          <label>Séries
            <input v-model.number="ex.series" type="number" min="1" max="50" />
          </label>
          <label>Repetições
            <input v-model="ex.repeticoes" maxlength="30" placeholder="12, 10-12, 30s" />
          </label>
          <label>Carga
            <input v-model="ex.carga" maxlength="30" placeholder="10 kg, elástico forte" />
          </label>
          <label>Descanso (segundos)
            <input v-model.number="ex.descanso_segundos" type="number" min="0" max="3600" step="5" />
          </label>
          <label>Grupo muscular
            <input v-model="ex.grupo_muscular" list="grupos" maxlength="40" />
          </label>
          <label>Equipamento
            <input v-model="ex.equipamento" list="equipamentos" maxlength="40" />
          </label>
          <label>Método
            <input v-model="ex.metodo" list="metodos" maxlength="40" placeholder="Normal" />
          </label>
          <label>Vídeo (link)
            <input v-model="ex.video_url" type="url" maxlength="500" placeholder="https://youtube.com/..." />
          </label>
          <label class="largo">Observações
            <input v-model="ex.observacoes" maxlength="500" placeholder="Desça devagar, cotovelo fixo..." />
          </label>
        </div>
      </li>
    </ol>

    <button type="button" class="secundario adicionar" @click="adicionarExercicio">+ Adicionar exercício</button>

    <p v-if="erro" class="erro">{{ erro }}</p>

    <div class="acoes">
      <button v-if="!novo" type="button" class="secundario perigo" @click="excluir">Excluir treino</button>
      <span class="espaco" />
      <button type="button" class="secundario" @click="emit('cancelar')">Cancelar</button>
      <button type="submit" :disabled="salvando">{{ salvando ? 'Salvando...' : 'Salvar treino' }}</button>
    </div>

    <datalist id="blocos"><option v-for="b in blocos" :key="b" :value="b" /></datalist>
    <datalist id="grupos"><option v-for="g in GRUPOS" :key="g" :value="g" /></datalist>
    <datalist id="equipamentos"><option v-for="e in EQUIPAMENTOS" :key="e" :value="e" /></datalist>
    <datalist id="metodos"><option v-for="m in METODOS" :key="m" :value="m" /></datalist>
  </form>
</template>

<style scoped>
.editor {
  display: flex;
  flex-direction: column;
  gap: 16px;
  text-align: left;
}
h2, h3 {
  margin: 0;
}
h3 {
  color: var(--verde);
  margin-top: 8px;
}
.grade {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 12px;
}
.largo {
  grid-column: 1 / -1;
}
label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--texto-suave);
}
textarea {
  padding: 12px 14px;
  border-radius: 10px;
  border: 1px solid var(--borda);
  background: var(--superficie);
  color: var(--texto);
  font: inherit;
  resize: vertical;
}
.exercicios {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.exercicio {
  padding: 16px;
  border-radius: 16px;
  background: rgb(20 20 31 / 0.8);
  border: 1px solid var(--borda);
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.cabecalho {
  display: flex;
  align-items: center;
  gap: 10px;
}
.numero {
  flex: none;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background: var(--gradiente);
  color: var(--preto);
  font-weight: 800;
}
.nome {
  flex: 1;
  min-width: 0;
  font-weight: 600;
}
.botoes {
  display: flex;
  gap: 4px;
}
.icone {
  width: 36px;
  height: 36px;
  padding: 0;
  background: var(--superficie);
  border: 1px solid var(--borda);
  color: var(--texto);
}
.perigo {
  color: #ff7ab8;
}
.adicionar {
  align-self: flex-start;
  border-style: dashed;
  border-color: var(--roxo);
  color: var(--roxo);
}
.vazio {
  margin: 0;
  color: var(--texto-suave);
}
.acoes {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.espaco {
  flex: 1;
}
</style>
