<script setup>
import { computed, ref, toRaw } from 'vue'
import ExercicioCampos from './ExercicioCampos.vue'
import SugestoesExercicio from './SugestoesExercicio.vue'
import { agruparPorBloco, nomesDosBlocos } from '../lib/blocos'
import { exercicioVazio, limparExercicio, validarExercicio } from '../lib/exercicio'

const props = defineProps({
  treino: { type: Object, required: true },
  novo: { type: Boolean, default: false },
  salvando: { type: Boolean, default: false },
})
const emit = defineEmits(['salvar', 'cancelar', 'excluir'])

const form = ref(structuredClone(toRaw(props.treino)))
const erro = ref('')

// Blocos já usados neste treino, para sugerir ao digitar.
const blocos = computed(() => nomesDosBlocos(form.value.exercicios))

function adicionarExercicio() {
  // Novo exercício entra no mesmo bloco do último, que é o caso mais comum.
  form.value.exercicios.push(exercicioVazio(form.value.exercicios.at(-1)?.bloco ?? ''))
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

function textoOuNulo(valor) {
  return valor?.trim() || null
}

function salvar() {
  erro.value = ''
  const t = form.value
  // Valida na ordem em que a pessoa vê a lista, antes de reagrupar.
  const limpos = t.exercicios.map(limparExercicio)
  for (const [i, ex] of limpos.entries()) {
    const problema = validarExercicio(ex)
    if (problema) return (erro.value = `Exercício ${i + 1}: ${problema}`)
  }

  const treino = {
    ...t,
    nome: t.nome.trim(),
    foco: textoOuNulo(t.foco),
    observacoes: textoOuNulo(t.observacoes),
    exercicios: agruparPorBloco(limpos),
  }
  if (!treino.nome) return (erro.value = 'Dê um nome ao treino (ex.: Treino A).')
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

        <ExercicioCampos v-model="form.exercicios[i]" />
      </li>
    </ol>

    <button type="button" class="secundario adicionar" @click="adicionarExercicio">+ Adicionar exercício</button>
    <p v-if="blocos.length > 1" class="dica">Ao salvar, cada exercício vai para o fim do bloco escolhido.</p>

    <p v-if="erro" class="erro">{{ erro }}</p>

    <div class="acoes">
      <button v-if="!novo" type="button" class="secundario perigo" @click="excluir">Excluir treino</button>
      <span class="espaco" />
      <button type="button" class="secundario" @click="emit('cancelar')">Cancelar</button>
      <button type="submit" :disabled="salvando">{{ salvando ? 'Salvando...' : 'Salvar treino' }}</button>
    </div>

    <SugestoesExercicio :blocos="blocos" />
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
.vazio,
.dica {
  margin: 0;
  color: var(--texto-suave);
}
.dica {
  font-size: 0.85rem;
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
