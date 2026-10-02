-- Avatar storage bucket and secure upload policies.
insert into storage.buckets(id,name,public) values('avatars','avatars',true) on conflict(id) do update set public=true;
create policy "avatar_upload_own" on storage.objects for insert to authenticated with check(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "avatar_update_own" on storage.objects for update to authenticated using(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text) with check(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "avatar_delete_own" on storage.objects for delete to authenticated using(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);
