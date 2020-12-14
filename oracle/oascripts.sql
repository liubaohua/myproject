------------------------------------------------------
-- Export file for user OA@ORCL                     --
-- Created by Administrator on 2019-11-13, 16:34:45 --
------------------------------------------------------

set define off
spool oascripts.log

prompt
prompt Creating function SOAP_CALL
prompt ===========================
prompt
create or replace function oa.soap_call
  ( p_req_body       in varchar2
  , p_target_url in varchar2
  , p_soap_action in varchar2 default 'none'
  ) return xmltype
  is
    l_soap_request  varchar2(30000);
    l_soap_response varchar2(30000);
    http_req utl_http.req;
    http_resp utl_http.resp;
  begin
    l_soap_request := '<?xml version="1.0" encoding="UTF-8"?><env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"  xmlns:sn="http://service.webservice.nc/IMakeVoucher" >
    <env:Body>'|| p_req_body ||'</env:Body></env:Envelope>';
    http_req:= utl_http.begin_request
               ( p_target_url
               , 'POST'
               , 'HTTP/1.1'
               );
    utl_http.set_header(http_req, 'Content-Type', 'text/xml; charset=UTF8');
    utl_http.set_header(http_req, 'Content-Length', length(l_soap_request));
    utl_http.set_header(http_req, 'SOAPAction', p_soap_action);
    utl_http.write_text(http_req, l_soap_request);
    -- the actual call to the service is made here
    http_resp:= utl_http.get_response(http_req);
    utl_http.read_text(http_resp, l_soap_response);
    utl_http.end_response(http_resp);

    -- only return from the soap response - that is: the content of the body element in the SOAP envelope
    return XMLType.createXML(l_soap_response).extract('/env:Envelope/env:Body/child::node()'
                     , 'xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"');
  end;
/

prompt
prompt Creating function FN_NCSERVICE
prompt ==============================
prompt
CREATE OR REPLACE FUNCTION OA.FN_NCService(pk_billtype varchar2,pk_cont varchar2,iOaRecid number)
 RETURN clob AS
  l_response_call          XMLType;
  l_request_body           varchar2(1000);
  l_target_url             varchar2(500);
  l_NcResult            clob;
BEGIN
  l_target_url        := 'http://192.168.1.153:8096/uapws/service/nc.webservice.service.IMakeVoucher';
  l_request_body      :='<sn:makeVoucher><string>{pk_billtype:"'||pk_billtype||'",oa_recid:"'||iOaRecid||'",pk_cont:"'||pk_cont||'"}</string></sn:makeVoucher>';
  l_response_call := soap_call(l_request_body, l_target_url, 'sendtext');
  l_NcResult := l_response_call.extract('//return/text()').getStringVal();
  
  return l_NcResult;
end;
/

prompt
prompt Creating function FUN_GETPK_CUMANBYPKS
prompt ======================================
prompt
create or replace function oa.fun_getpk_cumanByPks(cPk_corp varchar2,cPk_cubasdoc varchar2)
 return varchar2 is
  strResult varchar2(20);
begin
   --供应商档案PK
select max(pk_cumandoc) into strResult from nc5.bd_cumandoc where custflag in (1,3)
    and pk_corp=cPk_corp and pk_cubasdoc=cPk_cubasdoc;
  return strResult;
end fun_getpk_cumanByPks;
/

prompt
prompt Creating function FUN_GCHT_GETPK_CUMAN1
prompt =======================================
prompt
create or replace function oa.fun_gcht_getpk_cuman1(iBillid number) return varchar2 is
cPk_corp varchar(4);
cPK_cubasdoc varchar(20);
begin

select field0025,field0028 into cPk_corp,cPK_cubasdoc
from formmain_0208 f where f.id=iBillid;

return fun_getpk_cumanByPks(cPk_corp ,cPk_cubasdoc);

end fun_gcht_getpk_cuman1;
/

prompt
prompt Creating function FUN_GCHT_GETPK_CUMAN2
prompt =======================================
prompt
create or replace function oa.fun_gcht_getpk_cuman2(iBillid number) return varchar2 is
cPk_corp varchar(4);
cPK_cubasdoc varchar(20);
begin

select field0025,field0029 into cPk_corp,cPK_cubasdoc
from formmain_0208 f where f.id=iBillid;

return fun_getpk_cumanByPks(cPk_corp ,cPk_cubasdoc);

end fun_gcht_getpk_cuman2;
/

prompt
prompt Creating function FUN_GETPK_CONT
prompt ================================
prompt
create or replace function oa.fun_getpk_cont(cPk_corp varchar2,vPk_BillType varchar2,vContName varchar2)
 return varchar2 is
  strResult varchar2(20);
begin

  select max(d.pk_cont) into strResult from nc5.pm_cm_contract d
    where d.pk_corp=cPk_corp and nvl(d.dr,0)=0 and d.vname=vContName and d.pk_billtype=vPk_BillType;
    return   strResult;
end fun_getpk_cont;
/

prompt
prompt Creating function FUN_GETPK_CORP
prompt ================================
prompt
create or replace function oa.fun_getpk_corp(iOaCorpid number) return varchar2 is
  strResult varchar2(4);
begin
  select max(pk_corp) into strResult from nc5.bd_corp c,org_unit u
  where c.unitname=u.name and u.id=iOaCorpid
  and( u.code ='company' or u.code is null)  ;
  
  return strResult;
end fun_getpk_corp;
/

prompt
prompt Creating function FUN_GETPK_CUBASDOC
prompt ====================================
prompt
create or replace function oa.fun_getpk_cubasdoc(iOaCorpid number,cCusName varchar2) return varchar2 is
  strResult varchar2(20);
begin

select max(FIELD0004) into strResult from formmain_0212 cus
where cus.FIELD0006 = cCusName and cus.field0003=iOaCorpid;

  return strResult;
end fun_getpk_cubasdoc;
/

prompt
prompt Creating function FUN_GETPK_DEPTDOC
prompt ===================================
prompt
create or replace function oa.fun_getpk_deptdoc(cPk_corp varchar2,iOaDeptId number)
 return varchar2 is
  strResult varchar2(20);
begin

  select max(d.pk_deptdoc) into strResult from nc5.bd_deptdoc d ,org_unit u
    where d.pk_corp=cPk_corp  and u.code=d.cfulldeptcode and
     u.id = iOaDeptId;
    return   strResult;
end fun_getpk_deptdoc;
/

prompt
prompt Creating function FUN_GETPK_DEPTFROMNCBYCODE
prompt ============================================
prompt
create or replace function oa.fun_getpk_deptFromNCByCode(cFullDeptCode1 varchar2) return varchar2 is
  strResult varchar2(20);
begin
 select max(d.pk_deptdoc) into strResult
   from nc5.bd_deptdoc d where d.cfulldeptcode=cFullDeptCode1;
  return strResult;
end fun_getpk_deptFromNCByCode;
/

prompt
prompt Creating function FUN_GETPK_DEPTFROMNCBYID
prompt ==========================================
prompt
create or replace function oa.fun_getpk_deptFromNCByID(iOaDeptId varchar2) return varchar2 is
  strResult varchar2(20);
begin
  select  max(d.pk_deptdoc) into strResult
   from oa.org_unit u1 inner join nc5.bd_deptdoc d on d.cfulldeptcode=u1.code
   where u1.id=iOaDeptId;
  return strResult;
end fun_getpk_deptFromNCByID;
/

prompt
prompt Creating function FUN_GETPK_PROJECT
prompt ===================================
prompt
create or replace function oa.fun_getpk_project(iOaCorpid number,cProjName varchar2) return varchar2 is
  strResult varchar2(20);
begin

select max(FIELD0005) into strResult from formmain_0214 proj
where proj.FIELD0002 = cProjName --项目名称
  and proj.FIELD0004  =iOaCorpid;--公司id

  return strResult;
end fun_getpk_project;
/

prompt
prompt Creating function FUN_GETPK_PROJECTTYPE
prompt =======================================
prompt
create or replace function oa.fun_getpk_projecttype(cProjectTypeName varchar2) return varchar2 is
  strResult varchar2(20);
begin

select max(FIELD0005) into strResult from formmain_0216 conttype
where conttype.FIELD0002=cProjectTypeName;

  return strResult;
end fun_getpk_projecttype;
/

prompt
prompt Creating function FUN_GETPK_PSNDOCBYID
prompt ======================================
prompt
create or replace function oa.fun_getpk_psndocById(cPk_corp varchar2,iOaPersonId number)
 return varchar2 is
  strResult varchar2(20);
begin

  select max(ry.pk_psndoc) into strResult from nc5.bd_psndoc ry,org_member m
    where ry.pk_corp=cPk_corp and ry.psnname=m.name and m.id=iOaPersonId;
    return   strResult;
end fun_getpk_psndocById;
/

prompt
prompt Creating function FUN_GETPK_PSNDOCBYNAME
prompt ========================================
prompt
create or replace function oa.fun_getpk_psndocByName(cPk_corp varchar2,cPersonName varchar2)
 return varchar2 is
  strResult varchar2(20);
begin

  select max(ry.pk_psndoc) into strResult from nc5.bd_psndoc ry
    where ry.pk_corp=cPk_corp and ry.psnname= cPersonName;
    return   strResult;
end fun_getpk_psndocByName;
/

prompt
prompt Creating function FUN_GETPK_USERBYNAME
prompt ======================================
prompt
create or replace function oa.fun_getpk_userByName(cPersonName varchar2)
 return varchar2 is
  strResult varchar2(20);
begin
select max(yh.cuserid) into strResult from nc5.sm_user yh
where yh.user_name = cPersonName;
    return   strResult;
end fun_getpk_userByName;
/

