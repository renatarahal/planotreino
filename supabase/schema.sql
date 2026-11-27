-- Rode este script no Supabase: SQL Editor > New query > colar > Run.
--
-- Modelo de acesso: existe UMA conta de login (a da família). Quem está logado
-- pode ver e editar tudo. Por isso é essencial DESATIVAR novos cadastros em
-- Authentication > Sign In / Providers > "Allow new users to sign up".

create table if not exists public.perfis (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (char_length(nome) between 1 and 40),
  avatar text not null default '🏋️',
  cor text not null default '#9d4dff' check (cor ~ '^#[0-9a-fA-F]{6}$'),
  criado_em timestamptz not null default now()
);

alter table public.perfis enable row level security;

-- Só quem está logado acessa a tabela. Visitantes sem login (anon) ficam sem acesso.
grant select, insert, update, delete on public.perfis to authenticated;

drop policy if exists "familia acessa perfis" on public.perfis;
create policy "familia acessa perfis"
on public.perfis for all
to authenticated
using (true)
with check (true);

-- ---------------------------------------------------------------------------
-- Treinos (A, B, C...) de cada perfil
-- ---------------------------------------------------------------------------
create table if not exists public.treinos (
  id uuid primary key default gen_random_uuid(),
  perfil_id uuid not null references public.perfis(id) on delete cascade,
  nome text not null check (char_length(nome) between 1 and 40),        -- ex.: Treino A
  foco text check (char_length(foco) <= 80),                             -- ex.: Peito e tríceps
  observacoes text check (char_length(observacoes) <= 1000),             -- aquecimento, dicas gerais
  ordem int not null default 0,
  criado_em timestamptz not null default now()
);

create index if not exists treinos_perfil_idx on public.treinos (perfil_id, ordem);

-- Qual treino é "o da vez" para cada perfil (muda ao finalizar um treino)
alter table public.perfis
  add column if not exists treino_atual_id uuid references public.treinos(id) on delete set null;

-- ---------------------------------------------------------------------------
-- Exercícios de cada treino
-- ---------------------------------------------------------------------------
create table if not exists public.exercicios (
  id uuid primary key default gen_random_uuid(),
  treino_id uuid not null references public.treinos(id) on delete cascade,
  ordem int not null default 0,
  bloco text check (char_length(bloco) <= 60),                           -- ex.: Aquecimento (~8 min)
  nome text not null check (char_length(nome) between 1 and 80),
  grupo_muscular text check (char_length(grupo_muscular) <= 40),
  equipamento text check (char_length(equipamento) <= 40),
  series int check (series between 1 and 50),
  repeticoes text check (char_length(repeticoes) <= 30),                 -- ex.: 12 | 10-12 | 30s | até a falha
  carga text check (char_length(carga) <= 30),                           -- ex.: 10 kg | elástico vermelho
  descanso_segundos int check (descanso_segundos between 0 and 3600),
  metodo text check (char_length(metodo) <= 40),                         -- ex.: bi-set, drop-set
  observacoes text check (char_length(observacoes) <= 500),
  video_url text check (video_url ~* '^https?://' and char_length(video_url) <= 500),
  feito boolean not null default false,                                  -- checkbox do dia
  criado_em timestamptz not null default now()
);

-- Para quem já tinha criado a tabela antes do campo "bloco" existir
alter table public.exercicios
  add column if not exists bloco text check (char_length(bloco) <= 60);

create index if not exists exercicios_treino_idx on public.exercicios (treino_id, ordem);

alter table public.treinos enable row level security;
alter table public.exercicios enable row level security;

grant select, insert, update, delete on public.treinos to authenticated;
grant select, insert, update, delete on public.exercicios to authenticated;

drop policy if exists "familia acessa treinos" on public.treinos;
create policy "familia acessa treinos"
on public.treinos for all
to authenticated
using (true)
with check (true);

drop policy if exists "familia acessa exercicios" on public.exercicios;
create policy "familia acessa exercicios"
on public.exercicios for all
to authenticated
using (true)
with check (true);

-- ---------------------------------------------------------------------------
-- Histórico: um registro por treino finalizado
-- ---------------------------------------------------------------------------
-- Guarda uma cópia dos exercícios do dia, para o histórico continuar certo
-- mesmo se o treino for editado ou apagado depois.
create table if not exists public.historico (
  id uuid primary key default gen_random_uuid(),
  perfil_id uuid not null references public.perfis(id) on delete cascade,
  treino_id uuid references public.treinos(id) on delete set null,
  treino_nome text not null check (char_length(treino_nome) between 1 and 40),
  iniciado_em timestamptz,
  finalizado_em timestamptz not null default now(),
  duracao_segundos int check (duracao_segundos between 0 and 86400),
  exercicios_feitos int not null default 0 check (exercicios_feitos >= 0),
  exercicios_total int not null default 0 check (exercicios_total >= 0),
  exercicios jsonb not null default '[]'::jsonb  -- [{ nome, bloco, series, repeticoes, carga, feito }]
);

create index if not exists historico_perfil_idx on public.historico (perfil_id, finalizado_em desc);

alter table public.historico enable row level security;

grant select, insert, delete on public.historico to authenticated;

drop policy if exists "familia acessa historico" on public.historico;
create policy "familia acessa historico"
on public.historico for all
to authenticated
using (true)
with check (true);

-- Finaliza um treino de uma vez só: grava no histórico, desmarca os
-- checkboxes e define o próximo treino "da vez". Se uma parte falhar, nada
-- é gravado. Roda com as permissões de quem chamou (security invoker).
create or replace function public.finalizar_treino(
  p_treino uuid,
  p_proximo uuid,
  p_duracao_segundos int default null,
  p_iniciado_em timestamptz default null
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_perfil uuid;
  v_nome text;
  v_registro uuid;
begin
  select perfil_id, nome into v_perfil, v_nome from public.treinos where id = p_treino;
  if v_perfil is null then
    raise exception 'Treino não encontrado';
  end if;
  if p_proximo is not null
     and not exists (select 1 from public.treinos where id = p_proximo and perfil_id = v_perfil) then
    raise exception 'O próximo treino precisa ser do mesmo perfil';
  end if;

  insert into public.historico
    (perfil_id, treino_id, treino_nome, iniciado_em, duracao_segundos, exercicios_feitos, exercicios_total, exercicios)
  select
    v_perfil,
    p_treino,
    v_nome,
    p_iniciado_em,
    -- Cronômetro esquecido ligado por mais de 24h: guarda sem duração.
    case when p_duracao_segundos between 0 and 86400 then p_duracao_segundos end,
    count(*) filter (where e.feito),
    count(e.id),
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'nome', e.nome, 'bloco', e.bloco, 'series', e.series,
          'repeticoes', e.repeticoes, 'carga', e.carga, 'feito', e.feito
        ) order by e.ordem
      ) filter (where e.id is not null),
      '[]'::jsonb
    )
  from (select 1) as um
  left join public.exercicios e on e.treino_id = p_treino
  returning id into v_registro;

  update public.exercicios set feito = false where treino_id = p_treino and feito;
  update public.perfis set treino_atual_id = coalesce(p_proximo, p_treino) where id = v_perfil;

  return v_registro;
end;
$$;

revoke execute on function public.finalizar_treino(uuid, uuid, int, timestamptz) from public, anon;
grant execute on function public.finalizar_treino(uuid, uuid, int, timestamptz) to authenticated;
