-- Insert an in-app notification whenever a message is created.
-- Run this in Supabase SQL editor.

create or replace function public.insert_message_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if NEW.is_deleted or NEW.sender_id = NEW.receiver_id then
    return NEW;
  end if;

  insert into public.notifications (
    title,
    message,
    user_id,
    sender_id,
    conversation_id
  ) values (
    'New message',
    coalesce(nullif(NEW.content, ''), 'Sent you an attachment'),
    NEW.receiver_id,
    NEW.sender_id,
    NEW.conversation_id
  );

  return NEW;
end;
$$;

drop trigger if exists on_message_insert_notification on public.messages;

create trigger on_message_insert_notification
after insert on public.messages
for each row
execute function public.insert_message_notification();
