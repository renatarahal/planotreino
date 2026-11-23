// Frases motivacionais (zoeiras). Uma por dia, igual para toda a família.
// Para acrescentar novas, é só colocar mais itens na lista.
export const FRASES = [
  'Hoje está um ótimo dia para dormir. Então vamos treinar.',
  'Você não comeu o suficiente hoje. Coma e venha se exercitar.',
  'O sofá ligou. Pediu um tempo. Respeita ele e vai treinar.',
  'Seu eu do futuro mandou dizer: obrigado por hoje. Não decepciona.',
  'Choveu? Ótimo, a academia é dentro de casa.',
  'Se cansar, descansa. Mas descansa fazendo prancha.',
  'Hoje não é dia de perna. Brincadeira, é sim.',
  'A preguiça veio te visitar. Diz que você saiu para treinar.',
  'Ninguém nunca se arrependeu de um treino. Já de um pastel...',
  'Suar é só a gordura chorando. Deixa ela chorar.',
  'Você já rolou o celular por 40 minutos. Agora rola no colchonete.',
  'A barra não vai se levantar sozinha. A gente já testou.',
  'Hoje o desafio é simples: treinar mais do que reclamar.',
  'O halter está te olhando faz três dias. Vai lá conversar com ele.',
  'Músculo não aparece por Wi-Fi. Precisa de conexão presencial.',
  'Bateu a preguiça? Faz 10 agachamentos e ela vai embora com vergonha.',
  'Domingo é dia de descanso. Hoje não é domingo. Se for, treina igual.',
  'Seu Netflix pode esperar 40 minutos. Ele não vai a lugar nenhum.',
  'Comeu brigadeiro ontem? Hoje são 3 séries a mais. Cada um.',
  'Treinar em casa: sem trânsito, sem desculpa, sem fila no aparelho.',
  'A cama está quentinha. A gente sabe. Levanta mesmo assim.',
  'Hoje é um ótimo dia para ficar forte. Amanhã também, mas começa hoje.',
  'Não precisa ser perfeito. Precisa só não ficar sentado.',
  'O espelho pediu um assunto novo. Dá um motivo para ele.',
  'Se a família toda treinar, ninguém pode reclamar da dor depois.',
  'Burpee: ninguém gosta, todo mundo precisa. Igual a brócolis.',
  'Você disse "segunda eu começo". Hoje é o dia que você chamou de segunda.',
  'Cansado? Ótimo, isso quer dizer que você está vivo. Agora treina.',
  'O cachorro do vizinho faz mais cardio que você. Reage.',
  'Hidrata, alonga e vai. Desculpa nova só amanhã.',
]

// Conta os dias desde 1970 pelo horário local, para a frase virar à meia-noite.
export function fraseDoDia(data = new Date()) {
  const dia = Math.floor(
    Date.UTC(data.getFullYear(), data.getMonth(), data.getDate()) / 86_400_000,
  )
  return FRASES[dia % FRASES.length]
}