prompt
prompt Creating function FUN_GETPK_USERBYOAID
prompt ======================================
prompt
create or replace function oa.fun_getpk_userByOaId(iUserid number)
 return varchar2 is
  strResult varchar2(20);
begin
select max(yh.cuserid) into strResult from org_member m3
left join nc5.sm_user yh on yh.user_name=m3.name
where m3.id = iUserid;
    return   strResult;
end fun_getpk_userByOaId;
/

prompt
prompt Creating procedure PROC_GET_RESOURCE_LOCK
prompt =========================================
prompt
CREATE OR REPLACE PROCEDURE OA.PROC_GET_RESOURCE_LOCK(
	newLockId IN LONG, 
	userId IN LONG, 
	lFrom IN VARCHAR2, 
	loginTime IN LONG, 
	moduleId IN VARCHAR2, 
	resourceId IN LONG, 
	action IN INTEGER,
	lockTime IN LONG,
	expireTime IN LONG,
	success OUT INTEGER
) IS
	
		lockId LONG;
		ownerId LONG;
		curExpireTime LONG;
		lockAction INTEGER;
		loginFrom VARCHAR2(100);
	
	begin
		success := 0;

		BEGIN

		if(action <> -1)
			then
				select ID,OWNER,EXPIREATION_TIMEMILLIS,LOGIN_FROM,ACTION into lockId, ownerId,curExpireTime,loginFrom,lockAction from ctp_lock where RESOURCE_ID=resourceId and (ACTION=action or ACTION=-1);
			else
				select ID,OWNER,EXPIREATION_TIMEMILLIS,LOGIN_FROM,ACTION into lockId, ownerId,curExpireTime,loginFrom,lockAction from ctp_lock where RESOURCE_ID=resourceId;
		end if;
		
		EXCEPTION WHEN NO_DATA_FOUND THEN
			null;
		END;
		
		BEGIN
		
		if(lockId is null)
			then 			
				insert into ctp_lock(ID,OWNER,MODULE,RESOURCE_ID,ACTION,LOGIN_TIMEMILLIS,LOCK_TIMEMILLIS,EXPIREATION_TIMEMILLIS,LOGIN_FROM)VALUES(newLockId,userId,moduleId,resourceId,action,loginTime,lockTime,expireTime,lFrom);
				success := 1;
			else
				if(ownerId = userId and lFrom = loginFrom)
					then 
						update ctp_lock set LOGIN_TIMEMILLIS=loginTime,LOCK_TIMEMILLIS=lockTime,EXPIREATION_TIMEMILLIS=expireTime,ACTION=action where ID=lockId;
						success := 1;
					else
						if(curExpireTime < lockTime)
							then
								delete from ctp_lock where ID=lockId;
								insert into ctp_lock(ID,OWNER,MODULE,RESOURCE_ID,ACTION,LOGIN_TIMEMILLIS,LOCK_TIMEMILLIS,EXPIREATION_TIMEMILLIS,LOGIN_FROM)VALUES(newLockId,userId,moduleId,resourceId,action,loginTime,lockTime,expireTime,lFrom);
								success := 1;
							else
								success := 0;
						end if;
				end if;
		end if;
		commit;
		EXCEPTION WHEN OTHERS THEN
			success := 0;
			rollback;
		END;
			
	end PROC_GET_RESOURCE_LOCK;
/

prompt
prompt Creating procedure PROC_NEXTSERIALNUMBER
prompt ========================================
prompt
CREATE OR REPLACE PROCEDURE OA.proc_nextserialnumber (
    sid        IN INTEGER,
    readonly   IN INTEGER,
    rnextval   OUT INTEGER
) IS

    svalue             INTEGER;
    rulreset           INTEGER;
    minval             INTEGER;
    todbval            INTEGER;
    maxval             INTEGER;
    digitnum           INTEGER;
    currentyear        INTEGER;
    currentmonth       INTEGER;
    currentday         INTEGER;
    markyear           INTEGER;
    markmonth          INTEGER;
    markday            INTEGER;
    scurrentmarkdate   DATE;
    currentdate        DATE;
BEGIN
    SELECT
        value,
        current_mark_date,
        rule_reset,
        min_value,
        digit
    INTO
        svalue,scurrentmarkdate,rulreset,minval,digitnum
    FROM
        form_serial_number
    WHERE
        id = sid
    FOR UPDATE;

    IF
        ( svalue IS NULL )
    THEN
        svalue := 1;
    END IF;
    rnextval := svalue;
    currentdate := SYSDATE;
    currentyear := extract ( YEAR FROM currentdate );
    currentmonth := extract ( MONTH FROM currentdate );
    currentday := extract ( DAY FROM currentdate );
    markyear := extract ( YEAR FROM scurrentmarkdate );
    markmonth := extract ( MONTH FROM scurrentmarkdate );
    markday := extract ( DAY FROM scurrentmarkdate );


    IF
        ( ( ( rulreset = 1 ) AND ( currentyear != markyear ) ) OR ( ( rulreset = 2 ) AND ( currentyear != markyear OR currentmonth != markmonth ) ) OR ( ( rulreset = 3 ) AND ( currentyear
!= markyear OR currentmonth != markmonth OR currentday != markday ) ) )
    THEN
        IF
            ( minval IS NOT NULL )
        THEN
            rnextval := minval;
        ELSE
            rnextval := 1;
        END IF;
    END IF;

    IF
        ( readonly = 0 )
    THEN

        maxval := power(10,digitnum);
        IF
            ( rnextval >= ( maxval - 1 ) )
        THEN
            IF
                ( minval IS NULL )
            THEN
                todbval := 1;
            ELSE
                todbval := minval;
            END IF;

        ELSE
            todbval := rnextval + 1;
        END IF;

        UPDATE form_serial_number
            SET
                value = todbval,
                current_mark_date = currentdate
        WHERE
            id = sid;

    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END proc_nextserialnumber;
/

prompt
prompt Creating procedure SP_APPLYPAY2NC
prompt =================================
prompt
create or replace procedure oa.sp_applypay2nc(pk_payer_man varchar,pk_receiver_man varchar,pk_jbr varchar,pk_jbbm varchar,pk_zdr varchar,pk_zdbm varchar,oa_tabname varchar,iOaBillid number)
as
nContBaseMny1 number;
vPk_billtype varchar(4);
--pk_cont1 varchar(20);
pragma AUTONOMOUS_TRANSACTION;
begin

delete from nc5.pm_pa_payapply_oa where oa_recid=iOaBillid;
select max(ncontbasemny),max(pk_billtype) into nContBaseMny1,vPk_billtype from nc5.pm_cm_contract 
where pk_cont = (select f.field0036 from formmain_0206 f where f.id=iOaBillId);



--select top 1 ncontbasemny,pk_billtype,pk_cont into nContBaseMny1,vPk_billtype,pk_cont1 from nc5.pm_cm_contract where 
--icontstatus in (1,4) and pk_billtype in ('9241','9242','9243') 
--and nvl(dr,0)=0 and vname in (select f.field0008 from formmain_0206 f where f.id=iOaBillId);

insert into nc5.pm_pa_payapply_oa(pk_payapply,
  bisclose,bisholddecuct,bisincludemate,bisinitbill,bisoffset,
  bisoverplanmny,bispreapply,bisprojpledge,bisreturn,bisupload,biswardeduct,biswarranty,
    pk_contract,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,
    dapprovedate,dbilldate,dmakedate,
    ncontbasemny,ncontorigmny,
    nactapplyorigmny,napplybasemny,nactapplybasemny,napplyorigmny,
    pk_conttype,pk_cumandoc,pk_cubasdoc,pk_second,pk_secondbase,
    vbillno,
    vmemo,
    voperatorid,PK_REALDEPT,oa_tabname,oa_recid,oa_billno,
    pk_basetype,pk_origintype,nbaserate,iuploadmode
    ,iholdtype
    ,vbillstatus,
    biscontsettle,vdef1,
    vlastbilltype,vlastbillid,vdef10
    )
  select seq_pay.nextval as pk_payapply,
  'N','N','N','N','N','N','N','N','N','N','N','N',
  f.field0036 as pk_contract,'9261' as Pk_billtype,f.field0034 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
  f.field0037 as pk_project,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0021,'yyyy-mm-dd') as dbilldate,
  to_char(f.field0021,'yyyy-mm-dd') as dmakedate,
  nContBaseMny1 as ncontbasemny,nContBaseMny1 as ncontorigmny,
  f.field0026 as nactapplyorigmny,f.field0026 as napplybasemny,f.field0026 as nactapplybasemny,f.field0026 as napplyorigmny,
  f.field0035 as pk_conttype,pk_payer_man as pk_first,f.field0038 as pk_cubasdoc,pk_receiver_man as pk_second,f.field0039 as pk_secondbase,
  f.field0001 as vbillno,
  f.field0020 as vmemo,--f.field0012 as vorigrealcontno,
  pk_zdr as voperatorid,pk_zdbm as PK_REALDEPT,
  oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
  '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
  1 as nbaserate,1 as iuploadmode,
  0 as iholdtype
  ,1 as vbillstatus,f.field0041 as biscontsettle,f.field0040 as vdef1,--是否水电气请款
  vPk_billtype as vlastbilltype,f.field0036 as vlastbillid,(select max(billno) from nc5.pm_oa_billno where oa_recid=f.id )
  FROM formmain_0206 f where f.id=iOaBillId;
  commit;

end;
/

prompt
prompt Creating procedure SP_NOCONTPAY2NC
prompt ==================================
prompt
create or replace procedure oa.sp_nocontpay2nc(pk_receiver_bas varchar,pk_receiver_man varchar,pk_jbr varchar,pk_jbbm varchar,pk_zdr varchar,pk_zdbm varchar,oa_tabname varchar,iOaBillid number)
as
pragma AUTONOMOUS_TRANSACTION;
begin

