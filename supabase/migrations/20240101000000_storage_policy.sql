-- Profil fotoğrafları için güvenlik politikası
create policy "Profil fotoğraflarını herkes görebilir"
on storage.objects for select
using ( bucket_id = 'profile-images' );

create policy "Kullanıcılar kendi profil fotoğraflarını yükleyebilir"
on storage.objects for insert
with check (
  bucket_id = 'profile-images'
  AND auth.uid() = (storage.foldername(name))[1]::uuid
);

create policy "Kullanıcılar kendi profil fotoğraflarını güncelleyebilir"
on storage.objects for update
using (
  bucket_id = 'profile-images'
  AND auth.uid() = (storage.foldername(name))[1]::uuid
)
with check (
  bucket_id = 'profile-images'
  AND auth.uid() = (storage.foldername(name))[1]::uuid
);

create policy "Kullanıcılar kendi profil fotoğraflarını silebilir"
on storage.objects for delete
using (
  bucket_id = 'profile-images'
  AND auth.uid() = (storage.foldername(name))[1]::uuid
);