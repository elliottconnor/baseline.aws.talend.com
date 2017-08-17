INSERT INTO tac_quickstart.userrolereference
(dtype, e_version, user_user_id, userrole_role_id)
select 'UserRoleReference', 0, (select user.id from user where user.login='admin@company.com'), userrole.id  from userrole where name <> 'Administrator'

delete from userrolereference where e_id > 2

select * from user

select * from userrole

select * from userrolereference

select user.id from user where user.login='admin@company.com'
