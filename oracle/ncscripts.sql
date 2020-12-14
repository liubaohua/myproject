------------------------------------------------------
-- Export file for user NC5@ORCL                    --
-- Created by Administrator on 2019-11-13, 16:35:48 --
------------------------------------------------------

set define off
spool ncscripts.log

prompt
prompt Creating trigger TR_BD_CUBASDOC
prompt ===============================
prompt
create or replace trigger nc5.tr_bd_cubasdoc
  after update or delete
  on bd_cubasdoc
  for each row
declare
 nextid number;
 isdelete number;
 cusbasid varchar(20);
 pk_areacl1 varchar(20);
 custcode1 varchar(30);
 custname1 varchar(100);
 corpid varchar(4);
begin
select max(id)+1 into nextid from oa.formmain_0212;
if nextid is null then
  nextid :=1;
  end if;
cusbasid := :new.pk_cubasdoc;
corpid := :new.pk_corp;
pk_areacl1 := :new.pk_areacl;
custcode1 := :new.custcode;
custname1 := :new.custname;

isdelete := 0;
if deleting then
cusbasid := :old.pk_cubasdoc;
pk_areacl1 := :old.pk_areacl;
corpid := :old.pk_corp;
custcode1 := :old.custcode;
custname1 := :old.custname;
isdelete :=1;
end if;

if :new.dr=1 or :new.sealflag='Y' then
   isdelete :=1;
end if;

merge into oa.formmain_0212 t using
  (select nextid as id,1 as state,'5155926295238168506' as START_MEMBER_ID,sysdate as START_DATE,
  0 APPROVE_MEMBER_ID,null APPROVE_DATE,0 FINISHEDFLAG,0 RATIFYFLAG,0 RATIFY_MEMBER_ID,null RATIFY_DATE,
  0 sort,cl.areaclcode as FIELD0001,cl.areaclname as FIELD0002,u.id as FIELD0003,cusbasid FIELD0004, custcode1 as FIELD0005,custname1 FIELD0006,0 FIELD0007
  from 
 nc5.bd_areacl cl,nc5.bd_corp c,oa.org_unit u,nc5.bd_cumandoc m
where pk_areacl1=cl.pk_areacl and m.pk_cubasdoc=cusbasid
--and m.pk_cubasdoc=b.pk_cubasdoc 
and m.custflag in (1,3)
and c.pk_corp=m.pk_corp 
--and nvl(b.dr,0)=0 
and u.name=c.unitname
and nvl(cl.dr,0)=0 and nvl(c.dr,0)=0 
) t1
  on (t1.FIELD0003=t.FIELD0003 and t1.FIELD0004=t.FIELD0004)
when matched then
update set FIELD0001=t1.FIELD0001,FIELD0002=t1.FIELD0002,FIELD0005=t1.FIELD0005,FIELD0006=t1.FIELD0006,FIELD0007=isdelete
when not matched then
insert(id,
state,
start_member_id,
start_date,
approve_member_id,
approve_date,
finishedflag,
ratifyflag,
ratify_member_id,
ratify_date,
sort,
field0001,
field0002,
field0003,
field0004,
field0005,
field0006,
field0007
) values (oa.seq_0212_customer.nextval,
t1.state,
t1.start_member_id,
t1.start_date,
t1.approve_member_id,
t1.approve_date,
t1.finishedflag,
t1.ratifyflag,
t1.ratify_member_id,
t1.ratify_date,
t1.sort,
t1.field0001,
t1.field0002,
t1.field0003,
t1.field0004,
t1.field0005,
t1.field0006,
t1.field0007);

end tr_bd_cubasdoc;
/

prompt
prompt Creating trigger TR_BD_CUMANDOC
prompt ===============================
prompt
create or replace trigger nc5.tr_bd_cumandoc
  after insert or update or delete
  on bd_cumandoc
  for each row
declare
 nextid number;
 isdelete number;
 cusmanid varchar(20);
 cusbasid varchar(20);
 corpid varchar(4);
 custflag1 number;
 pk_areacl1 varchar(20);
 custcode1 varchar(30);
 custname1 varchar(100);
 
begin
select max(id)+1 into nextid from oa.formmain_0212;
if nextid is null then
  nextid :=1;
  end if;
cusmanid := :new.pk_cumandoc;
cusbasid := :new.pk_cubasdoc;
corpid := :new.pk_corp;
custflag1 := :new.custflag;
isdelete := 0;
if deleting then
  cusmanid := :old.pk_cumandoc;
  cusbasid := :old.pk_cubasdoc;
  corpid := :old.pk_corp;
  