insert into nc5.pm_pa_noncontfee_oa(pk_noncontfee,pk_project,Pk_billtype,pk_corp,vdeptid,vdealerid,noncontfeetype,
    dapprovedate,dbilldate,dmakedate,
    nsumapplybasemny,nsumapplyorigmny,
    pk_cubasdoc,pk_cumandoc,vbillno,
    voperatorid,vrealdeptid,
    oa_tabname,oa_recid,oa_billno,
    pk_basetype,pk_origintype,nbaserate,iuploadmode,
    ictrlstatus,vbillstatus,bisclose,bisinitbill,bissendplat,bissubstituefee,vdef10
    )
  select seq_npay.nextval as pk_noncontfee,f.field0021 as pk_project,'9262',f.field0016 as pk_corp,
  pk_jbbm as vdeptid,pk_jbr as vdealerid,field0017 as noncontfeetype,
  to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0012,'yyyy-mm-dd') as dbilldate,
  to_char(f.field0012,'yyyy-mm-dd') as dmakedate,
  f.field0004 as nsumapplybasemny,f.field0004 as nsumapplyorigmny,
  pk_receiver_bas as pk_cubasdoc,pk_receiver_man as pk_cumandoc,
  f.field0001 as vbillno,
  pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
  oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
  '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
  1 as nbaserate,1 as iuploadmode,
  0 as ictrlstatus,1 as vbillstatus,'N' as bisclose,'N' as bisinitbill,'N' as bissendplat,'N' as bissubstituefee,(select max(billno) from nc5.pm_oa_billno where oa_recid=f.id ) as billno
  FROM formmain_0201 f where f.id=iOaBillId;
 commit;
end;
/

prompt
prompt Creating procedure SP_SAVEBILLNO
prompt ================================
prompt
create or replace procedure oa.sp_savebillno(pk_billtype varchar,iOaBillid number,billno varchar)
as
pragma AUTONOMOUS_TRANSACTION;
begin


--更新 流水号 
if pk_billtype <='9249' then
update nc5.pm_cm_contract set vdef10=billno where vreserve20=iOaBillid;
commit;
end if;
if pk_billtype ='9261' then
update nc5.pm_pa_payapply set vdef10=billno where vreserve10=iOaBillid;
commit;
end if;
if pk_billtype ='9262' then
update nc5.pm_pa_noncontfee set vdef10=billno where vreserve10=iOaBillid;
commit;
end if;

end;
/

prompt
prompt Creating procedure SP_SYNC_CUSTOMER
prompt ===================================
prompt
create or replace procedure oa.sp_sync_customer as
begin
merge into oa.formmain_0212 t using 
  (select distinct (case when b.sealflag='Y' or b.dr=1 then 1 else 0 end) as isdelete,1 as state,
  '5155926295238168506' as START_MEMBER_ID,sysdate as START_DATE,
  0 APPROVE_MEMBER_ID,null APPROVE_DATE,0 FINISHEDFLAG,0 RATIFYFLAG,0 RATIFY_MEMBER_ID,null RATIFY_DATE,
  0 sort,cl.areaclcode as FIELD0001,cl.areaclname as FIELD0002,u.id as FIELD0003,b.pk_cubasdoc FIELD0004,
  b.custcode as FIELD0005,b.custname FIELD0006,0 FIELD0007
  from nc5.bd_cubasdoc b,nc5.bd_areacl cl,nc5.bd_corp c,nc5.bd_cumandoc cm,oa.org_unit u
where b.pk_areacl=cl.pk_areacl and cm.pk_cubasdoc=b.pk_cubasdoc and c.pk_corp=cm.pk_corp
and nvl(b.dr,0)=0 and u.code=c.unitcode and cm.custflag in (1,3)
and nvl(cl.dr,0)=0 and nvl(c.dr,0)=0 ) t1 
  on (t1.FIELD0003=t.FIELD0003 and t1.FIELD0004=t.FIELD0004)
