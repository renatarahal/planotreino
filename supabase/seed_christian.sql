-- Cadastra o treino "Full Body de Readaptação" no perfil Christian.
-- Rode no Supabase: SQL Editor > New query > colar > Run.
-- Se o Christian já tiver um treino com esse nome, o script para sem gravar nada.

do $$
declare
  v_qtd int;
  v_perfil uuid;
  v_treino uuid;
  nl constant text := chr(10);
  b_aquec constant text := 'Aquecimento e Postura';
  b_forca constant text := 'Força Full Body';
  b_compl constant text := 'Complemento e Cardio';
begin
  select count(*) into v_qtd from public.perfis where lower(trim(nome)) = 'christian';
  if v_qtd = 0 then
    raise exception 'Não existe perfil chamado Christian. Crie o perfil no site e rode o script de novo.';
  elsif v_qtd > 1 then
    raise exception 'Existe mais de um perfil chamado Christian. Deixe só um e rode o script de novo.';
  end if;
  select id into v_perfil from public.perfis where lower(trim(nome)) = 'christian';

  if exists (select 1 from public.treinos where perfil_id = v_perfil and nome = 'Full Body de Readaptação') then
    raise exception 'O Christian já tem um treino chamado "Full Body de Readaptação". Apague ou renomeie pelo site antes de rodar de novo.';
  end if;

  insert into public.treinos (perfil_id, nome, foco, observacoes, ordem)
  values (
    v_perfil,
    'Full Body de Readaptação',
    'Condicionamento, emagrecimento, postura e baixo impacto',
    'Semanas 1 a 4 | 3x por semana | 35 a 40 min | Silencioso.' || nl || nl ||
    'Frequência: faça em dias alternados (ex.: segunda, quarta e sexta) para garantir 48h de recuperação muscular.' || nl ||
    'Dias extras opcionais (ex.: terça ou quinta): se estiver disposto, 15 a 20 min de elíptico leve + 5 min de abertura com elástico.' || nl ||
    'Regra da semana 1: termine as séries sentindo que ainda teria "2 repetições sobrando", sem exagerar na carga logo no início.' || nl ||
    'Evolução: mantenha este protocolo por 3 a 4 semanas, até fazer todas as séries com controle e sem fadiga excessiva, antes de migrar para divisões AB ou ABC.',
    coalesce((select max(ordem) + 1 from public.treinos where perfil_id = v_perfil), 0)
  )
  returning id into v_treino;

  insert into public.exercicios
    (treino_id, ordem, bloco, nome, series, repeticoes, carga, descanso_segundos, metodo, grupo_muscular, equipamento, observacoes)
  values
    -- Bloco 1: Aquecimento e postura
    (v_treino, 0, b_aquec, 'Elíptico leve', null, '5 min', null, null, null, 'Cardio', 'Elíptico',
      'Ritmo conversável. Pedale em ritmo leve e constante para elevar a frequência cardíaca e lubrificar as articulações sem impacto. '
      'Mantenha os ombros relaxados e longe das orelhas, respirando fundo pelo nariz.'),
    (v_treino, 1, b_aquec, 'Abertura com elástico (band pull-apart)', 2, '15', 'Elástico leve', 30, null, 'Costas', 'Elástico',
      'Segure o elástico na largura dos ombros com os braços estendidos à frente e abra até encostar no peito, juntando bem as escápulas. '
      'Ajuda a aliviar a tensão acumulada no computador.'),
    (v_treino, 2, b_aquec, 'Mobilidade torácica em quatro apoios', 2, '8 cada lado', null, null, 'Contínuo', 'Mobilidade', 'Colchonete',
      'Em quatro apoios, passe um braço por baixo do tronco girando a coluna e depois abra o mesmo braço em direção ao teto, acompanhando com o olhar. '
      'Solta a rigidez do meio das costas e do pescoço antes da carga.'),

    -- Bloco 2: Força full body
    (v_treino, 3, b_forca, 'Agachamento goblet com kettlebell', 3, '10-12', '12 kg', 60, null, 'Quadríceps', 'Kettlebell',
      'Segure o kettlebell junto ao peito com os cotovelos apontados para baixo e agache mantendo o peito aberto e os pés firmes no chão. '
      'Suba empurrando o chão e contraindo os glúteos no topo.' || nl ||
      'Progressão: quando 3x12 com 12 kg ficar tranquilo, passe para o kettlebell de 24 kg começando com 3x6 a 8 repetições.'),
    (v_treino, 4, b_forca, 'Remada nas argolas', 3, '8-12', 'Peso corporal', 60, null, 'Costas', 'Argolas',
      'Segure as argolas com o corpo reto e inclinado para trás, puxando o peito em direção às mãos enquanto aperta as escápulas. '
      'Desça de forma controlada.' || nl ||
      'Ajuste: controle a dificuldade pela posição dos pés (corpo mais vertical = mais leve; corpo mais horizontal = mais pesado).'),
    (v_treino, 5, b_forca, 'Levantamento terra com kettlebell', 3, '12', '12 kg na semana 1', 60, null, 'Posterior de coxa', 'Kettlebell',
      'Posicione o kettlebell entre os pés, empurre o quadril para trás mantendo a coluna neutra e suba estendendo o quadril com força nos glúteos e posteriores de coxa.' || nl ||
      'Progressão: comece com 12 kg na primeira semana para testar o movimento e passe para 24 kg assim que sentir segurança.'),

    -- Bloco 3: Complemento e cardio
    (v_treino, 6, b_compl, 'Flexão inclinada nas argolas', 3, '8-10', 'Peso corporal', 60, null, 'Peito', 'Argolas',
      'Argolas acima da cintura. Faça as flexões com o abdômen firme e o corpo alinhado da cabeça aos calcanhares. '
      'Desça com controle, sem deixar os ombros subirem em direção às orelhas.' || nl ||
      'Ajuste: argolas mais altas facilitam na primeira semana; baixe a altura aos poucos conforme ganhar força.'),
    (v_treino, 7, b_compl, 'Dead bug (core estável)', 3, '8 cada lado', null, 45, null, 'Abdômen', 'Colchonete',
      'Deitado de costas com a lombar pressionada no chão, estenda devagar um braço para trás e a perna oposta à frente, sem deixar as costas arquearem. '
      'Fortalece o abdômen profundo e protege a lombar.'),
    (v_treino, 8, b_compl, 'Elíptico intervalado leve', null, '8 a 10 min', null, null, 'Intervalado 1 min / 1 min', 'Cardio', 'Elíptico',
      'Alterne 1 minuto em ritmo firme (respiração mais acelerada, mas controlada) com 1 minuto bem leve para recuperar o fôlego. '
      'Encerra a sessão elevando o gasto calórico sem barulho e sem sobrecarga nos joelhos.');

  -- Se o Christian ainda não tem um treino "da vez", este passa a ser.
  update public.perfis set treino_atual_id = v_treino
  where id = v_perfil and treino_atual_id is null;
end $$;