custflag1 := :old.custflag;
  isdelete :=1;
end if;

if :new.dr=1 or :new.sealflag='Y' then --封存操作
   isdelete :=1;
end if;

select pk_areacl,custcode,custname into pk_areacl1,custcode1,custname1 from bd_cubasdoc where pk_cubasdoc=cusbasid;


merge into oa.formmain_0212 t using
	(select nextid as id,1 as state,'5155926295238168506' as START_MEMBER_ID,sysdate as START_DATE,
	0 APPROVE_MEMBER_ID,null APPROVE_DATE,0 FINISHEDFLAG,0 RATIFYFLAG,0 RATIFY_MEMBER_ID,null RATIFY_DATE,
  0 sort,cl.areaclcode as FIELD0001,cl.areaclname as FIELD0002,u.id as FIELD0003,cusbasid FIELD0004, custcode1 as FIELD0005,custname1 FIELD0006,0 FIELD0007
  from  nc5.bd_cubasdoc b,
  nc5.bd_areacl cl,nc5.bd_corp c,oa.org_unit u--,nc5.bd_cumandoc m
where pk_areacl1=cl.pk_areacl 
and b.pk_cubasdoc=cusbasid
--and cusbasid=m.pk_cubasdoc 
and custflag1 in (1,3)
and c.pk_corp=corpid----m.pk_corp --and nvl(b.dr,0)=0
and u.name=c.unitname
and nvl(cl.dr,0)=0 and nvl(c.dr,0)=0  ) t1
  on (t1.FIELD0003=t.FIELD0003 and t1.FIELD0004=t.FIELD0004)
when matched then
update set FIELD0001=t1.FIELD0001,FIELD0002=t1.FIELD0002,FIELD0005=t1.FIELD0005,FIELD0006=t1.FIELD0006,FIELD0007=isdelete
when not matched then
insert(id,
state,
start_member_id,
start_date,
approve_member_id,
approve_date,
finishedflag,
ratifyflag,
ratify_member_id,
ratify_date,
sort,
field0001,
field0002,
field0003,
field0004,
field0005,
field0006,
field0007
) values (oa.seq_0212_customer.nextval,
t1.state,
t1.start_member_id,
t1.start_date,
t1.approve_member_id,
t1.approve_date,
t1.finishedflag,
t1.ratifyflag,
t1.ratify_member_id,
t1.ratify_date,
t1.sort,
t1.field0001,
t1.field0002,
t1.field0003,
t1.field0004,
t1.field0005,
t1.field0006,
t1.field0007);

end tr_bd_cumandoc;
/

prompt
prompt Creating trigger TR_BD_DEPTDOC
prompt ==============================
prompt
create or replace trigger nc5.tr_bd_deptdoc
before insert or update
on bd_deptdoc
for each row
begin
 select c.unitcode||:new.deptcode into :new.cfulldeptcode from bd_corp c where c.pk_corp=:new.pk_corp;
end;
/

prompt
prompt Creating trigger TR_CONTRACT
prompt ============================
prompt
create or replace trigger nc5.tr_contract
before insert or update
on pm_cm_contract
for each row
begin
  insert into pm_oa_temp(bill,seq) values ('contract',seqtemp.nextval);
end;
/

prompt
prompt Creating trigger TR_FDC_BD_PROJECT
prompt ==================================
prompt
create or replace trigger nc5.tr_fdc_bd_project
  after update or delete
  on fdc_bd_project
  for each row
declare
 nextid number;
 isdelete number;
 projectid varchar(20);
 projcode varchar(30);
 projname varchar(50);
begin
select max(id)+1 into nextid from oa.formmain_0214;
if nextid is null then
  nextid :=1;
end if;
projectid := :new.pk_project;
projcode := :new.vcode;
projname := :new.vname;
isdelete := 0;
if deleting then
  projectid := :old.pk_project;
  projcode := :old.vcode;
  projname := :old.vname;
  isdelete :=1;
end if;

if :new.dr=1 or :new.bisclosed='Y' then --逻辑删除或关闭项目
   isdelete :=1;
end if;

