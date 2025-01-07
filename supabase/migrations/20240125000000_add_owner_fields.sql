alter table restaurants
add column owner_type text default 'normal' check (owner_type in ('normal', 'restaurant', 'admin')); 