when matched then
update set FIELD0001=t1.FIELD0001,FIELD0002=t1.FIELD0002,FIELD0005=t1.FIELD0005,FIELD0006=t1.FIELD0006,FIELD0007=t1.isdelete
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
) values (seq_0212_customer.nextval,
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
end sp_sync_customer;
/

prompt
prompt Creating procedure SYNC_FK
prompt ==========================
prompt
create or replace procedure oa.sync_fk(iOaBillId number,bRevoke number)
as

iJbPersonId number;
iJbDeptId number;
iZdPersonId number;
iZdDeptId number;
pk_jbr varchar(20);--经办人NCPK
pk_jbbm varchar(20);--经办部门NCPK
pk_zdr varchar(20);--制单人NCPK
pk_zdbm varchar(20);--制单部门NCPK
sPk_corp varchar(4);

oa_tabname varchar(15);--OA表名
can_delete number:=0;--能否删除（反操作）

pk_payer_bas varchar(20);--付款NCPK
pk_receiver_bas varchar(20);--收款NCPK
pk_payer_man varchar(20);--付款NCPK
pk_receiver_man varchar(20);--收款NCPK
vNCResult clob;
begin

  if bRevoke = 1 then
    select 1 into can_delete from nc5.pm_pa_payapply a where a.oa_recid=iOaBillId and a.oa_tabname=oa_tabname

     and nvl(dr,0)=0;
    if can_delete=1 then
      raise_application_error(-20001,'已有相关修订单记录不能删除');
      return;
    end if;
    update nc5.pm_pa_payapply a set a.dr=1 where a.oa_recid=iOaBillId and a.oa_tabname=oa_tabname;
    return;
  end if;

select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0034 as sPk_corp,field0038 as pk_payer_bas,field0039 as pk_receiver_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_payer_bas,pk_receiver_bas
from formmain_0206 f where f.id=iOaBillId;


--经办部门NCPK
--select fun_getpk_deptdoc(sPk_corp,iJbPersonId) into pk_jbbm from dual;

--制单人NCPK
select fun_getpk_userByOaId(iZdPersonId) into pk_zdr  from dual;
--制单部门NCPK
select fun_getpk_deptFromNCByID(iZdDeptId) into pk_zdbm  from dual;
--经办人PK
select fun_getpk_psndocById(sPk_corp,iJbPersonId) into pk_jbr from dual;
--经办部门NCPK
select fun_getpk_deptFromNCByID(iJbDeptId) into pk_jbbm  from dual;
--付款方PK
select fun_getpk_cumanByPks(sPk_corp,pk_payer_bas) into pk_payer_man from dual;
--收款方PK
select fun_getpk_cumanByPks(sPk_corp,pk_receiver_bas) into pk_receiver_man from dual;

  sp_applypay2nc(pk_payer_man,pk_receiver_man,pk_jbr,pk_jbbm,pk_zdr,pk_zdbm,oa_tabname,iOaBillId);
  select FN_NCService('9261','',iOaBillId) into vNCResult from dual;
   insert into nc5.pm_oa_errlog(pk_billtype,pk_cont,oa_recid,message2) values ('9261','',iOaBillId,vNCResult);
end;
/

prompt
prompt Creating procedure SYNC_HT
prompt ==========================
prompt
create or replace procedure oa.sync_ht(sNcBillType varchar,iOaBillId number,bRevoke number)
as
iJbPersonId number;
iJbDeptId number;
iZdPersonId number;
iZdDeptId number;
pk_jbr varchar(20);--经办人NCPK
pk_jbbm varchar(20);--经办部门NCPK
pk_zdr varchar(20);--制单人NCPK
pk_zdbm varchar(20);--制单部门NCPK

sPk_corp varchar(4);
pk_first_bas varchar(20);
pk_second_bas varchar(20);
pk_first_man varchar(20);--甲方NCPK
pk_second_man varchar(20);--乙方NCPK
oa_tabname varchar(15);--OA表名
can_delete number:=0;--能否删除（反操作）
sPK_Cont varchar(20);
vNCResult clob;
pragma AUTONOMOUS_TRANSACTION;
begin

  if sNcBillType = '9241' then--工程合同
   oa_tabname:='formmain_0208';
  end if;
  if sNcBillType = '9242' then--材料合同
   oa_tabname:='formmain_0205';
  end if;
  if sNcBillType = '9243' then--其他合同
   oa_tabname:='formmain_0204';
  end if;
  if sNcBillType = '9244' then--工程合同修订
   oa_tabname:='formmain_0207';
  end if;
  if sNcBillType = '9245' then--材料合同修订
   oa_tabname:='formmain_0203';
  end if;
  if sNcBillType = '9246' then--其他合同修订
   oa_tabname:='formmain_0202';
  end if;

--撤回审批
  if bRevoke = 1 then
    select 1 into can_delete from nc5.pm_cm_contract a where a.oa_recid=iOaBillId and a.oa_tabname=oa_tabname
    and pk_origcont is not null and pk_modiconttype is not null and nvl(dr,0)=0;
    if can_delete=1 then
      raise_application_error(-20001,'已有相关修订单记录不能删除');
      return;
    end if;
    update nc5.pm_cm_contract a set a.dr=1 where a.oa_recid=iOaBillId and a.oa_tabname=oa_tabname;
    return;
  end if;

  if sNcBillType = '9241' then--工程合同
   oa_tabname:='formmain_0208';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0025 as sPk_corp,field0028 as pk_first_bas,field0029 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0208 f where f.id=iOaBillId;
  end if;
  if sNcBillType = '9242' then--材料合同
   oa_tabname:='formmain_0205';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0026 as sPk_corp,field0029 as pk_first_bas,field0030 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0205 f where f.id=iOaBillId;
end if;
  if sNcBillType = '9243' then--其他合同
   oa_tabname:='formmain_0204';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0025 as sPk_corp,field0028 as pk_first_bas,field0029 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0204 f where f.id=iOaBillId;
  end if;
  if sNcBillType = '9244' then--工程合同修订
   oa_tabname:='formmain_0207';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0035 as sPk_corp,field0038 as pk_first_bas,field0039 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0207 f where f.id=iOaBillId;
end if;
  if sNcBillType = '9245' then--材料合同修订
   oa_tabname:='formmain_0203';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0033 as sPk_corp,field0036 as pk_first_bas,field0037 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0203 f where f.id=iOaBillId;
  end if;
  if sNcBillType = '9246' then--其他合同修订
   oa_tabname:='formmain_0202';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0033 as sPk_corp,field0036 as pk_first_bas,field0037 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0202 f where f.id=iOaBillId;
  end if;
--正常审批结束
-- pk_origintype
-- pk_basetype
--vrealdeptid
--nbaserate 1
--iuploadmode 1
--isplitstate 0
--isourcetype 2
--ipaymode 0：按付款协议付款 3：按合同产值付款
--iholdtype 0
--ictrlstatus 0 1?
--biscountcost Y
--bisincludemodi Y
--新增保存 vbillstatus=8
--提交后 vbillstatus=3
--审核后 vbillstatus=1

--合同状态：icontstatus 未生效:0,生效:1,中止:6


--经办部门NCPK
--select fun_getpk_deptdoc(sPk_corp,iJbPersonId) into pk_jbbm from dual;

--制单人NCPK
select fun_getpk_userByOaId(iZdPersonId) into pk_zdr  from dual;
--制单部门NCPK
select fun_getpk_deptFromNCByID(iZdDeptId) into pk_zdbm  from dual;
--经办人PK
select fun_getpk_psndocById(sPk_corp,iJbPersonId) into pk_jbr from dual;
--经办部门NCPK
select fun_getpk_deptFromNCByID(iJbDeptId) into pk_jbbm  from dual;
--甲方PK
select fun_getpk_cumanByPks(sPk_corp,pk_first_bas) into pk_first_man from dual;
--乙方PK
select fun_getpk_cumanByPks(sPk_corp,pk_second_bas) into pk_second_man from dual;

    delete from nc5.pm_cm_contract_oa where oa_recid=iOaBillId;

    if sNcBillType = '9241' then-- 工程合同

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,
      vdigest,vpaydigest,vmemo,vorigrealcontno,voperatorid,vrealdeptid,
      vdef4,vdef3,vdef6,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select 1||lpad(cast(seq_cont.nextval as varchar(10)),19,'0') as pk_cont,sNcBillType,f.field0025 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0027 as pk_project,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0021,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0013 as nsignbasemny,f.field0013 as nsignorigmny,f.field0013 as ncontbasemny,f.field0013 as ncontcostbasemny,
    f.field0013 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0013 as ncontorigmny,
    f.field0026 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,(select max(billno) from nc5.pm_oa_billno where oa_recid=f.id ) as vbillno,
    f.field0008 as vname,f.field0017 as vdigest,f.field0018 as vpaydigest,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0032 as isstardecor,--是否红星美凯龙装修
    f.field0031 as islawidea,--是否需要律师审批
    f.field0030 as iswatercont,--是否水电气合同
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,f.field0001 as billcode
    FROM formmain_0208 f where f.id=iOaBillId;
  end if;

  if sNcBillType = '9244' then-- 工程合同修订

    select max(field0044) into sPK_Cont from formmain_0207 where id=iOaBillId;--原合同PK
    if sPK_Cont is null then
      select max(pk_cont) into sPK_Cont from nc5.pm_cm_contract where pk_billtype='9241' and icontstatus=1 and nvl(dr,0)=0
      and vname in (select field0008 from formmain_0207 where id=iOaBillId);
    end if;

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,pk_origcont,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,vorigname,
      vdigest,vpaydigest,vmodimemo,vmemo,vorigrealcontno,vrealcontno,voperatorid,vrealdeptid,
      vdef4,vdef3,vdef6,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select sPK_Cont as pk_cont,sNcBillType,f.field0035 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0037 as pk_project,sPK_Cont as pk_origcont,
    to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0027,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0025 as nsignbasemny,f.field0025 as nsignorigmny,f.field0025 as ncontbasemny,f.field0025 as ncontcostbasemny,f.field0025 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0025 as ncontorigmny,
    f.field0036 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0024 as vname,f.field0008 as vorigname,f.field0017 as vdigest,f.field0018 as vpaydigest,f.field0028 as vmodimemo,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,f.field0026 as vrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0031 as isstardecor,--是否红星美凯龙装修
    f.field0007 as islawidea,--是否需要律师审批
    f.field0006 as iswatercont,--是否水电气合同
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,(select max(billno) from nc5.pm_oa_billno where oa_recid=f.id ) as billcode
    FROM formmain_0207 f where f.id=iOaBillId;


  end if;

  if sNcBillType = '9242' then-- 材料合同

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,
      vdigest,vpaydigest,vmemo,vorigrealcontno,voperatorid,vrealdeptid,
      vdef3,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select 1||lpad(cast(seq_cont.nextval as varchar(10)),19,'0') as pk_cont,sNcBillType,f.field0026 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0028 as pk_project,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0021,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0013 as nsignbasemny,f.field0013 as nsignorigmny,
    f.field0013 as ncontbasemny,f.field0013 as ncontcostbasemny,f.field0013 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0013 as ncontorigmny,
    f.field0027 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0008 as vname,f.field0017 as vdigest,f.field0018 as vpaydigest,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0031 as islawidea,--是否需要律师审批
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,(select max(billno) from nc5.pm_oa_billno where oa_recid=f.id ) as billcode
    FROM formmain_0205 f where f.id=iOaBillId;
  end if;

  if sNcBillType = '9245' then-- 材料合同修订

      select max(field0040) into sPK_Cont from formmain_0203 where id=iOaBillId;--原合同PK
      if sPK_Cont is null then
         select max(pk_cont) into sPK_Cont from nc5.pm_cm_contract where pk_billtype='9242' and icontstatus=1 and nvl(dr,0)=0
         and vname in (select field0008 from formmain_0203 where id=iOaBillId);
      end if;

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,pk_origcont,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,vorigname,
      vdigest,vpaydigest,vmodimemo,vmemo,vorigrealcontno,vrealcontno,voperatorid,vrealdeptid,
      vdef3,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select sPK_Cont as pk_cont,sNcBillType,f.field0033 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0035 as pk_project,sPK_Cont as pk_origcont,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,
    to_char(f.field0027,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0025 as nsignbasemny,f.field0025 as nsignorigmny,--
    f.field0025 as ncontbasemny,f.field0025 as ncontcostbasemny,f.field0025 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0025 as ncontorigmny,
    f.field0034 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0024 as vname,f.field0008 as vorigname,f.field0017 as vdigest,f.field0018 as vpaydigest,f.field0028 as vmodimemo,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,f.field0026 as vrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0038 as islawidea,--是否需要律师审批
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,(select max(billno) from nc5.pm_oa_billno where oa_recid=f.id ) as billcode
    FROM formmain_0203 f where f.id=iOaBillId;
  end if;

  if sNcBillType = '9243' then-- 其他合同

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,
      vdigest,vpaydigest,vmemo,vorigrealcontno,voperatorid,vrealdeptid,
      vdef3,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select 1||lpad(cast(seq_cont.nextval as varchar(10)),19,'0') as pk_cont,sNcBillType,f.field0025 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0027 as pk_project,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0021,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0013 as nsignbasemny,f.field0013 as nsignorigmny,
    f.field0013 as ncontbasemny,f.field0013 as ncontcostbasemny,f.field0013 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0013 as ncontorigmny,
    f.field0026 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0008 as vname,f.field0017 as vdigest,f.field0018 as vpaydigest,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0031 as islawidea,--是否需要律师审批
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,(select max(billno) from nc5.pm_oa_billno where oa_recid=f.id ) as billcode
    FROM formmain_0204 f where f.id=iOaBillId;
  end if;

  if sNcBillType = '9246' then-- 其他合同修订

      select max(field0040) into sPK_Cont from formmain_0202 where id=iOaBillId;--原合同PK
      if sPK_Cont is null then
        select max(pk_cont) into sPK_Cont from nc5.pm_cm_contract where pk_billtype='9243' and icontstatus=1 and nvl(dr,0)=0
        and vname in (select field0008 from formmain_0202 where id=iOaBillId);
     end if;
    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,pk_origcont,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,vorigname,
      vdigest,vpaydigest,vmodimemo,vmemo,vorigrealcontno,vrealcontno,voperatorid,vrealdeptid,
      vdef3,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select sPK_Cont as pk_cont,sNcBillType,f.field0033 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0035 as pk_project,sPK_Cont as pk_origcont,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,
    to_char(f.field0027,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0025 as nsignbasemny,f.field0025 as nsignorigmny,
    f.field0025 as ncontbasemny,f.field0025 as ncontcostbasemny,f.field0025 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0025 as ncontorigmny,
    f.field0034 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0024 as vname,f.field0008 as vorigname,f.field0017 as vdigest,f.field0018 as vpaydigest,f.field0028 as vmodimemo,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,f.field0026 as vrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0038 as islawidea,--是否需要律师审批
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,(select max(billno) from nc5.pm_oa_billno where oa_recid=f.id ) as billcode
    FROM formmain_0202 f where f.id=iOaBillId;
  end if;
  commit;

  select FN_NCService(sNcBillType,sPK_Cont,iOaBillId) into vNCResult from dual;
  insert into nc5.pm_oa_errlog(pk_billtype,pk_cont,oa_recid,message2) values (sNcBillType,sPK_Cont,iOaBillId,vNCResult);
  commit;

end;
/

prompt
prompt Creating procedure SYNC_HT_TEST
prompt ===============================
prompt
create or replace procedure oa.sync_ht_test(sNcBillType varchar,iOaBillId number,bRevoke number)
as
iJbPersonId number;
iJbDeptId number;
iZdPersonId number;
iZdDeptId number;
pk_jbr varchar(20);--经办人NCPK
pk_jbbm varchar(20);--经办部门NCPK
pk_zdr varchar(20);--制单人NCPK
pk_zdbm varchar(20);--制单部门NCPK

sPk_corp varchar(4);
pk_first_bas varchar(20);
pk_second_bas varchar(20);
pk_first_man varchar(20);--甲方NCPK
pk_second_man varchar(20);--乙方NCPK
oa_tabname varchar(15);--OA表名
can_delete number:=0;--能否删除（反操作）
sPK_Cont varchar(20);
vNCResult clob;
pragma AUTONOMOUS_TRANSACTION;
begin

  if sNcBillType = '9241' then--工程合同
   oa_tabname:='formmain_0208';
  end if;
  if sNcBillType = '9242' then--材料合同
   oa_tabname:='formmain_0205';
  end if;
  if sNcBillType = '9243' then--其他合同
   oa_tabname:='formmain_0204';
  end if;
  if sNcBillType = '9244' then--工程合同修订
   oa_tabname:='formmain_0207';
  end if;
  if sNcBillType = '9245' then--材料合同修订
   oa_tabname:='formmain_0203';
  end if;
  if sNcBillType = '9246' then--其他合同修订
   oa_tabname:='formmain_0202';
  end if;

--撤回审批
  if bRevoke = 1 then
    select 1 into can_delete from nc5.pm_cm_contract a where a.oa_recid=iOaBillId and a.oa_tabname=oa_tabname
    and pk_origcont is not null and pk_modiconttype is not null and nvl(dr,0)=0;
    if can_delete=1 then
      raise_application_error(-20001,'已有相关修订单记录不能删除');
      return;
    end if;
    update nc5.pm_cm_contract a set a.dr=1 where a.oa_recid=iOaBillId and a.oa_tabname=oa_tabname;
    return;
  end if;

  if sNcBillType = '9241' then--工程合同
   oa_tabname:='formmain_0208';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0025 as sPk_corp,field0028 as pk_first_bas,field0029 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0208 f where f.id=iOaBillId;
  end if;
  if sNcBillType = '9242' then--材料合同
   oa_tabname:='formmain_0205';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0026 as sPk_corp,field0029 as pk_first_bas,field0030 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0205 f where f.id=iOaBillId;
end if;
  if sNcBillType = '9243' then--其他合同
   oa_tabname:='formmain_0204';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0025 as sPk_corp,field0028 as pk_first_bas,field0029 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0204 f where f.id=iOaBillId;
  end if;
  if sNcBillType = '9244' then--工程合同修订
   oa_tabname:='formmain_0207';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0035 as sPk_corp,field0038 as pk_first_bas,field0039 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0207 f where f.id=iOaBillId;
end if;
  if sNcBillType = '9245' then--材料合同修订
   oa_tabname:='formmain_0203';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0033 as sPk_corp,field0036 as pk_first_bas,field0037 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0203 f where f.id=iOaBillId;
  end if;
  if sNcBillType = '9246' then--其他合同修订
   oa_tabname:='formmain_0202';
select f.field0002 as iJbPersonId,field0003 as iJbDeptId,field0023 as iZdPersonId,field0022 as iZdDeptId,
field0033 as sPk_corp,field0036 as pk_first_bas,field0037 as pk_second_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_first_bas,pk_second_bas
from formmain_0202 f where f.id=iOaBillId;
  end if;
--正常审批结束
-- pk_origintype
-- pk_basetype
--vrealdeptid
--nbaserate 1
--iuploadmode 1
--isplitstate 0
--isourcetype 2
--ipaymode 0：按付款协议付款 3：按合同产值付款
--iholdtype 0
--ictrlstatus 0 1?
--biscountcost Y
--bisincludemodi Y
--新增保存 vbillstatus=8
--提交后 vbillstatus=3
--审核后 vbillstatus=1

--合同状态：icontstatus 未生效:0,生效:1,中止:6


--经办部门NCPK
--select fun_getpk_deptdoc(sPk_corp,iJbPersonId) into pk_jbbm from dual;

--制单人NCPK
select fun_getpk_userByOaId(iZdPersonId) into pk_zdr  from dual;
--制单部门NCPK
select fun_getpk_deptFromNCByID(iZdDeptId) into pk_zdbm  from dual;
--经办人PK
select fun_getpk_psndocById(sPk_corp,iJbPersonId) into pk_jbr from dual;
--经办部门NCPK
select fun_getpk_deptFromNCByID(iJbDeptId) into pk_jbbm  from dual;
--甲方PK
select fun_getpk_cumanByPks(sPk_corp,pk_first_bas) into pk_first_man from dual;
--乙方PK
select fun_getpk_cumanByPks(sPk_corp,pk_second_bas) into pk_second_man from dual;

    delete from nc5.pm_cm_contract_oa where oa_recid=iOaBillId;

    if sNcBillType = '9241' then-- 工程合同

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,
      vdigest,vpaydigest,vmemo,vorigrealcontno,voperatorid,vrealdeptid,
      vdef4,vdef3,vdef6,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select 1||lpad(cast(seq_cont.nextval as varchar(10)),19,'0') as pk_cont,sNcBillType,f.field0025 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0027 as pk_project,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0021,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0013 as nsignbasemny,f.field0013 as nsignorigmny,f.field0013 as ncontbasemny,f.field0013 as ncontcostbasemny,
    f.field0013 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0013 as ncontorigmny,
    f.field0026 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0008 as vname,f.field0017 as vdigest,f.field0018 as vpaydigest,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0032 as isstardecor,--是否红星美凯龙装修
    f.field0031 as islawidea,--是否需要律师审批
    f.field0030 as iswatercont,--是否水电气合同
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,f.field0001 as billcode
    FROM formmain_0208 f where f.id=iOaBillId;
  end if;

  if sNcBillType = '9244' then-- 工程合同修订

    select max(field0044) into sPK_Cont from formmain_0207 where id=iOaBillId;--原合同PK
    if sPK_Cont is null then
      select max(pk_cont) into sPK_Cont from nc5.pm_cm_contract where pk_billtype='9241' and icontstatus=1 and nvl(dr,0)=0
      and vname in (select field0008 from formmain_0207 where id=iOaBillId);
    end if;

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,pk_origcont,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,vorigname,
      vdigest,vpaydigest,vmodimemo,vmemo,vorigrealcontno,vrealcontno,voperatorid,vrealdeptid,
      vdef4,vdef3,vdef6,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select sPK_Cont as pk_cont,sNcBillType,f.field0035 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0037 as pk_project,sPK_Cont as pk_origcont,
    to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0027,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0025 as nsignbasemny,f.field0025 as nsignorigmny,f.field0025 as ncontbasemny,f.field0025 as ncontcostbasemny,f.field0025 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0025 as ncontorigmny,
    f.field0036 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0024 as vname,f.field0008 as vorigname,f.field0017 as vdigest,f.field0018 as vpaydigest,f.field0028 as vmodimemo,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,f.field0026 as vrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0031 as isstardecor,--是否红星美凯龙装修
    f.field0007 as islawidea,--是否需要律师审批
    f.field0006 as iswatercont,--是否水电气合同
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,f.field0001 as billcode
    FROM formmain_0207 f where f.id=iOaBillId;


  end if;

  if sNcBillType = '9242' then-- 材料合同

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,
      vdigest,vpaydigest,vmemo,vorigrealcontno,voperatorid,vrealdeptid,
      vdef3,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select 1||lpad(cast(seq_cont.nextval as varchar(10)),19,'0') as pk_cont,sNcBillType,f.field0026 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0028 as pk_project,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0021,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0013 as nsignbasemny,f.field0013 as nsignorigmny,
    f.field0013 as ncontbasemny,f.field0013 as ncontcostbasemny,f.field0013 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0013 as ncontorigmny,
    f.field0027 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0008 as vname,f.field0017 as vdigest,f.field0018 as vpaydigest,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0031 as islawidea,--是否需要律师审批
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,f.field0001 as billcode
    FROM formmain_0205 f where f.id=iOaBillId;
  end if;

  if sNcBillType = '9245' then-- 材料合同修订

      select max(field0040) into sPK_Cont from formmain_0203 where id=iOaBillId;--原合同PK
      if sPK_Cont is null then
         select max(pk_cont) into sPK_Cont from nc5.pm_cm_contract where pk_billtype='9242' and icontstatus=1 and nvl(dr,0)=0
         and vname in (select field0008 from formmain_0203 where id=iOaBillId);
      end if;

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,pk_origcont,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,vorigname,
      vdigest,vpaydigest,vmodimemo,vmemo,vorigrealcontno,vrealcontno,voperatorid,vrealdeptid,
      vdef3,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select sPK_Cont as pk_cont,sNcBillType,f.field0033 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0035 as pk_project,sPK_Cont as pk_origcont,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,
    to_char(f.field0027,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0025 as nsignbasemny,f.field0025 as nsignorigmny,--
    f.field0025 as ncontbasemny,f.field0025 as ncontcostbasemny,f.field0025 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0025 as ncontorigmny,
    f.field0034 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0024 as vname,f.field0008 as vorigname,f.field0017 as vdigest,f.field0018 as vpaydigest,f.field0028 as vmodimemo,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,f.field0026 as vrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0038 as islawidea,--是否需要律师审批
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,f.field0001 as billcode
    FROM formmain_0203 f where f.id=iOaBillId;
  end if;

  if sNcBillType = '9243' then-- 其他合同

    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,
      vdigest,vpaydigest,vmemo,vorigrealcontno,voperatorid,vrealdeptid,
      vdef3,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select 1||lpad(cast(seq_cont.nextval as varchar(10)),19,'0') as pk_cont,sNcBillType,f.field0025 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0027 as pk_project,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,to_char(f.field0021,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0013 as nsignbasemny,f.field0013 as nsignorigmny,
    f.field0013 as ncontbasemny,f.field0013 as ncontcostbasemny,f.field0013 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0013 as ncontorigmny,
    f.field0026 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0008 as vname,f.field0017 as vdigest,f.field0018 as vpaydigest,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0031 as islawidea,--是否需要律师审批
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,f.field0001 as billcode
    FROM formmain_0204 f where f.id=iOaBillId;
  end if;

  if sNcBillType = '9246' then-- 其他合同修订

      select max(field0040) into sPK_Cont from formmain_0202 where id=iOaBillId;--原合同PK
      if sPK_Cont is null then
        select max(pk_cont) into sPK_Cont from nc5.pm_cm_contract where pk_billtype='9243' and icontstatus=1 and nvl(dr,0)=0
        and vname in (select field0008 from formmain_0202 where id=iOaBillId);
     end if;
    insert into nc5.pm_cm_contract_oa(pk_cont,Pk_billtype,pk_corp,vdeptid,vdealerid,pk_project,pk_origcont,
      dapprovedate,dbilldate,dmakedate,dsigndate,nsignbasemny,nsignorigmny,
      ncontbasemny,ncontcostbasemny,ncontcostorigmny,
      ncontnocostbasemny,ncontnocostorigmny,ncontorigmny,
      pk_conttype,pk_first,pk_second,vbillno,vname,vorigname,
      vdigest,vpaydigest,vmodimemo,vmemo,vorigrealcontno,vrealcontno,voperatorid,vrealdeptid,
      vdef3,oa_tabname,oa_recid,oa_billno,
      pk_basetype,pk_origintype,nbaserate,iuploadmode,isplitstate,
      isourcetype,ipaymode,iholdtype,biscountcost,
      bisincludemodi,ictrlstatus,vbillstatus,icontstatus,vdef10)
    select sPK_Cont as pk_cont,sNcBillType,f.field0033 as pk_corp,pk_jbbm as vdeptid,pk_jbr as vdealerid,
    f.field0035 as pk_project,sPK_Cont as pk_origcont,to_char(sysdate,'yyyy-mm-dd') as dapprovedate,
    to_char(f.field0027,'yyyy-mm-dd') as dbilldate,
    to_char(f.field0021,'yyyy-mm-dd') as dmakedate,to_char(f.field0014,'yyyy-mm-dd') as dsigndate,
    f.field0025 as nsignbasemny,f.field0025 as nsignorigmny,
    f.field0025 as ncontbasemny,f.field0025 as ncontcostbasemny,f.field0025 as ncontcostorigmny,
    0 as ncontnocostbasemny,0 as ncontnocostorigmny,f.field0025 as ncontorigmny,
    f.field0034 as pk_conttype,pk_first_man as pk_first,pk_second_man as pk_second,f.field0001 as vbillno,
    f.field0024 as vname,f.field0008 as vorigname,f.field0017 as vdigest,f.field0018 as vpaydigest,f.field0028 as vmodimemo,
    f.field0020 as vmemo,f.field0012 as vorigrealcontno,f.field0026 as vrealcontno,pk_zdr as voperatorid,pk_zdbm as vrealdeptid,
    f.field0038 as islawidea,--是否需要律师审批
    oa_tabname,iOaBillId as oa_recid,f.field0001 as oa_billno,
    '00010000000000000001' as pk_basetype,'00010000000000000001' as pk_origintype,
    1 as nbaserate,1 as iuploadmode,0 as isplitstate,2 as isourcetype,0 as ipaymode,
    0 as iholdtype,'Y' as biscountcost,'Y' as bisincludemodi,0 as ictrlstatus,1 as vbillstatus,0 as icontstatus,f.field0001 as billcode
    FROM formmain_0202 f where f.id=iOaBillId;
  end if;
  commit;

  --select FN_NCService(sNcBillType,sPK_Cont,iOaBillId) into vNCResult from dual;
  --insert into nc5.pm_oa_errlog(pk_billtype,pk_cont,oa_recid,message2) values (sNcBillType,sPK_Cont,iOaBillId,vNCResult);
  --commit;

end;
/

prompt
prompt Creating procedure SYNC_WU
prompt ==========================
prompt
create or replace procedure oa.sync_wu(iOaBillId number,bRevoke number)
as
oa_tabname varchar(15);--OA表名
can_delete number:=0;--能否删除（反操作）
pk_jbr varchar(20);--经办人NCPK
pk_jbbm varchar(20);--经办部门NCPK
pk_zdr varchar(20);--制单人NCPK
pk_zdbm varchar(20);--制单部门NCPK
pk_receiver_bas varchar(20);--收款方NC bas PK
pk_receiver_man varchar(20);--收款方NC man PK
vNCResult clob;
iJbPersonId number;
iJbDeptId number;
iZdPersonId number;
iZdDeptId number;
sPk_corp varchar(4);

begin

  if bRevoke = 1 then
    select 1 into can_delete from nc5.pm_pa_noncontfee a where a.oa_recid=iOaBillId and a.oa_tabname=oa_tabname
;
    if can_delete=1 then
      raise_application_error(-20001,'已有相关修订单记录不能删除');
      return;
    end if;
    update nc5.pm_pa_noncontfee a set a.dr=1 where a.oa_recid=iOaBillId and a.oa_tabname=oa_tabname;
    return;
  end if;


select f.field0006 as iJbPersonId,field0005 as iJbDeptId,field0014 as iZdPersonId,field0013 as iZdDeptId,
field0016 as sPk_corp,field0018 as pk_receiver_bas
into iJbPersonId,iJbDeptId,iZdPersonId,iZdDeptId,sPk_corp,pk_receiver_bas
from formmain_0201 f where f.id=iOaBillId;


--经办部门NCPK
--select fun_getpk_deptdoc(sPk_corp,iJbPersonId) into pk_jbbm from dual;

--制单人NCPK
select fun_getpk_userByOaId(iZdPersonId) into pk_zdr  from dual;
--制单部门NCPK
select fun_getpk_deptFromNCByID(iZdDeptId) into pk_zdbm  from dual;
--经办人PK
select fun_getpk_psndocById(sPk_corp,iJbPersonId) into pk_jbr from dual;
--经办部门NCPK
select fun_getpk_deptFromNCByID(iJbDeptId) into pk_jbbm  from dual;
--收款方PK
select fun_getpk_cumanByPks(sPk_corp,pk_receiver_bas) into pk_receiver_man from dual;

  sp_nocontpay2nc(pk_receiver_bas,pk_receiver_man,pk_jbr,pk_jbbm,pk_zdr,pk_zdbm,oa_tabname,iOaBillId);
  select FN_NCService('9262','',iOaBillId) into vNCResult from dual;
  insert into nc5.pm_oa_errlog(pk_billtype,pk_cont,oa_recid,message2) values ('9262','',iOaBillId,vNCResult);

end;
/

prompt
prompt Creating trigger TRI_GCHT_XD
prompt ============================
prompt
create or replace trigger oa.tri_gcht_xd
before insert or update
on formmain_0207--工程合同修订
  for each row
declare

pk_cubasdoc1st varchar(20);
pk_cubasdoc2nd varchar(20);
pk_project varchar(20);
pk_corp1 varchar(4);
pk_conttype1 varchar(20);
pk_cont1 varchar(20);

begin

select fun_getpk_corp(:new.field0004) into  pk_corp1 from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0015) into  pk_cubasdoc1st from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0016) into  pk_cubasdoc2nd from dual;
select fun_getpk_project(:new.field0004,:new.field0011) into  pk_project from dual;
select fun_getpk_projecttype(:new.field0009) into  pk_conttype1 from dual;

select fun_getpk_cont(pk_corp1,'9241',:new.field0008) into  pk_cont1 from dual;

--fun_getpk_corp iOaCorpid
--fun_getpk_cubasdoc iOaCorpid,cCusName
--fun_getpk_project iOaCorpid,cProjName
--fun_getpk_projecttype  cProjectTypeName

select
  pk_corp1,
  pk_conttype1,
  (case when e1.enumvalue='0' then 'Y' else 'N' end) as decor_flag,
  (case when e2.enumvalue='0' then 'Y' else 'N' end) as law_flag,
  (case when e3.enumvalue='0' then 'Y' else 'N' end) as gas_flag,
  pk_cubasdoc1st,
  pk_cubasdoc2nd,
  pk_project,
  pk_cont1
  into :new.field0035,--公司PK
  :new.field0036,--合同类型PK
  :new.field0042,--装修标志
  :new.field0041,--律师标志
  :new.field0040,--水电气合同标志
  :new.field0038,--甲方PK
  :new.field0039,--乙方PK
  :new.field0037,--项目PK
  :new.field0044--原合同PK
  from dual left join ctp_enum_item e1 on e1.id=:new.field0031--是否红星美凯龙装修
  left join ctp_enum_item e2 on e2.id=:new.field0007--是否需要律师审批
  left join ctp_enum_item e3 on e3.id=:new.field0006;--是否水电气合同

 sp_savebillno(9244,:new.id,:new.field0001);
 
end tri_gcht_xd;
/

prompt
prompt Creating trigger TR_CHGCONTSTAT
prompt ===============================
prompt
create or replace trigger oa.tr_chgcontstat
after insert or update
on formmain_0226--合同状态调整
  for each row
declare
vBillType varchar(4);
vBillType_orig varchar(4);
sPK_Cont varchar(20);
iContstat number;
iOaBillId number;
iCurrContstat number :=-1;
nPayedmny number:=0;
vNCResult clob;
begin

--field0056 单据状态
--   562560076970477410  生效 0
--   1253785730791001501 作废 1
--   3809572103538428265 未生效 2

-- field0009 单据类型
--   -7405372342111681503  工程合同  0
--   6778781750779463420  材料合同  1
--   104504294407162084  其他合同  2
--   3113107611590673641  付款申请单  3

-- field0008 合同名称
-- icontstatus 未生效:0,生效:1,中止:6

if :new.field0056 = 562560076970477410 then
iCurrContstat := 1;--生效
end if;
if :new.field0056 = 1253785730791001501 then
iCurrContstat := 6;--TODO
end if;
if :new.field0056 = 3809572103538428265 then
iCurrContstat := 0;--未生效
end if;
--单据类型
if :new.field0009 = -7405372342111681503 then
vBillType_orig :='9241';
vBillType :='9247';--工程合同
select max(id) into iOaBillId from formmain_0208 where field0008=:new.field0008;--根据合同名称查询ID
end if;
if :new.field0009 = 6778781750779463420 then
vBillType_orig :='9242';
vBillType :='9248';
select max(id) into iOaBillId from formmain_0205 where field0008=:new.field0008;--根据合同名称查询ID
end if;
if :new.field0009 = 104504294407162084 then
vBillType_orig :='9243';
vBillType :='9249';
select max(id) into iOaBillId from formmain_0204 where field0008=:new.field0008;--根据合同名称查询ID
end if;

select max(icontstatus),max(nsumpaybasemny),max(pk_cont) into iContstat, nPayedmny,sPK_Cont from nc5.pm_cm_contract c where nvl(c.dr,0)=0 and c.pk_billtype=vBillType_orig and c.vname= :new.field0008;
if iContstat is null then
  raise_application_error(-20001,'NC系统中未查询到数据'||vBillType||'---'||:new.field0008);
  return;
end if;
if iCurrContstat = iContstat then
  return;--
end if;

if nPayedmny > 0 then
  raise_application_error(-20001,'已有付款记录不可变更状态'||vBillType||'---'||:new.field0008);
  return;
end if;

 select FN_NCService(vBillType,sPK_Cont,iOaBillId) into vNCResult from dual;

 insert into nc5.pm_oa_errlog(pk_billtype,pk_cont,oa_recid,message) values (vBillType,sPK_Cont,iOaBillId,vNCResult);

end tr_chgcontstat;
/

prompt
prompt Creating trigger TR_CLHT
prompt ========================
prompt
create or replace trigger oa.tr_clht
before insert or update
on formmain_0205--材料合同录入
  for each row
declare

pk_cubasdoc1st varchar(20);
pk_cubasdoc2nd varchar(20);
pk_project varchar(20);
pk_corp1 varchar(4);
pk_conttype1 varchar(20);
begin

select fun_getpk_corp(:new.field0004) into  pk_corp1 from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0015) into  pk_cubasdoc1st from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0016) into  pk_cubasdoc2nd from dual;
select fun_getpk_project(:new.field0004,:new.field0011) into  pk_project from dual;
select fun_getpk_projecttype(:new.field0009) into  pk_conttype1 from dual;

--fun_getpk_corp iOaCorpid
--fun_getpk_cubasdoc iOaCorpid,cCusName
--fun_getpk_project iOaCorpid,cProjName
--fun_getpk_projecttype  cProjectTypeName

  select pk_corp1,
  pk_conttype1,
  (case when e2.enumvalue='0' then 'Y' else 'N' end) as law_flag,
  pk_cubasdoc1st,
  pk_cubasdoc2nd,
  pk_project
  into :new.field0026,--公司PK
  :new.field0027,--合同类型PK
  :new.field0031,--律师标志
  :new.field0029,--甲方PK
  :new.field0030,--乙方PK
  :new.field0028--项目PK
  from dual c  left join ctp_enum_item e2 on e2.id=:new.field0007;--是否需要律师审批;

 sp_savebillno(9242,:new.id,:new.field0001);
end tr_clht;
/

prompt
prompt Creating trigger TR_CLHT_XD
prompt ===========================
prompt
create or replace trigger oa.tr_clht_xd
before insert or update
on formmain_0203--材料合同修订
  for each row
declare

pk_cubasdoc1st varchar(20);
pk_cubasdoc2nd varchar(20);
pk_project varchar(20);
pk_corp1 varchar(4);
pk_conttype1 varchar(20);
pk_cont1 varchar(20);

begin

select fun_getpk_corp(:new.field0004) into  pk_corp1 from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0015) into  pk_cubasdoc1st from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0016) into  pk_cubasdoc2nd from dual;
select fun_getpk_project(:new.field0004,:new.field0011) into  pk_project from dual;
select fun_getpk_projecttype(:new.field0009) into  pk_conttype1 from dual;

