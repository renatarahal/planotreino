import { novoId } from './uuid'

// Colunas editáveis de um exercício (as mesmas da tabela public.exercicios).
export const CAMPOS_EXERCICIO = [
  'bloco',
  'nome',
  'grupo_muscular',
  'equipamento',
  'series',
  'repeticoes',
  'carga',
  'descanso_segundos',
  'metodo',
  'observacoes',
  'video_url',
]

// Sugestões que aparecem ao digitar. Os campos aceitam qualquer outro valor.
export const SUGESTOES = {
  grupos: ['Peito', 'Costas', 'Ombros', 'Bíceps', 'Tríceps', 'Antebraço', 'Abdômen', 'Lombar',
    'Quadríceps', 'Posterior de coxa', 'Glúteos', 'Panturrilha', 'Corpo inteiro', 'Cardio', 'Mobilidade'],
  equipamentos: ['Halteres', 'Barra', 'Anilha', 'Kettlebell', 'Elástico', 'Banco', 'Peso corporal',
    'Bola suíça', 'Corda', 'Step', 'Colchonete', 'Barra fixa', 'Caneleira', 'Bicicleta', 'Esteira'],
  metodos: ['Normal', 'Bi-set', 'Tri-set', 'Drop-set', 'Pirâmide', 'Rest-pause', 'Circuito',
    'Isometria', 'Super-série', 'AMRAP', 'EMOM'],
}

export function exercicioVazio(bloco = '') {
  return {
    id: novoId(),
    bloco,
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

// Texto vazio vira null; números vazios também.
function limpar(valor) {
  if (typeof valor === 'string') return valor.trim() || null
  return valor === '' || Number.isNaN(valor) ? null : valor
}

export function limparExercicio(ex) {
  return {
    id: ex.id,
    feito: ex.feito ?? false,
    ...Object.fromEntries(CAMPOS_EXERCICIO.map((c) => [c, limpar(ex[c])])),
  }
}

// Recebe um exercício já limpo. Devolve a mensagem de erro, ou '' se estiver tudo certo.
export function validarExercicio(ex) {
  if (!ex.nome) return 'falta o nome.'
  if (ex.series != null && (ex.series < 1 || ex.series > 50)) return 'séries entre 1 e 50.'
  if (ex.descanso_segundos != null && (ex.descanso_segundos < 0 || ex.descanso_segundos > 3600))
    return 'descanso entre 0 e 3600 segundos.'
  if (ex.video_url && !/^https?:\/\//i.test(ex.video_url))
    return 'o link do vídeo precisa começar com http:// ou https://'
  return ''
}
