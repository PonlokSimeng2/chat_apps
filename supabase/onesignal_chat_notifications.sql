-- OneSignal chat notifications via database trigger
-- Replace the placeholders for app_id and rest_api_key before running in Supabase.

create extension if not exists pg_net;

alter table public.users
  add column if not exists onesignal_subscription_id text;

create or replace function public.notify_message_onesignal()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  receiver_sub_id text;
  receiver_is_online boolean;
  sender_name text;
  message_body text;
  payload jsonb;
  onesignal_app_id text := '9a5ddfd5-fe71-4dac-99c9-5d0801040829';
  onesignal_api_key text := 'YOUR_REST_API_KEY';
begin
  if NEW.is_deleted or NEW.sender_id = NEW.receiver_id then
    return NEW;
  end if;

  if onesignal_app_id like 'YOUR_%' or onesignal_api_key like 'YOUR_%' then
    return NEW;
  end if;

  select u.onesignal_subscription_id,
         u.is_online
    into receiver_sub_id,
         receiver_is_online
  from public.users u
  where u.id = NEW.receiver_id;

  if coalesce(receiver_is_online, false) then
    return NEW;
  end if;

  if receiver_sub_id is null or receiver_sub_id = '' then
    return NEW;
  end if;

  select u.display_name
    into sender_name
  from public.users u
  where u.id = NEW.sender_id;

  message_body := coalesce(nullif(NEW.content, ''), 'Sent you an attachment');

  payload := jsonb_build_object(
    'app_id', onesignal_app_id,
    'include_subscription_ids', jsonb_build_array(receiver_sub_id),
    'target_channel', 'push',
    'headings', jsonb_build_object('en', coalesce(sender_name, 'New message')),
    'contents', jsonb_build_object('en', message_body)
  );

  perform net.http_post(
    url := 'https://api.onesignal.com/notifications',
    headers := jsonb_build_object(
      'Authorization', 'Basic ' || onesignal_api_key,
      'Content-Type', 'application/json'
    ),
    body := payload
  );

  return NEW;
end;
$$;

drop trigger if exists on_message_onesignal_notify on public.messages;

create trigger on_message_onesignal_notify
after insert on public.messages
for each row
execute function public.notify_message_onesignal();