select fun_getpk_cont(pk_corp1,'9242',:new.field0008) into  pk_cont1 from dual;

--fun_getpk_corp iOaCorpid
--fun_getpk_cubasdoc iOaCorpid,cCusName
--fun_getpk_project iOaCorpid,cProjName
--fun_getpk_projecttype  cProjectTypeName

  select pk_corp1,
  pk_conttype1,
  (case when e2.enumvalue='0' then 'Y' else 'N' end) as law_flag,
  pk_cubasdoc1st,
  pk_cubasdoc2nd,
  pk_project,
  pk_cont1
  into :new.field0033,--公司PK
  :new.field0034,--合同类型PK
  :new.field0038,--律师标志
  :new.field0036,--甲方PK
  :new.field0037,--乙方PK
  :new.field0035,--项目PK
  :new.field0040--原合同PK
  from dual c
  left join ctp_enum_item e2 on e2.id=:new.field0007;--是否需要律师审批
  
 sp_savebillno(9244,:new.id,:new.field0001);
 
end tr_clht_xd;
/

prompt
prompt Creating trigger TR_COL_SUMMARY
prompt ===============================
prompt
create or replace trigger oa.tr_col_summary
after update
on col_summary
for each row
declare isrevoke number;
   strNcBillType varchar(4);
  begin
    isrevoke :=0;
