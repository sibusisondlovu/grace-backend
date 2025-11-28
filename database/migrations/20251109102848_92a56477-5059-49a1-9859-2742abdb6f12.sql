-- Update the handle_new_user function to assign organization based on email domain
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  user_email text;
  user_domain text;
  org_id uuid;
begin
  -- Get user email
  user_email := new.email;
  
  -- Extract domain from email
  user_domain := split_part(user_email, '@', 2);
  
  -- Try to find organization matching the email domain
  select id into org_id
  from public.organizations
  where domain = user_domain
  limit 1;
  
  -- If no organization found with matching domain, use the first active organization
  -- or create a default one (you can customize this logic)
  if org_id is null then
    select id into org_id
    from public.organizations
    where is_active = true
    order by created_at asc
    limit 1;
  end if;
  
  -- Insert profile with organization_id
  insert into public.profiles (
    id,
    user_id,
    organization_id,
    first_name,
    last_name,
    email
  )
  values (
    gen_random_uuid(),
    new.id,
    org_id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    user_email
  );
  
  return new;
end;
$$;