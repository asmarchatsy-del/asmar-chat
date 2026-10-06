-- Optimize RLS auth helpers and keep affected policies scoped to authenticated users.
-- auth.uid()/auth.role() are wrapped in SELECT so PostgreSQL can cache them per statement.
-- Policies are intentionally limited to authenticated users; service-role/admin operations
-- remain protected by their existing SECURITY DEFINER authorization checks.
do $$
declare p record; newqual text; newcheck text; cmd text;
begin
  for p in
    select schemaname, tablename, policyname, qual, with_check
    from pg_policies
    where schemaname='public'
      and (qual like '%auth.uid()%' or qual like '%auth.role()%'
        or with_check like '%auth.uid()%' or with_check like '%auth.role()%')
  loop
    newqual := case when p.qual is null then null
      else replace(replace(p.qual,'auth.uid()','(select auth.uid())'),'auth.role()','(select auth.role())') end;
    newcheck := case when p.with_check is null then null
      else replace(replace(p.with_check,'auth.uid()','(select auth.uid())'),'auth.role()','(select auth.role())') end;
    if newqual is not null and newcheck is not null then cmd := 'UPDATE';
    elsif newcheck is not null then cmd := 'INSERT';
    elsif lower(p.policyname) like '%delete%' then cmd := 'DELETE';
    else cmd := 'SELECT';
    end if;
    execute format('drop policy if exists %I on %I.%I',p.policyname,p.schemaname,p.tablename);
    execute format('create policy %I on %I.%I as permissive for %s to authenticated using (%s) %s',
      p.policyname,p.schemaname,p.tablename,cmd,
      coalesce(newqual,'true'),
      case when cmd in ('INSERT','UPDATE') then 'with check ('||coalesce(newcheck,'true')||')' else '' end);
  end loop;
end $$;