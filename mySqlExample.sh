mysql -u root -pcommander -D commander -e "select * from ec_configuration_history;"
mysqladmin -u root -pcommander -f drop commander
mysqladmin -u root -pcommander -f create commander
mysql -u root -pcommander -D commander < /tmp/commander.sql
mysql -u root -pcommander -D commander -e "show databases;"
mysql -u root -pcommander -D commander -e "show tables;"
mysql --socket=/opt/data1/mysql/mysql.sock --user=root --password=commander -e "show variables; show grants for commander;"
mysql --socket=/opt/data1/mysql/mysql.sock --user=root --password=commander -e "show variables; set global max_user_connections = 0; flush privileges;"
mysql --socket=/opt/electriccloud/electriccommander/mysql/mysql.sock --user=root --password=commander -e "show databases; drop database commander; create database commander;"
mysql --socket=/opt/electriccloud/electriccommander/mysql/mysql.sock --user=root --password=commander < "/net/f2home/tkendig/Customers/support/Symbian/Zid103183/db_export_351_Fri Apr 1"
#mysql --socket=/opt/electriccloud/electriccommander/mysql/mysql.sock --user=root --password=commander -e "use commander; show tables; select * from ec_user; select DISTINCT owner from ec_session where expires >= CURRENT_DATE();"
#mysql --socket=/opt/electriccloud/electriccommander/mysql/mysql.sock --user=root --password=commander -e "use commander; show tables; select * from ec_user; select DISTINCT user_name from ec_session s, ec_session_auth sa, ec_authentication a where expires is not NULL and expires >= CURRENT_DATE() and sa.session_id=s.id and sa.authentication_id=a.id;"
mysql --socket=/opt/electriccloud/electriccommander/mysql/mysql.sock --user=root --password=commander -e "use commander; select owner, COUNT(owner) from ec_session GROUP BY owner;"
mysql --socket=/opt/electriccloud/electriccommander/mysql/mysql.sock --user=root --password=commander -e "use commander; select COUNT(*) from ec_job_step;"
mysql --socket=/opt/electriccloud/electriccommander/mysql/mysql.sock --user=root --password=commander -e "use commander; show table status from commander;"
mysql --socket=/opt/electriccloud/electriccommander/mysql/mysql.sock --user=root --password=commander -e "use commander; SELECT a.id, b.id, a.entity_id FROM   ec_session a, ec_session b WHERE  a.entity_type = 'jobStep' AND b.entity_type = 'jobStep' AND a.entity_id = b.entity_id AND a.id != b.id;"