if (:new.state != 3 and :old.state =3) then
   isrevoke :=1;
end if;


-- 


    if (:new.state = 3 and :old.state !=3) or (:new.state != 3 and :old.state =3) then

      if :new.form_appid=8426033719983161482 then --工程合同formmain_0208
  strNcBillType :='9241';
  sync_ht(strNcBillType,:new.form_recordid,isrevoke);
--   insert into nc5.pm_oa_temp(bill,seq) values ('col_summary',nc5.seqtemp.nextval);
      end if;
      if :new.form_appid=-3989024980432240427 then --工程合同修订formmain_0207
  strNcBillType :='9244';
  sync_ht(strNcBillType,:new.form_recordid,isrevoke);
      end if;
      if :new.form_appid=-7176398882568518043 then --材料合同formmain_0205
  strNcBillType :='9242';
  sync_ht(strNcBillType,:new.form_recordid,isrevoke);
      end if;
      if :new.form_appid=-5318643614975963443 then--材料合同修订formmain_0203
        strNcBillType :='9245';
  sync_ht(strNcBillType,:new.form_recordid,isrevoke);
      end if;
      if :new.form_appid=-8530129557149693844 then--其他合同formmain_0204
  strNcBillType :='9243';
  sync_ht(strNcBillType,:new.form_recordid,isrevoke);
      end if;
      if :new.form_appid=-7954091047524283925 then--其他合同修订formmain_0202
  strNcBillType :='9246';
  sync_ht(strNcBillType,:new.form_recordid,isrevoke);
      end if;
      if :new.form_appid=-563667203412308156 then--合同付款formmain_0206
         sync_fk(:new.form_recordid,isrevoke);
      end if;
      if :new.form_appid=-4360488821200368305 then--无合同费用单formmain_0201
         sync_wu(:new.form_recordid,isrevoke);
      end if;
    end if;
