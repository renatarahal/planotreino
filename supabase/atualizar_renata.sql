-- Atualiza o "Treino em Casa" da Renata para o checklist novo.
-- Rode no Supabase: SQL Editor > New query > colar > Run.
-- Pode rodar mais de uma vez: ele não duplica exercícios.
-- No fim, mostra a lista de exercícios como ficou.

do $$
declare
  v_qtd int;
  v_treino uuid;
  b_principal constant text := 'Treino Principal (~18 min)';
  b_core constant text := 'Core e Proteção Lombar (~8 min)';
begin
  select count(*) into v_qtd
  from public.treinos t join public.perfis p on p.id = t.perfil_id
  where lower(trim(p.nome)) = 'renata' and t.nome = 'Treino em Casa';
  if v_qtd <> 1 then
    raise exception 'Esperava 1 treino "Treino em Casa" da Renata e achei %. Nada foi alterado.', v_qtd;
  end if;
  select t.id into v_treino
  from public.treinos t join public.perfis p on p.id = t.perfil_id
  where lower(trim(p.nome)) = 'renata' and t.nome = 'Treino em Casa';

  -- 1. Nomes novos dos blocos
  update public.exercicios set bloco = b_principal
  where treino_id = v_treino and lower(bloco) like 'treino principal%';

  update public.exercicios set bloco = b_core
  where treino_id = v_treino
    and (lower(bloco) like 'complementar%' or lower(bloco) like 'lombar e core%');

  -- 2. Mobilidade de quadril: troca a versão ajoelhada pelas novas opções
  update public.exercicios
  set nome = 'Mobilidade de quadril (para-brisa ou pêndulo)',
      series = 2,
      repeticoes = '10',
      observacoes = 'Deitada (para-brisa) ou em pé (pêndulo).'
  where treino_id = v_treino and lower(nome) like 'mobilidade de quadril%';

  -- 3. Panturrilha: atualiza a que já existe, ou cria se não houver
  if exists (select 1 from public.exercicios where treino_id = v_treino and lower(nome) like 'panturrilha%') then
    update public.exercicios
    set nome = 'Panturrilha em pé (elevação de calcanhar)',
        bloco = b_principal,
        series = 3,
        repeticoes = '15',
        descanso_segundos = 45
    where treino_id = v_treino and lower(nome) like 'panturrilha%';
  else
    insert into public.exercicios
      (treino_id, ordem, bloco, nome, series, repeticoes, descanso_segundos, grupo_muscular, equipamento)
    values
      (v_treino, 900, b_principal, 'Panturrilha em pé (elevação de calcanhar)', 3, '15', 45, 'Panturrilha', 'Peso corporal');
  end if;

  -- 4. Prancha inclinada: exercício novo no fim do bloco de core
  if not exists (select 1 from public.exercicios where treino_id = v_treino and lower(nome) like 'prancha%') then
    insert into public.exercicios
      (treino_id, ordem, bloco, nome, series, repeticoes, descanso_segundos, grupo_muscular, equipamento, observacoes)
    values
      (v_treino, 1000, b_core, 'Prancha inclinada nos antebraços', 3, '15-20s', 45, 'Abdômen', 'Step ou banco',
       'Antebraços apoiados no step ou no banco.');
  end if;

  -- 5. Reorganiza a ordem: Aquecimento, Treino Principal, Core.
  -- Dentro de cada bloco, mantém a ordem que já existia.
  update public.exercicios e
  set ordem = n.posicao
  from (
    select id,
           row_number() over (
             order by
               case
                 when lower(bloco) like 'aquecimento%' then 0
                 when lower(bloco) like 'treino principal%' then 1
                 when lower(bloco) like 'core e prote%' then 2
                 else 3
               end,
               ordem,
               criado_em
           ) - 1 as posicao
    from public.exercicios
    where treino_id = v_treino
  ) n
  where e.id = n.id;
end $$;

-- Resultado: confira se a lista ficou como o checklist.
select e.ordem + 1 as "#", e.bloco, e.nome, e.series, e.repeticoes, e.carga, e.descanso_segundos as descanso
from public.exercicios e
join public.treinos t on t.id = e.treino_id
join public.perfis p on p.id = t.perfil_id
where lower(trim(p.nome)) = 'renata' and t.nome = 'Treino em Casa'
order by e.ordem;