merge into oa.formmain_0214 t using
  (select nextid as id,1 as state,'5155926295238168506' as START_MEMBER_ID,sysdate as START_DATE,
  0 APPROVE_MEMBER_ID,null APPROVE_DATE,0 FINISHEDFLAG,0 RATIFYFLAG,0 RATIFY_MEMBER_ID,null RATIFY_DATE,
  0 sort,p.pk_project,projcode as FIELD0001,projname as FIELD0002,0 as FIELD0003,u.id as FIELD0004,p.pk_project as FIELD0005,u.code as unitcode
  from fdc_bd_project_corp p,bd_corp co,oa.org_unit u
  where p.pk_project= projectid and nvl(:new.bisfinished,'N')='N' and nvl(:new.bisclosed,'N')='N'
  and co.pk_corp=p.pk_corp and u.name=co.unitname) t1
  on (t1.pk_project=t.FIELD0005 and t1.FIELD0004=t.FIELD0004)
when matched then
update set FIELD0001=t1.FIELD0001,FIELD0002=t1.FIELD0002,FIELD0003=isdelete
when not matched then
insert(id,
state,
start_member_id,
start_date,
approve_member_id,
approve_date,
finishedflag,
ratifyflag,
ratify_member_id,
ratify_date,
sort,
field0001,
field0002,
field0003,
field0004,
field0005,
unitcode
) values (oa.seq_0212_customer.nextval,
t1.state,
t1.start_member_id,
t1.start_date,
t1.approve_member_id,
t1.approve_date,
t1.finishedflag,
t1.ratifyflag,
t1.ratify_member_id,
t1.ratify_date,
t1.sort,
t1.field0001,
t1.field0002,
t1.field0003,
t1.field0004,
t1.field0005,
t1.unitcode);

end tr_fdc_bd_project;
/

prompt
prompt Creating trigger TR_FDC_BD_PROJECT_CORP
prompt =======================================
prompt
create or replace trigger nc5.tr_fdc_bd_project_corp
  after insert or update or delete
  on fdc_bd_project_corp
  for each row
declare
 nextid number;
 isdelete number;
 projectid varchar(20);
 corpid varchar(4);
begin
select max(id)+1 into nextid from oa.formmain_0214;
if nextid is null then
  nextid :=1;
end if;

projectid := :new.pk_project;
corpid := :new.pk_corp;
isdelete := 0;
if deleting then
  projectid := :old.pk_project;
  corpid := :old.pk_corp;
  isdelete :=1;
end if;

if :new.dr=1 then
   isdelete :=1;
end if;

merge into oa.formmain_0214 t using
  (select nextid as id,1 as state,'5155926295238168506' as START_MEMBER_ID,sysdate as START_DATE,
  0 APPROVE_MEMBER_ID,null APPROVE_DATE,0 FINISHEDFLAG,0 RATIFYFLAG,0 RATIFY_MEMBER_ID,null RATIFY_DATE,
  0 sort,p.pk_project,p.vcode as FIELD0001,p.vname as FIELD0002,0 as FIELD0003,u.id as FIELD0004,p.pk_project as FIELD0005,
  u.code as unitcode
  from fdc_bd_project p,bd_corp co,oa.org_unit u
  where p.pk_project= projectid and nvl(p.bisfinished,'N')='N' and nvl(p.bisclosed,'N')='N'
  and co.pk_corp= corpid and u.name=co.unitname) t1
  on (t1.pk_project=t.FIELD0005 and t1.FIELD0004=t.FIELD0004)
when matched then
update set FIELD0001=t1.FIELD0001,FIELD0002=t1.FIELD0002,FIELD0003=isdelete
when not matched then
insert(id,
state,
start_member_id,
start_date,
approve_member_id,
approve_date,
finishedflag,
ratifyflag,
ratify_member_id,
ratify_date,
sort,
field0001,
field0002,
field0003,
field0004,
field0005,unitcode
) values (oa.seq_0212_customer.nextval,
t1.state,
t1.start_member_id,
t1.start_date,
t1.approve_member_id,
t1.approve_date,
t1.finishedflag,
t1.ratifyflag,
t1.ratify_member_id,
t1.ratify_date,
t1.sort,
t1.field0001,
t1.field0002,
t1.field0003,
t1.field0004,
t1.field0005,t1.unitcode);

end tr_fdc_bd_project_corp;
/

prompt
prompt Creating trigger TR_PM_BD_CONTTYPE
prompt ==================================
prompt
create or replace trigger nc5.tr_Pm_bd_conttype
  after insert or update or delete
  on Pm_bd_conttype
  for each row
