<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { criarPerfil, listarPerfis } from '../api/perfis'
import { perfilAtual, sair } from '../session'

const AVATARES = ['🏋️', '💪', '🏃', '🚴', '🧘', '🤸', '🥊', '⚽', '🦁', '🐯', '🦊', '🐼']
const CORES = ['#2bff88', '#9d4dff', '#00e5ff', '#ff3df2', '#c6ff00', '#ff9f1c']

const router = useRouter()
const perfis = ref([])
const erro = ref('')
const adicionando = ref(false)
const novo = ref({ nome: '', avatar: AVATARES[0], cor: CORES[0] })

async function carregar() {
  try {
    perfis.value = await listarPerfis()
  } catch {
    erro.value = 'Não foi possível carregar os perfis.'
  }
}

function escolher(perfil) {
  perfilAtual.value = perfil
  router.push('/treinos')
}

async function salvarNovo() {
  const nome = novo.value.nome.trim()
  if (!nome) return
  try {
    await criarPerfil({ ...novo.value, nome })
  } catch {
    erro.value = 'Não foi possível criar o perfil.'
    return
  }
  adicionando.value = false
  novo.value = { nome: '', avatar: AVATARES[0], cor: CORES[0] }
  await carregar()
}

async function sairDaConta() {
  await sair()
  router.push('/login')
}

onMounted(carregar)
</script>

<template>
  <main class="tela">
    <h1>Quem vai treinar?</h1>
    <p v-if="erro" class="erro">{{ erro }}</p>

    <ul class="perfis">
      <li v-for="p in perfis" :key="p.id">
        <button class="perfil" @click="escolher(p)">
          <span class="avatar" :style="{ background: p.cor }">{{ p.avatar }}</span>
          <span class="nome">{{ p.nome }}</span>
        </button>
      </li>
      <li>
        <button class="perfil" @click="adicionando = true">
          <span class="avatar adicionar">+</span>
          <span class="nome">Adicionar perfil</span>
        </button>
      </li>
    </ul>

    <form v-if="adicionando" class="novo" @submit.prevent="salvarNovo">
      <input v-model="novo.nome" placeholder="Nome" maxlength="40" required autofocus />
      <div class="opcoes">
        <button
          v-for="a in AVATARES"
          :key="a"
          type="button"
          class="opcao"
          :class="{ ativa: novo.avatar === a }"
          @click="novo.avatar = a"
        >{{ a }}</button>
      </div>
      <div class="opcoes">
        <button
          v-for="c in CORES"
          :key="c"
          type="button"
          class="opcao cor"
          :class="{ ativa: novo.cor === c }"
          :style="{ background: c }"
          :aria-label="`Cor ${c}`"
          @click="novo.cor = c"
        />
      </div>
      <div class="acoes">
        <button type="button" class="secundario" @click="adicionando = false">Cancelar</button>
        <button type="submit">Salvar</button>
      </div>
    </form>

    <button class="secundario" @click="sairDaConta">Sair</button>
  </main>
</template>

<style scoped>
.perfis {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 28px;
}
.perfil {
  background: none;
  border: none;
  padding: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  color: var(--texto-suave);
  cursor: pointer;
  font-weight: 600;
}
.perfil:hover,
.perfil:focus-visible {
  transform: none;
  box-shadow: none;
  outline: none;
}
.perfil:hover .nome,
.perfil:focus-visible .nome {
  color: var(--verde);
}
.avatar {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 56px;
  border: 4px solid var(--preto);
  box-shadow: 0 0 0 2px transparent;
  transition: transform 0.2s, box-shadow 0.2s;
}
.perfil:hover .avatar,
.perfil:focus-visible .avatar {
  transform: scale(1.08);
  box-shadow: 0 0 0 3px var(--verde), 0 0 32px rgb(43 255 136 / 0.5);
}
@media (max-width: 560px) {
  .perfis {
    gap: 20px;
  }
  .avatar {
    width: 96px;
    height: 96px;
    font-size: 44px;
  }
}
.adicionar {
  background: var(--superficie);
  color: var(--roxo);
  border: 2px dashed var(--roxo);
}
.novo {
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: min(360px, 90vw);
}
.opcoes {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.opcao {
  width: 40px;
  height: 40px;
  padding: 0;
  border-radius: 50%;
  font-size: 20px;
  background: var(--superficie);
  border: 2px solid transparent;
}
.opcao.ativa {
  border-color: var(--verde);
  box-shadow: 0 0 12px rgb(43 255 136 / 0.5);
}
.acoes {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
</style>
