<script setup>
import { computed, onMounted, ref } from 'vue'
import { excluirRegistro, listarHistorico } from '../api/historico'
import { formatarDuracao } from '../lib/tempo'
import { perfilAtual } from '../session'

const perfil = perfilAtual.value
const registros = ref([]) // do mais recente para o mais antigo
const carregando = ref(true)
const erro = ref('')

const hoje = new Date()
const mes = ref(new Date(hoje.getFullYear(), hoje.getMonth(), 1))

const SEMANA = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
const fmtMes = new Intl.DateTimeFormat('pt-BR', { month: 'long', year: 'numeric' })
const fmtDia = new Intl.DateTimeFormat('pt-BR', { weekday: 'short', day: '2-digit', month: '2-digit' })
const fmtHora = new Intl.DateTimeFormat('pt-BR', { hour: '2-digit', minute: '2-digit' })
const fmtData = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' })

// Dia no horário local de quem está vendo, para o treino das 23h cair no dia certo.
const chaveDia = (d) => `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`
const maiuscula = (t) => t.charAt(0).toUpperCase() + t.slice(1)

const tituloMes = computed(() => maiuscula(fmtMes.format(mes.value)))
const ehMesAtual = computed(
  () => mes.value.getFullYear() === hoje.getFullYear() && mes.value.getMonth() === hoje.getMonth(),
)

function mudarMes(delta) {
  mes.value = new Date(mes.value.getFullYear(), mes.value.getMonth() + delta, 1)
}

const doMes = computed(() =>
  registros.value.filter((r) => {
    const d = new Date(r.finalizado_em)
    return d.getFullYear() === mes.value.getFullYear() && d.getMonth() === mes.value.getMonth()
  }),
)
const diasTreinados = computed(() => new Set(doMes.value.map((r) => chaveDia(new Date(r.finalizado_em)))))
const tempoTotal = computed(() => doMes.value.reduce((soma, r) => soma + (r.duracao_segundos ?? 0), 0))
const maisAntigo = computed(() => registros.value.at(-1) ?? null)

// Células do calendário: espaços vazios até o 1º dia cair no dia da semana certo.
const celulas = computed(() => {
  const ano = mes.value.getFullYear()
  const m = mes.value.getMonth()
  const vazios = new Date(ano, m, 1).getDay()
  const dias = new Date(ano, m + 1, 0).getDate()
  const lista = Array.from({ length: vazios }, (_, i) => ({ chave: `vazio-${i}` }))
  for (let dia = 1; dia <= dias; dia++) {
    const chave = chaveDia(new Date(ano, m, dia))
    lista.push({ chave, dia, treinou: diasTreinados.value.has(chave), hoje: chave === chaveDia(hoje) })
  }
  return lista
})

function quando(r) {
  const d = new Date(r.finalizado_em)
  return `${maiuscula(fmtDia.format(d).replace('.', ''))} · ${fmtHora.format(d)}`
}

function seriesReps(ex) {
  return [ex.series, ex.repeticoes].filter(Boolean).join(' × ')
}

async function carregar() {
  carregando.value = true
  erro.value = ''
  try {
    registros.value = await listarHistorico(perfil.id)
  } catch {
    erro.value = 'Não foi possível carregar o histórico.'
  } finally {
    carregando.value = false
  }
}

async function excluir(r) {
  if (!confirm(`Apagar do histórico o treino de ${quando(r)} (${r.treino_nome})?`)) return
  try {
    await excluirRegistro(r.id)
    registros.value = registros.value.filter((x) => x.id !== r.id)
  } catch {
    erro.value = 'Não foi possível apagar o registro.'
  }
}

onMounted(carregar)
</script>

