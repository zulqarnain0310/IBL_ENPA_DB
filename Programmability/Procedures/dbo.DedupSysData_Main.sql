SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE proc [dbo].[DedupSysData_Main]
as
begin

DECLARE @TimeKey int = (SELECT TimeKey FROM SysDatamatrix  WHERE CurrentStatus='C')
insert into DedupSysData
(
NCIF
,SrcAppAlt_Key
,SrcAppCustomerID
,PAN
,EffectiveFromTimeKey
,EffectiveToTimeKey)
select 
NCIF
,SrcAppAlt_Key
,SrcAppCustomerID
,PAN
,@TimeKey
,49999 from DedupSysData_Temp
end
GO