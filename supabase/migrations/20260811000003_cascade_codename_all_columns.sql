-- fn_cascade_codename_rename (20260811000001) covered setting/permission
-- tables and b-quest-list's assign fields, but missed every other column
-- that stores a codename as a plain-text reference: b-quest-list.owner,
-- and b_account_list / b_opportunity_list's create_by / update_by / owner
-- / am / sub_am. Those two tables are empty today, but will hit the same
-- orphaning bug once B-ACCOUNT is actually used — cover them now.
create or replace function public.fn_cascade_codename_rename()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.codename is distinct from old.codename and old.codename is not null then
    update public.setting_project set codename = new.codename where codename = old.codename;
    update public."b-quest-setting" set codename = new.codename where codename = old.codename;
    update public."b-account-setting" set codename = new.codename where codename = old.codename;
    update public.b_finance_setting set codename = new.codename where codename = old.codename;

    update public."b-quest-list" set designer_assign = new.codename where designer_assign = old.codename;
    update public."b-quest-list" set creative_assign = new.codename where creative_assign = old.codename;
    update public."b-quest-list" set owner = new.codename where owner = old.codename;

    update public.b_account_list set create_by = new.codename where create_by = old.codename;
    update public.b_account_list set update_by = new.codename where update_by = old.codename;

    update public.b_opportunity_list set owner = new.codename where owner = old.codename;
    update public.b_opportunity_list set am = new.codename where am = old.codename;
    update public.b_opportunity_list set sub_am = new.codename where sub_am = old.codename;
    update public.b_opportunity_list set create_by = new.codename where create_by = old.codename;
    update public.b_opportunity_list set update_by = new.codename where update_by = old.codename;
  end if;
  return new;
end;
$$;

-- backfill the b-quest-list.owner rows already orphaned (same
-- employee_id-suffix matching as the earlier backfills)
do $$
declare
  r record;
  new_codename text;
begin
  for r in select distinct owner as codename from public."b-quest-list" where owner is not null loop
    select p.codename into new_codename
      from public.profiles p
      where p.employee_id = substring(r.codename from '\(([^)]+)\)$')
      limit 1;
    if new_codename is not null and new_codename <> r.codename then
      update public."b-quest-list" set owner = new_codename where owner = r.codename;
    end if;
  end loop;
end $$;
