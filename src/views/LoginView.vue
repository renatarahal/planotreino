<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { entrar } from '../session'
import { fraseDoDia } from '../frases'
import { MODO_DEMO, SENHA_DEMO } from '../lib/demo'

const frase = fraseDoDia()

const router = useRouter()
const senha = ref('')
const erro = ref('')
const carregando = ref(false)

async function enviar() {
  erro.value = ''
  carregando.value = true
  try {
    await entrar(senha.value)
    router.push('/perfis')
  } catch {
    erro.value = 'Senha incorreta.'
  } finally {
    carregando.value = false
  }
}
</script>

<template>
  <main class="tela">
    <div>
      <h1 class="logo">PlanoTreino</h1>
      <p class="chamada">{{ frase }}</p>
    </div>
    <form class="cartao" @submit.prevent="enviar">
      <label for="senha">Senha da família</label>
      <input id="senha" v-model="senha" type="password" autocomplete="current-password" required autofocus />
      <p v-if="erro" class="erro">{{ erro }}</p>
      <p v-if="MODO_DEMO" class="demo">Modo demonstração: a senha é <strong>{{ SENHA_DEMO }}</strong></p>
      <button type="submit" :disabled="carregando">{{ carregando ? 'Entrando...' : 'Entrar' }}</button>
    </form>
  </main>
</template>

<style scoped>
.chamada {
  max-width: 36ch;
  margin: 12px auto 0;
  font-style: italic;
  color: var(--texto-suave);
  font-size: 1.1rem;
}
.cartao {
  display: flex;
  flex-direction: column;
  gap: 14px;
  width: min(340px, 90vw);
  padding: 28px;
  text-align: left;
  border-radius: 20px;
  border: 2px solid transparent;
  background:
    linear-gradient(var(--superficie), var(--superficie)) padding-box,
    var(--gradiente) border-box;
  box-shadow: 0 0 40px rgb(157 77 255 / 0.25);
}
.demo {
  margin: 0;
  font-size: 0.85rem;
  color: var(--texto-suave);
}
.demo strong {
  color: var(--verde);
}
label {
  font-weight: 600;
  color: var(--texto-suave);
}
</style>