declare
 nextid number;
 isdelete number;
 contypeid varchar(20);
 typecode varchar(30);
 typename varchar(30);
 iattr number;
begin
select max(id)+1 into nextid from oa.formmain_0216;
contypeid := :new.pk_conttype;
typecode := :new.vcode;
typename := :new.vname;
iattr := :new.iattribute;
isdelete := 0;
if nextid is null then
nextid :=1;
end if;
if deleting then
  contypeid := :old.pk_conttype;
  typecode := :old.vcode;
  typename := :old.vname;
  iattr := :old.iattribute;
  isdelete :=1;
end if;

if :new.dr=1 or :new.bisseal='Y' then
   isdelete :=1;
end if;

if length(typecode)= 2 then --一级不同步
  return;
end if;

merge into oa.formmain_0216 t using
  (select nextid as id,1 as state,'5155926295238168506' as START_MEMBER_ID,sysdate as START_DATE,
  0 APPROVE_MEMBER_ID,null APPROVE_DATE,0 FINISHEDFLAG,0 RATIFYFLAG,0 RATIFY_MEMBER_ID,null RATIFY_DATE,
  0 sort,typecode FIELD0001,typename FIELD0002,iattr as FIELD0003,0 FIELD0004,contypeid as FIELD0005 from dual) t1
  on (t1.FIELD0005=t.FIELD0005)
when matched then
update set FIELD0001=t1.FIELD0001,FIELD0002=t1.FIELD0002,FIELD0003=t1.FIELD0003,FIELD0004=isdelete
when not matched then
insert(id,
state,
start_member_id,
start_date,
approve_member_id,
approve_date,
finishedflag,
ratifyflag,
ratify_member_id,
ratify_date,
sort,
field0001,
field0002,
field0003,
field0004,
field0005
) values (t1.id,
t1.state,
t1.start_member_id,
t1.start_date,
t1.approve_member_id,
t1.approve_date,
t1.finishedflag,
t1.ratifyflag,
t1.ratify_member_id,
t1.ratify_date,
t1.sort,
t1.field0001,
t1.field0002,
t1.field0003,
t1.field0004,
t1.field0005);

end tr_Pm_bd_conttype;
/

prompt
prompt Creating trigger TR_PM_BD_NOCONTFEETYPE
prompt =======================================
prompt
create or replace trigger nc5.tr_pm_bd_nocontfeetype
  after insert or update or delete
  on pm_bd_nocontfeetype
  for each row
declare
 nextid number;
 isdelete number;
 contypeid varchar(20);
 typecode varchar(30);
 typename varchar(30);
 iattr number;
begin
select max(id)+1 into nextid from oa.formmain_0213;
contypeid := :new.pk_nocontfeetype;
typecode := :new.vcode;
typename := :new.vname;
isdelete := 0;
if nextid is null then
nextid :=1;
end if;
if deleting then
  contypeid := :old.pk_nocontfeetype;
  typecode := :old.vcode;
  typename := :old.vname;
  isdelete :=1;
end if;

if :new.dr=1 or :new.bisseal='Y' then
   isdelete :=1;
end if;

merge into oa.formmain_0213 t using
	(select nextid as id,1 as state,'5155926295238168506' as START_MEMBER_ID,sysdate as START_DATE,
	0 APPROVE_MEMBER_ID,null APPROVE_DATE,0 FINISHEDFLAG,0 RATIFYFLAG,0 RATIFY_MEMBER_ID,null RATIFY_DATE,
  0 sort,typecode as FIELD0001,typename as FIELD0002,0 FIELD0003,contypeid as field0004 from dual) t1
  on (t1.FIELD0004=t.FIELD0004)
when matched then
update set FIELD0001=t1.FIELD0001,FIELD0002=t1.FIELD0002,FIELD0003=isdelete
when not matched then
insert(id,
state,
start_member_id,
start_date,
approve_member_id,
approve_date,
finishedflag,
ratifyflag,
ratify_member_id,
ratify_date,
sort,
field0001,
field0002,
field0003,
field0004
) values (t1.id,
t1.state,
t1.start_member_id,
t1.start_date,
t1.approve_member_id,
t1.approve_date,
t1.finishedflag,
t1.ratifyflag,
t1.ratify_member_id,
t1.ratify_date,
t1.sort,
t1.field0001,
t1.field0002,
t1.field0003,
t1.field0004);

end tr_pm_bd_nocontfeetype;
/


spool off
