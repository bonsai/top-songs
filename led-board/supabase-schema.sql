-- 1. Supabase Dashboard → SQL Editor で実行
-- 2. Database → Replication → messages テーブルの Realtime を ON にする

create table if not exists messages (
  id bigint generated always as identity primary key,
  text text not null,
  created_at timestamptz not null default now()
);

-- Realtime は Supabase Dashboard → Database → Replication から有効化
-- または以下を SQL Editor で実行:
-- alter publication supabase_realtime add table messages;
