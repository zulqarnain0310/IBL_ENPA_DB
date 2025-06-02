SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE Proc [dbo].[UPGRADION_ACCELATOR_PROVISION]
@Timekey as int 

as begin
DECLARE @Ext_DATE DATE =(SELECT DATE FROM SysDataMatrix WHERE TimeKey=@TimeKey)
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='UPGRADION_ACCELATOR_PROVISION' AND [EXT_DATE]=@Ext_DATE AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Ext_DATE,@TimeKey,'UPGRADION_ACCELATOR_PROVISION',GETDATE()

--Declare @Timekey as int --=(Select TimeKey from SysDataMatrix where CurrentStatus='C')

--select * 
Update B set b.EffectiveToTimeKey=@Timekey-1
from NPA_IntegrationDetails a inner join CURDAT.AcceleratedProv b
on a.CustomerACID=b.CustomerACID
and b.EffectivetoTimeKey=49999
where a.EffectiveFromTimeKey=@timekey And a.EffectiveToTimeKey=@Timekey
ANd A.NCIF_AssetClassAlt_Key=1

UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='UPGRADION_ACCELATOR_PROVISION' AND [EXT_DATE]=@Ext_DATE AND ISNULL([Audit_Flg],0)=0
 

end
GO