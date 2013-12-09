-- Function: product_complete_ratio(integer, integer)

-- DROP FUNCTION product_complete_ratio(integer, integer);

CREATE OR REPLACE FUNCTION product_complete_ratio(
    v_product_id integer,
    v_release_id integer)
  RETURNS numeric AS
$BODY$
declare
  v_pack_count numeric;
  v_finish_pack_count numeric;
  v_process numeric;
begin
  select count(pack.id) into v_pack_count
  from product_repo_pack
    join pack on product_repo_pack.pack_id = pack.id
    join product_repo on product_repo_pack.product_repo_id = product_repo.id
    join product on product_repo.product_id = product.id
    join release_tbl on product_repo.release_id = release_tbl.id
  where product_repo.product_id = v_product_id
  and product_repo.release_id = v_release_id;

  select count(pack.id) into v_finish_pack_count
  from product_repo_pack
    join pack on product_repo_pack.pack_id = pack.id
    join product_repo on product_repo_pack.product_repo_id = product_repo.id
    join product on product_repo.product_id = product.id
    join release_tbl on product_repo.release_id = release_tbl.id
  where product_repo.product_id = v_product_id
  and product_repo.release_id = v_release_id
  and pack.status >= 40;

	RAISE NOTICE 'v_pack_count = %', v_pack_count;
  if v_pack_count < 1 then
	v_process = 0.00;
	  return v_process;
  end if;

  select round(v_finish_pack_count/v_pack_count, 2) into v_process;
  return v_process;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION product_complete_ratio(integer, integer)
  OWNER TO postgres;

-- Function: repo_complete_ratio(integer, integer)

-- DROP FUNCTION repo_complete_ratio(integer, integer);

CREATE OR REPLACE FUNCTION repo_complete_ratio(
    v_release_id integer,
    v_repo_id integer)
  RETURNS numeric AS
$BODY$
declare
  v_pack_count numeric;
  v_finish_pack_count numeric;
  v_process numeric;
begin
  select count(pack.id) into v_pack_count
    from product_repo_pack
      join pack on product_repo_pack.pack_id = pack.id
      join product_repo on product_repo_pack.product_repo_id = product_repo.id
      join repo on product_repo.repo_id = repo.id
      join release_tbl on product_repo.release_id = release_tbl.id
    where repo.id = v_repo_id
    and release_tbl.id = v_release_id;

    select count(pack.id) into v_finish_pack_count
    from product_repo_pack
      join pack on product_repo_pack.pack_id = pack.id
      join product_repo on product_repo_pack.product_repo_id = product_repo.id
      join repo on product_repo.repo_id = repo.id
      join release_tbl on product_repo.release_id = release_tbl.id
    where repo.id = v_repo_id
    and release_tbl.id = v_release_id
    and pack.status >= 40;

    if v_pack_count < 1 then
      return 0.00;
	end if;
    select round(v_finish_pack_count/v_pack_count, 2) into v_process;
    return v_process;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION repo_complete_ratio(integer, integer)
  OWNER TO postgres;

--
ALTER TABLE license_auto.public.pack ADD project_url varchar(150);