-- Cadastra o "Treino em Casa" no perfil Larissa, adaptado da ficha da academia
-- para os equipamentos de casa.
-- Rode no Supabase: SQL Editor > New query > colar > Run.
-- Se a Larissa já tiver um treino com esse nome, o script para sem gravar nada.

do $$
declare
  v_qtd int;
  v_perfil uuid;
  v_treino uuid;
  b_aquec constant text := 'Aquecimento e Mobilidade (~10 min)';
  b_principal constant text := 'Treino Principal (~15 min)';
  b_compl constant text := 'Complementar (~8 min)';
begin
  select count(*) into v_qtd from public.perfis where lower(trim(nome)) = 'larissa';
  if v_qtd = 0 then
    raise exception 'Não existe perfil chamado Larissa. Crie o perfil no site e rode o script de novo.';
  elsif v_qtd > 1 then
    raise exception 'Existe mais de um perfil chamado Larissa. Deixe só um e rode o script de novo.';
  end if;
  select id into v_perfil from public.perfis where lower(trim(nome)) = 'larissa';

  if exists (select 1 from public.treinos where perfil_id = v_perfil and nome = 'Treino em Casa') then
    raise exception 'A Larissa já tem um treino chamado "Treino em Casa". Apague ou renomeie pelo site antes de rodar de novo.';
  end if;

  insert into public.treinos (perfil_id, nome, foco, observacoes, ordem)
  values (
    v_perfil,
    'Treino em Casa',
    'Pernas, glúteos e core (sem carga nas mãos)',
    'Adaptado da ficha da academia para os equipamentos de casa.' || chr(10) ||
    'Sem carga nas mãos e sem apoio nos punhos.' || chr(10) || chr(10) ||
    'As trocas das máquinas de perna são propostas: valide com o profissional antes de seguir.' || chr(10) ||
    'Séries, repetições e descanso que não vieram da ficha são sugestões iniciais. Ajuste pelo site.',
    coalesce((select max(ordem) + 1 from public.treinos where perfil_id = v_perfil), 0)
  )
  returning id into v_treino;

  insert into public.exercicios
    (treino_id, ordem, bloco, nome, series, repeticoes, carga, descanso_segundos, grupo_muscular, equipamento, observacoes)
  values
    -- Aquecimento e mobilidade
    (v_treino, 0, b_aquec, 'Elíptico', null, '5 a 10 min', null, null, 'Cardio', 'Elíptico',
      'No lugar da esteira/bike. Ritmo leve, sem apertar as hastes com força.'),
    (v_treino, 1, b_aquec, 'Rotação de ombros com bastão', 2, '10', null, null, 'Mobilidade', 'Cabo de vassoura',
      'Segure o bastão sem apertar.'),
    (v_treino, 2, b_aquec, 'Mobilidade de quadril', 2, '10', null, null, 'Mobilidade', 'Colchonete', null),
    (v_treino, 3, b_aquec, 'Mobilidade de tornozelo', 2, '10', null, null, 'Mobilidade', 'Peso corporal', null),

    -- Pernas: adaptações das máquinas (validar com o profissional)
    (v_treino, 4, b_principal, 'Agachamento parcial até a cadeira', 3, '10', 'Sem carga', 45, 'Quadríceps', 'Cadeira',
      'No lugar do leg press. Encoste de leve na cadeira e suba. Alternativa: subida baixa no step.'),
    (v_treino, 5, b_principal, 'Abdução de joelhos sentada com elástico', 3, '12-15', 'Elástico leve', 45, 'Glúteos', 'Elástico',
      'No lugar da cadeira abdutora. Elástico ao redor das coxas, logo acima dos joelhos.'),
    (v_treino, 6, b_principal, 'Extensão de joelho com elástico', 3, '12 por perna', 'Elástico leve', 45, 'Quadríceps', 'Elástico',
      'No lugar da cadeira extensora. Sentada, elástico preso no tornozelo e num ponto fixo atrás.'),
    (v_treino, 7, b_principal, 'Flexão de joelho com elástico', 3, '12 por perna', 'Elástico leve', 45, 'Posterior de coxa', 'Elástico',
      'No lugar da cadeira flexora. Elástico no tornozelo e preso num ponto fixo à frente.'),
    (v_treino, 8, b_principal, 'Elevação de panturrilha sentada', 3, '15', 'Sem peso ou 5 kg nas coxas', 45, 'Panturrilha', 'Halteres',
      'No lugar da cadeira solear. Se usar peso, apoie o halter sobre as coxas em vez de segurar.'),

    -- Complementar (já era da ficha, no solo)
    (v_treino, 9, b_compl, 'Elevação de quadril no solo', 3, '8-10', 'Sem peso', 45, 'Glúteos', 'Colchonete',
      '1s de isometria no topo. A ficha permite até 4 séries.'),
    (v_treino, 10, b_compl, 'Abdominal infra no solo', 3, '10', null, 45, 'Abdômen', 'Colchonete',
      'Lombar apoiada no colchonete.'),
    (v_treino, 11, b_compl, 'Prancha ventral nos antebraços', 3, '20-30s', null, 45, 'Abdômen', 'Colchonete',
      'Apoiada nos antebraços para poupar os punhos.');

  -- Se a Larissa ainda não tem um treino "da vez", este passa a ser.
  update public.perfis set treino_atual_id = v_treino
  where id = v_perfil and treino_atual_id is null;
end $$;
