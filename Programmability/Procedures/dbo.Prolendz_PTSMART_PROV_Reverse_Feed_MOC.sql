SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROC [dbo].[Prolendz_PTSMART_PROV_Reverse_Feed_MOC](@TimeKey INT,@IS_MOC CHAR(1)='N')

AS
BEGIN
declare @DATE DATE
select @DATE=Date from dbo.SysDataMatrix  where  TimeKey=@TimeKey

DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='Prolendz_PTSMART_PROV_Reverse_Feed_MOC' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @DATE,@TimeKey,'Prolendz_PTSMART_PROV_Reverse_Feed_MOC',GETDATE() 

Insert into Prole_PT_PROV_ReverseFeedDetails_MOC
select @DATE As_On_Processing_Date,b.SourceName,a.NCIF_Id Dedupe_ID_UCIC_Enterprise_CIF,CustomerId Source_System_CIF,
CustomerACID Account_No,BranchCode Sol_Id ,ProductType SchemeType,ProductCode Scheme_Code,
TotalProvision,UNSERVED_INTEREST,CASE WHEN @IS_MOC='Y' THEN 'Y' ELSE 'N' END IS_MOC
from [dbo].[NPA_IntegrationDetails] a
inner join [dbo].[DimSourceSystem] b on a.SrcSysAlt_Key=b.SourceAlt_Key
                                    and b.EffectiveFromTimeKey<=@TimeKey 
									AND b.EffectiveToTimeKey>=@TimeKey
									and  a.EffectiveFromTimeKey<=@TimeKey 
									AND a.EffectiveToTimeKey>=@TimeKey
AND Cast(a.MOC_Date as date) in (CAST(getdate() as date)) 



UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='Prolendz_PTSMART_PROV_Reverse_Feed_MOC' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0

END
GO