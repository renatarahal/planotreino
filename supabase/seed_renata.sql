-- Cadastra o "Treino em Casa" no perfil Renata.
-- Rode DEPOIS do schema.sql: SQL Editor > New query > colar > Run.
-- Se rodar de novo, cria outro treino igual (dá para apagar pelo site).

do $$
declare
  v_perfil uuid;
  v_treino uuid;
begin
  select id into strict v_perfil from public.perfis where nome = 'Renata';
  -- "strict" dá erro se não houver perfil Renata ou se houver mais de um.

  insert into public.treinos (perfil_id, nome, foco, observacoes, ordem)
  values (
    v_perfil,
    'Treino em Casa',
    'Corpo inteiro + lombar e core',
    'Fazer 3x na semana. Total de ~30 min.' || chr(10) || chr(10) ||
    'Handgrip no dia a dia: 2 a 3 séries de 10 apertos lentos em cada mão, 1 ou 2 vezes ao dia, nos intervalos do trabalho.' || chr(10) ||
    'Evite usar o handgrip logo antes do treino de força, para não cansar a pegada na remada e nos halteres.',
    coalesce((select max(ordem) + 1 from public.treinos where perfil_id = v_perfil), 0)
  )
  returning id into v_treino;

  insert into public.exercicios
    (treino_id, ordem, bloco, nome, series, repeticoes, carga, descanso_segundos, grupo_muscular, equipamento, observacoes)
  values
    (v_treino, 0, 'Aquecimento e Mobilidade (~8 min)', 'Elíptico', null, '5 min', null, null, 'Cardio', 'Elíptico', 'Ritmo leve'),
    (v_treino, 1, 'Aquecimento e Mobilidade (~8 min)', 'Mobilidade de ombros com cabo de vassoura', 2, '10', null, null, 'Mobilidade', 'Cabo de vassoura', 'Frente e trás'),
    (v_treino, 2, 'Aquecimento e Mobilidade (~8 min)', 'Mobilidade de quadril ajoelhada', 2, '10 por perna', null, null, 'Mobilidade', 'Colchonete', null),
    (v_treino, 3, 'Treino Principal (~15 min)', 'Agachamento livre', 3, '10', null, 45, 'Quadríceps', 'Peso corporal', 'Com uma cadeira atrás como referência, se preferir'),
    (v_treino, 4, 'Treino Principal (~15 min)', 'Remada sentada no step com elástico', 3, '10', '20 a 35 kg', 45, 'Costas', 'Elástico e step', 'Costas retas, puxando na altura do umbigo'),
    (v_treino, 5, 'Treino Principal (~15 min)', 'Elevação lateral de ombros', 3, '10', '2 kg', 45, 'Ombros', 'Halteres', null),
    (v_treino, 6, 'Treino Principal (~15 min)', 'Rosca bíceps alternada', 3, '10 por braço', '2 kg', 45, 'Bíceps', 'Halteres', 'Cotovelos fixos'),
    (v_treino, 7, 'Treino Principal (~15 min)', 'Tríceps acima da cabeça', 3, '10', '4 kg (duas mãos)', 45, 'Tríceps', 'Halteres', 'Segure um halter com as duas mãos'),
    (v_treino, 8, 'Complementar (~7 min)', 'Elevação pélvica no chão (ponte)', 3, '12', null, 45, 'Glúteos', 'Colchonete', 'Contraia os glúteos no topo'),
    (v_treino, 9, 'Complementar (~7 min)', 'Abdominal dead bug', 3, '8 por lado', null, 45, 'Abdômen', 'Colchonete', 'Lombar totalmente colada no colchonete');

  -- Se a Renata ainda não tem um treino "da vez", este passa a ser.
  update public.perfis set treino_atual_id = v_treino
  where id = v_perfil and treino_atual_id is null;
end $$;