<template>
  <main class="pagina">
    <header class="topo">
      <span class="mini-avatar" :style="{ background: perfil.cor }">{{ perfil.avatar }}</span>
      <h1>Histórico de {{ perfil.nome }}</h1>
      <RouterLink to="/treinos" class="voltar">← Treinos</RouterLink>
    </header>

    <p v-if="erro" class="erro">{{ erro }}</p>

    <template v-if="!carregando">
      <div v-if="!registros.length" class="vazio">
        <p>Ainda não há treinos no histórico.</p>
        <p class="suave">Quando você clicar em <strong>Finalizar treino</strong>, ele aparece aqui.</p>
      </div>

      <template v-else>
        <p class="geral">
          {{ registros.length }} {{ registros.length === 1 ? 'treino' : 'treinos' }} no total,
          desde {{ fmtData.format(new Date(maisAntigo.finalizado_em)) }}
        </p>

        <div class="mes">
          <button class="seta" aria-label="Mês anterior" @click="mudarMes(-1)">‹</button>
          <h2>{{ tituloMes }}</h2>
          <button class="seta" aria-label="Próximo mês" :disabled="ehMesAtual" @click="mudarMes(1)">›</button>
        </div>

        <div class="resumo">
          <div class="cartao">
            <strong>{{ diasTreinados.size }}</strong>
            <span>{{ diasTreinados.size === 1 ? 'dia treinado' : 'dias treinados' }}</span>
          </div>
          <div class="cartao">
            <strong>{{ doMes.length }}</strong>
            <span>{{ doMes.length === 1 ? 'treino' : 'treinos' }}</span>
          </div>
          <div class="cartao">
            <strong>{{ tempoTotal ? formatarDuracao(tempoTotal * 1000) : '—' }}</strong>
            <span>de treino</span>
          </div>
        </div>

        <div class="calendario" role="grid" :aria-label="`Dias treinados em ${tituloMes}`">
          <span v-for="(d, i) in SEMANA" :key="`s${i}`" class="dia-semana" aria-hidden="true">{{ d }}</span>
          <span
            v-for="c in celulas"
            :key="c.chave"
            class="dia"
            :class="{ treinou: c.treinou, hoje: c.hoje, vazio: !c.dia }"
            :aria-label="c.dia ? `${c.dia}${c.treinou ? ', treinou' : ''}` : undefined"
          >{{ c.dia }}</span>
        </div>

        <p v-if="!doMes.length" class="suave centro">Nenhum treino finalizado neste mês.</p>

        <ul class="lista">
          <li v-for="r in doMes" :key="r.id">
            <details class="registro">
              <summary>
                <div class="linha">
                  <span class="quando">{{ quando(r) }}</span>
                  <span class="nome">{{ r.treino_nome }}</span>
                </div>
                <div class="etiquetas">
                  <span v-if="r.duracao_segundos != null" class="etiqueta destaque">⏱️ {{ formatarDuracao(r.duracao_segundos * 1000) }}</span>
                  <span class="etiqueta" :class="{ completo: r.exercicios_feitos === r.exercicios_total && r.exercicios_total }">
                    ✓ {{ r.exercicios_feitos }} de {{ r.exercicios_total }}
                  </span>
                </div>
              </summary>

              <ul class="exercicios">
                <template v-for="(ex, i) in r.exercicios" :key="i">
                  <li v-if="ex.bloco && ex.bloco !== r.exercicios[i - 1]?.bloco" class="bloco">{{ ex.bloco }}</li>
                  <li class="exercicio" :class="{ pulou: !ex.feito }">
                    <span class="marca" :aria-label="ex.feito ? 'Feito' : 'Não feito'">{{ ex.feito ? '✓' : '○' }}</span>
                    <span class="ex-nome">{{ ex.nome }}</span>
                    <span class="ex-info">{{ [seriesReps(ex), ex.carga].filter(Boolean).join(' · ') }}</span>
                  </li>
                </template>
              </ul>

              <button class="secundario perigo" @click="excluir(r)">Apagar do histórico</button>
            </details>
          </li>
        </ul>
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
.voltar {
  font-size: 0.9rem;
  font-weight: 600;
}
.vazio {
  text-align: center;
  padding: 48px 0;
}
.suave {
  color: var(--texto-suave);
}
.centro {
  text-align: center;
  margin: 0;
}
.geral {
  margin: 0;
  color: var(--texto-suave);
  font-size: 0.9rem;
}
.mes {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.mes h2 {
  margin: 0;
  font-size: 1.3rem;
}
.seta {
  width: 44px;
  height: 44px;
  padding: 0;
  font-size: 1.5rem;
  background: var(--superficie);
  border: 1px solid var(--borda);
  color: var(--texto);
}
.resumo {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
}
.cartao {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 14px 8px;
  border-radius: 16px;
  background: var(--superficie);
  border: 1px solid var(--borda);
  text-align: center;
}
.cartao strong {
  font-size: 1.5rem;
  background: var(--gradiente);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.cartao span {
  font-size: 0.8rem;
  color: var(--texto-suave);
}
.calendario {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 6px;
  padding: 16px;
  border-radius: 16px;
  background: var(--superficie);
  border: 1px solid var(--borda);
}
.dia-semana {
  text-align: center;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--texto-suave);
}
.dia {
  aspect-ratio: 1;
  max-width: 48px;
  width: 100%;
  justify-self: center;
  display: grid;
  place-items: center;
  border-radius: 50%;
  font-size: 0.9rem;
  color: var(--texto-suave);
}
.dia.treinou {
  background: var(--gradiente);
  color: var(--preto);
  font-weight: 800;
  box-shadow: 0 0 12px rgb(43 255 136 / 0.35);
}
.dia.hoje {
  outline: 2px solid var(--roxo);
  outline-offset: 2px;
}
.lista {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.registro {
  border-radius: 16px;
  background: var(--superficie);
  border: 1px solid var(--borda);
  padding: 14px 16px;
}
.registro[open] {
  border-color: var(--roxo);
}
summary {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  cursor: pointer;
  list-style: none;
}
summary::-webkit-details-marker {
  display: none;
}
.linha {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.quando {
  font-size: 0.85rem;
  color: var(--texto-suave);
}
.nome {
  font-weight: 700;
}
.etiquetas {
  display: flex;
  gap: 6px;
}
.etiqueta {
  font-size: 0.8rem;
  padding: 3px 10px;
  border-radius: 999px;
  background: rgb(255 255 255 / 0.06);
  color: var(--texto-suave);
}
.etiqueta.destaque,
.etiqueta.completo {
  background: rgb(43 255 136 / 0.15);
  color: var(--verde);
  font-weight: 700;
}
.exercicios {
  list-style: none;
  margin: 14px 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.bloco {
  margin-top: 8px;
  font-size: 0.75rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--verde);
}
.exercicio {
  display: grid;
  grid-template-columns: 20px 1fr auto;
  gap: 8px;
  align-items: baseline;
  font-size: 0.9rem;
}
.marca {
  color: var(--verde);
  font-weight: 800;
}
.exercicio.pulou {
  color: var(--texto-suave);
}
.exercicio.pulou .marca {
  color: var(--texto-suave);
}
.ex-info {
  font-size: 0.8rem;
  color: var(--texto-suave);
  text-align: right;
}
.perigo {
  color: #ff7ab8;
  font-size: 0.85rem;
  padding: 8px 14px;
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
  .calendario {
    padding: 12px 8px;
    gap: 4px;
  }
  .exercicio {
    grid-template-columns: 20px 1fr;
  }
  .ex-info {
    grid-column: 2;
    text-align: left;
  }
}
</style>
