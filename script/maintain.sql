-- 查看postgresql的连接数:
select * from pg_stat_activity;

-- 查看最大连接数限制:
show max_connections;

-- 查看为超级用户保留的连接数:
show superuser_reserved_connections;

-- kill process id
-- ps aux | grep mq_pack | awk '{print $2}' | xargs kill -9

-- Transfer manual data
update pack_manual  set homepage = null where homepage = '';
update pack_manual  set source_url = null where source_url = '';
update pack_manual  set license_url = null where license_url = '';
update pack_manual  set license = null where license = '';
update pack_manual  set unclear_license = null where unclear_license = '';
update pack_manual  set license_text = null where license_text = '';
update pack_manual  set cmt = null where cmt = '';

update pack as a
  set homepage = b.homepage,
  source_url = b.source_url,
  license_url = b.license_url,
  license = b.license,
  unclear_license = b.unclear_license,
  license_text = b.license_text,
  cmt = b.cmt,
  status = b.status
from pack_manual as b
where a.id = b.id;

-- Apache2.0 enqueue
update pack set status = 10 where id in (
select distinct on (name, version, lang) pack.* from pack
  join product_repo_pack c on c.pack_id = pack.id
  join product_repo t on t.id = c.product_repo_id
  where t.release_id = 10
  and pack.license = 'Apache2.0')

-- Kill procpid
SELECT
    pg_terminate_backend(procpid)
FROM
    pg_stat_activity
WHERE
    -- don't kill my own connection!
    procpid <> pg_backend_pid()
    -- don't kill the connections to other databases
    AND datname = 'database_name'
    ;

