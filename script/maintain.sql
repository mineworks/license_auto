查看postgresql的连接数:
select * from pg_stat_activity;


查看最大连接数限制:
show max_connections;
 

查看为超级用户保留的连接数:
show superuser_reserved_connections ; 

