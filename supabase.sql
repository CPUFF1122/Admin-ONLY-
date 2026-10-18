-- รันทั้งไฟล์ใน Supabase > SQL Editor
create table profiles(id uuid primary key references auth.users on delete cascade, username text, is_admin boolean default false);
create table products(id bigint generated always as identity primary key, name text not null, price numeric not null, stock int default 0, image_url text, created_at timestamptz default now());
create table orders(id bigint generated always as identity primary key, user_id uuid references auth.users not null, items jsonb not null, total numeric, slip_url text, status text default 'pending', delivery text, created_at timestamptz default now());
alter table profiles enable row level security; alter table products enable row level security; alter table orders enable row level security;

create function public.is_admin() returns boolean language sql security definer set search_path=public stable as $$ select coalesce((select is_admin from profiles where id=auth.uid()),false) $$;

create function handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into profiles(id,username) values(new.id,new.raw_user_meta_data->>'username'); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

-- คิดยอดรวมฝั่งเซิร์ฟเวอร์ ลูกค้าแก้ราคาเองไม่ได้
create function set_total() returns trigger language plpgsql security definer set search_path=public as $$ begin
  new.total:=(select coalesce(sum(p.price),0) from products p where p.id in (select (x->>'id')::bigint from jsonb_array_elements(new.items) x));
  new.status:='pending'; new.delivery:=null; return new; end $$;
create trigger orders_total before insert on orders for each row execute function set_total();

create function store_stats() returns json language sql security definer set search_path=public as $$
  select json_build_object('users',(select count(*) from profiles),'orders',(select count(*) from orders where status='paid')) $$;

create policy "me" on profiles for select using (id=auth.uid());
create policy "read products" on products for select using (true);
create policy "admin products" on products for all using (is_admin()) with check (is_admin());
create policy "read orders" on orders for select using (user_id=auth.uid() or is_admin());
create policy "make order" on orders for insert with check (user_id=auth.uid());
create policy "admin orders" on orders for update using (is_admin());

insert into storage.buckets(id,name,public) values('products','products',true),('slips','slips',false) on conflict do nothing;
create policy "products read" on storage.objects for select using (bucket_id='products');
create policy "products add" on storage.objects for insert with check (bucket_id='products' and public.is_admin());
create policy "products del" on storage.objects for delete using (bucket_id='products' and public.is_admin());
create policy "slip add" on storage.objects for insert to authenticated with check (bucket_id='slips' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "slip read" on storage.objects for select to authenticated using (bucket_id='slips' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));

-- หลังสมัครบัญชีของคุณเองแล้ว รันบรรทัดนี้ (แก้อีเมล) เพื่อตั้งเป็นแอดมิน
-- update profiles set is_admin=true where id=(select id from auth.users where email='you@example.com');
