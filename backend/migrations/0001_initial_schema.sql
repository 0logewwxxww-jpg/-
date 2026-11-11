-- المرحلة التالية: إنشاء مخطط متعدد المدارس وسياسات RLS.
-- لم تُنشأ الجداول التشغيلية بعد؛ لا تعتبر قاعدة البيانات جاهزة للإنتاج.
create extension if not exists pgcrypto;

create table if not exists public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  timezone text not null default 'Asia/Baghdad',
  created_at timestamptz not null default now()
);