end tr_col_summary;
/

prompt
prompt Creating trigger TR_GCHT
prompt ========================
prompt
create or replace trigger oa.tr_gcht
before insert or update
on formmain_0208--工程合同录入
  for each row
declare
pk_cubasdoc1st varchar(20);
pk_cubasdoc2nd varchar(20);
pk_project varchar(20);
pk_corp1 varchar(4);
pk_conttype1 varchar(20);
pk_jbr  varchar(20);
begin
  

  insert into nc5.pm_oa_temp(bill,seq,billno) values ('gcht',nc5.seqtemp.nextval,:new.field0001);
if :new.field0001 is not null then
  update nc5.pm_cm_contract set vdef10= :new.field0001 where vreserve10=:new.id;
end if;
  

select fun_getpk_corp(:new.field0004) into  pk_corp1 from dual;--pk_corp
select fun_getpk_cubasdoc(:new.field0004,:new.field0015) into  pk_cubasdoc1st from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0016) into  pk_cubasdoc2nd from dual;
select fun_getpk_project(:new.field0004,:new.field0011) into  pk_project from dual;
select fun_getpk_projecttype(:new.field0009) into  pk_conttype1 from dual;


select fun_getpk_psndocbyid(pk_corp1,:new.field0023) into pk_jbr from dual;
if pk_jbr is null then
  null;--  raise_application_error(-20001,'NC无对应的经办人');
