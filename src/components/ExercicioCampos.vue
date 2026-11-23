<script setup>
// Campos de um exercício (menos o nome, que cada tela posiciona do seu jeito).
// Precisa de <SugestoesExercicio> na mesma tela para as sugestões aparecerem.
const ex = defineModel({ type: Object, required: true })
</script>

<template>
  <div class="grade">
    <label class="largo">Bloco / seção
      <input v-model="ex.bloco" list="sugestoes-blocos" maxlength="60" placeholder="Aquecimento, Treino principal, Core..." />
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
      <input v-model="ex.grupo_muscular" list="sugestoes-grupos" maxlength="40" />
    </label>
    <label>Equipamento
      <input v-model="ex.equipamento" list="sugestoes-equipamentos" maxlength="40" />
    </label>
    <label>Método
      <input v-model="ex.metodo" list="sugestoes-metodos" maxlength="40" placeholder="Normal" />
    </label>
    <label>Vídeo (link)
      <input v-model="ex.video_url" type="url" maxlength="500" placeholder="https://youtube.com/..." />
    </label>
    <label class="largo">Observações
      <input v-model="ex.observacoes" maxlength="500" placeholder="Desça devagar, cotovelo fixo..." />
    </label>
  </div>
</template>

<style scoped>
.grade {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 12px;
  text-align: left;
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
input {
  min-width: 0;
}
</style>
