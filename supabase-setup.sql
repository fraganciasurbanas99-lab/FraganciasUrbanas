-- ============================================================
--  CONFIGURACIÓN DE SUPABASE PARA EL CATÁLOGO DE DECANTS
--  Cómo usarlo:
--  1. Entra a tu NUEVO proyecto en supabase.com
--  2. Menú lateral -> SQL Editor -> New query
--  3. Pega TODO este archivo y presiona "Run"
-- ============================================================

-- 1) Tabla de productos (cada fila = una presentación, ej. "Sauvage 5ml")
create table if not exists productos (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  marca       text,
  descripcion text,                       -- notas olfativas / detalle
  categoria   text,                       -- ej: Diseñador, Nicho, Árabe
  genero      text,                       -- Masculino / Femenino / Unisex
  ml          numeric,                    -- tamaño del decant (3, 5, 10...)
  precio      numeric not null default 0,
  imagen_url  text,
  stock       int default 0,
  destacado   boolean default false,      -- aparece primero si es true
  created_at  timestamptz default now()
);

-- 2) Activar seguridad por filas (RLS)
alter table productos enable row level security;

-- 3) Políticas: TODOS pueden LEER, solo usuarios logueados pueden EDITAR
drop policy if exists "lectura publica" on productos;
create policy "lectura publica"
  on productos for select using (true);

drop policy if exists "insertar autenticado" on productos;
create policy "insertar autenticado"
  on productos for insert to authenticated with check (true);

drop policy if exists "actualizar autenticado" on productos;
create policy "actualizar autenticado"
  on productos for update to authenticated using (true);

drop policy if exists "eliminar autenticado" on productos;
create policy "eliminar autenticado"
  on productos for delete to authenticated using (true);

-- 4) Bucket de imágenes (público para lectura)
insert into storage.buckets (id, name, public)
values ('productos', 'productos', true)
on conflict (id) do nothing;

drop policy if exists "img lectura publica" on storage.objects;
create policy "img lectura publica"
  on storage.objects for select using (bucket_id = 'productos');

drop policy if exists "img subir autenticado" on storage.objects;
create policy "img subir autenticado"
  on storage.objects for insert to authenticated with check (bucket_id = 'productos');

drop policy if exists "img borrar autenticado" on storage.objects;
create policy "img borrar autenticado"
  on storage.objects for delete to authenticated using (bucket_id = 'productos');

-- 5) (Opcional) Productos de ejemplo para probar. Bórralos cuando tengas los tuyos.
insert into productos (nombre, marca, descripcion, categoria, genero, ml, precio, stock, destacado) values
  ('Sauvage EDP',      'Dior',       'Bergamota, pimienta, ambroxan. Fresco y potente.', 'Diseñador', 'Masculino', 5,  35, 10, true),
  ('Bleu de Chanel',   'Chanel',     'Cítricos, incienso, madera de sándalo.',           'Diseñador', 'Masculino', 5,  38, 8,  false),
  ('Good Girl',        'Carolina Herrera', 'Café, jazmín, cacao. Dulce y elegante.',     'Diseñador', 'Femenino',  5,  33, 6,  true),
  ('Oud Wood',         'Tom Ford',   'Oud, palo de rosa, cardamomo. Nicho amaderado.',   'Nicho',     'Unisex',    5,  60, 4,  false);