--return;
end if;





--fun_getpk_corp iOaCorpid
--fun_getpk_cubasdoc iOaCorpid,cCusName
--fun_getpk_project iOaCorpid,cProjName
--fun_getpk_projecttype  cProjectTypeName

  select pk_corp1,
  pk_conttype1,(case when e1.enumvalue='0' then 'Y' else 'N' end) as decor_flag,
  (case when e2.enumvalue='0' then 'Y' else 'N' end) as law_flag,
  (case when e3.enumvalue='0' then 'Y' else 'N' end) as gas_flag,
  pk_cubasdoc1st,
  pk_cubasdoc2nd,
  pk_project
  into :new.field0025,--公司PK
  :new.field0026,--合同类型PK
  :new.field0032,--装修标志
  :new.field0031,--律师标志
  :new.field0030,--水电气合同标志
  :new.field0028,--甲方PK
  :new.field0029,--乙方PK
  :new.field0027--项目PK
  from dual c left join ctp_enum_item e1 on e1.id=:new.field0024--是否红星美凯龙装修
  left join ctp_enum_item e2 on e2.id=:new.field0007--是否需要律师审批
  left join ctp_enum_item e3 on e3.id=:new.field0006;--是否水电气合同
  
  sp_savebillno(9241,:new.id,:new.field0001);
  

end tr_gcht;
/

prompt
prompt Creating trigger TR_GCHT_AFTER
prompt ==============================
prompt
create or replace trigger oa.tr_gcht_after
after update
on formmain_0208--工程合同录入
  for each row
declare

begin


  insert into nc5.pm_oa_temp(bill,seq,billno) values ('gcht-after',nc5.seqtemp.nextval,:new.field0001);
if :new.field0001 is not null then
  update nc5.pm_cm_contract set vdef10 = :new.field0001 where vreserve20=:new.id;
end if;


end;
/

prompt
prompt Creating trigger TR_HTFK
prompt ========================
prompt
create or replace trigger oa.tr_htfk
before insert or update
on formmain_0206--合同付款
  for each row
declare
pk_cubasdoc1st varchar(20);
pk_cubasdoc2nd varchar(20);
pk_project varchar(20);
pk_corp1 varchar(4);
pk_conttype1 varchar(20);
pk_cont1 varchar(20);
begin

select fun_getpk_corp(:new.field0004) into  pk_corp1 from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0015) into  pk_cubasdoc1st from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0016) into  pk_cubasdoc2nd from dual;
select fun_getpk_project(:new.field0004,:new.field0011) into  pk_project from dual;
select fun_getpk_projecttype(:new.field0009) into  pk_conttype1 from dual;

select max(pk_cont) into pk_cont1 from nc5.pm_cm_contract 
where nvl(dr,0)=0 and vname=:new.field0008 and icontstatus in (1,4) and pk_billtype in ('9241','9242','9243');
--fun_getpk_corp iOaCorpid
--fun_getpk_cubasdoc iOaCorpid,cCusName
--fun_getpk_project iOaCorpid,cProjName
--fun_getpk_projecttype  cProjectTypeName

  select pk_corp1,
  pk_conttype1,
  (case when e2.enumvalue='0' then 'Y' else 'N' end) as request_flag,
  (case when e2.enumvalue='0' then 'Y' else 'N' end) as pay_flag,
  pk_cubasdoc1st,
  pk_cubasdoc2nd,
  pk_project,
  pk_cont1
  into :new.field0034,--公司PK
  :new.field0035,--合同类型PK
  :new.field0040,--是否水电气请款标志
  :new.field0041,--决算款标志
  :new.field0038,--付款单位PK
  :new.field0039,--收款单位PK
  :new.field0037,--项目PK
  :new.field0036 -- hetong pk
  from dual c left join ctp_enum_item e2 on e2.id=:new.field0031--是否水电气请款
  left join ctp_enum_item e3 on e3.id=:new.field0032;--是否决算款

 sp_savebillno(9261,:new.id,:new.field0001);
 

end tr_htfk;
/

prompt
prompt Creating trigger TR_ORG_UNIT
prompt ============================
prompt
CREATE OR REPLACE TRIGGER OA.tr_org_unit
  after insert
  on org_unit
  for each row
begin
-- 新增部门或公司
  update nc5.fdc_bd_project_corp set pk_project=pk_project
  where pk_corp = (select pk_corp from nc5.bd_corp where unitcode= :new.code);
--客商
  update nc5.bd_cumandoc set pk_cumandoc=pk_cumandoc
  where pk_corp = (select pk_corp from nc5.bd_corp where unitcode= :new.code);
  
--无合同费用类型
  update nc5.pm_bd_nocontfeetype set vcode=vcode;
--合同类型
  update nc5.Pm_bd_conttype set vcode=vcode;

end tr_org_unit;
/

prompt
prompt Creating trigger TR_QTHT
prompt ========================
prompt
create or replace trigger oa.tr_qtht
before insert or update
on formmain_0204--其他合同
  for each row
declare

pk_cubasdoc1st varchar(20);
pk_cubasdoc2nd varchar(20);
pk_project varchar(20);
pk_corp1 varchar(4);
pk_conttype1 varchar(20);
begin

select fun_getpk_corp(:new.field0004) into  pk_corp1 from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0015) into  pk_cubasdoc1st from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0016) into  pk_cubasdoc2nd from dual;
select fun_getpk_project(:new.field0004,:new.field0011) into  pk_project from dual;
select fun_getpk_projecttype(:new.field0009) into  pk_conttype1 from dual;

--fun_getpk_corp iOaCorpid
--fun_getpk_cubasdoc iOaCorpid,cCusName
--fun_getpk_project iOaCorpid,cProjName
--fun_getpk_projecttype  cProjectTypeName

  select pk_corp1,
  pk_conttype1,
  (case when e2.enumvalue='0' then 'Y' else 'N' end) as law_flag,
  pk_cubasdoc1st,
  pk_cubasdoc2nd,
  pk_project
  into :new.field0025,--公司PK
  :new.field0026,--合同类型PK
  :new.field0030,--律师标志
  :new.field0028,--甲方PK
  :new.field0029,--乙方PK
  :new.field0027--项目PK
  from dual c left join ctp_enum_item e2 on e2.id=:new.field0007;--是否需要律师审批


 sp_savebillno(9243,:new.id,:new.field0001);
 
end tr_qtht;
/

prompt
prompt Creating trigger TR_QTHT_XD
prompt ===========================
prompt
create or replace trigger oa.tr_qtht_xd
before insert or update
on formmain_0202 --其他合同修订
  for each row
declare
pk_cubasdoc1st varchar(20);
pk_cubasdoc2nd varchar(20);
pk_project varchar(20);
pk_corp1 varchar(4);
pk_conttype1 varchar(20);
pk_cont1 varchar(20);

begin

select fun_getpk_corp(:new.field0004) into  pk_corp1 from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0015) into  pk_cubasdoc1st from dual;
select fun_getpk_cubasdoc(:new.field0004,:new.field0016) into  pk_cubasdoc2nd from dual;
select fun_getpk_project(:new.field0004,:new.field0011) into  pk_project from dual;
select fun_getpk_projecttype(:new.field0009) into  pk_conttype1 from dual;

select fun_getpk_cont(pk_corp1,'9243',:new.field0008) into  pk_cont1 from dual;

--fun_getpk_corp iOaCorpid
--fun_getpk_cubasdoc iOaCorpid,cCusName
--fun_getpk_project iOaCorpid,cProjName
--fun_getpk_projecttype  cProjectTypeName

  select pk_corp1,
  pk_conttype1,
  (case when e2.enumvalue='0' then 'Y' else 'N' end) as law_flag,
  pk_cubasdoc1st,
  pk_cubasdoc2nd,
  pk_project,
  pk_cont1
  into :new.field0033,--公司PK
  :new.field0034,--合同类型PK
  :new.field0038,--律师标志
  :new.field0036,--甲方PK
  :new.field0037,--乙方PK
  :new.field0035,--项目PK
  :new.field0040--原合同PK
  from dual c left join ctp_enum_item e2 on e2.id=:new.field0007;--是否需要律师审批

 sp_savebillno(9246,:new.id,:new.field0001);
 
end tr_qtht_xd;
/

prompt
prompt Creating trigger TR_WHTFK
prompt =========================
prompt
create or replace trigger oa.tr_whtfk
before insert or update
on formmain_0201--无合同付款
  for each row
declare
pk_cubasdoc1st varchar(20);
pk_project varchar(20);
pk_corp1 varchar(4);
pk_noconttype1 varchar(20);
begin

select fun_getpk_corp(:new.field0015) into  pk_corp1 from dual;
select fun_getpk_cubasdoc(:new.field0015,:new.field0003) into  pk_cubasdoc1st from dual;
select fun_getpk_project(:new.field0015,:new.field0001) into  pk_project from dual;
select max(field0004) into pk_noconttype1 from formmain_0213 where field0002=:new.field0002;

--fun_getpk_corp iOaCorpid
--fun_getpk_cubasdoc iOaCorpid,cCusName
--fun_getpk_project iOaCorpid,cProjName
--fun_getpk_projecttype  cProjectTypeName

  select pk_corp1,
  pk_noconttype1,
  pk_cubasdoc1st,
  pk_project
  into :new.field0016,--公司PK
  :new.field0017,--无合同费用类型PK TODO
  :new.field0018,--收款单位PK
  :new.field0021--项目ncpk
  from dual c;

 sp_savebillno(9262,:new.id,:new.field0019);
 
end tr_whtfk;
/


spool off
