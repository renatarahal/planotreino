<script setup>
import { SUGESTOES } from '../lib/exercicio'

// Listas de sugestão usadas pelos campos de ExercicioCampos.
// Coloque uma vez por tela, porque os ids precisam ser únicos.
defineProps({ blocos: { type: Array, default: () => [] } })
</script>

<template>
  <datalist id="sugestoes-blocos"><option v-for="b in blocos" :key="b" :value="b" /></datalist>
  <datalist id="sugestoes-grupos"><option v-for="g in SUGESTOES.grupos" :key="g" :value="g" /></datalist>
  <datalist id="sugestoes-equipamentos"><option v-for="e in SUGESTOES.equipamentos" :key="e" :value="e" /></datalist>
  <datalist id="sugestoes-metodos"><option v-for="m in SUGESTOES.metodos" :key="m" :value="m" /></datalist>
</template>
