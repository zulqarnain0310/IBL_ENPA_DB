SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[OTHER_PROV_Reverse_Feed](@TimeKey INT,@IS_MOC CHAR(1)='N')
--@DATE VARCHAR(10)
AS
declare @DATE DATE
select @DATE=Date from dbo.SysDataMatrix  where  TimeKey=@TimeKey

DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='OTHER_PROV_Reverse_Feed' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @DATE,@TimeKey,'OTHER_PROV_Reverse_Feed',GETDATE()

IF(EOMONTH(@DATE)=@DATE)
BEGIN 
INSERT INTO OTHER_PROV_ReverseFeedDetails_Archive(AsOnDate,SourceName,Prov_Amount,IS_MOC)
SELECT AsOnDate,SourceName,Prov_Amount,IS_MOC
FROM OTHER_PROV_ReverseFeedDetails
END

TRUNCATE TABLE OTHER_PROV_ReverseFeedDetails


IF OBJECT_ID('TEMPDB..#MOC') IS NOT NULL
DROP TABLE #MOC
CREATE TABLE #MOC(NCIF_ID VARCHAR(100))

IF(@IS_MOC='Y')
BEGIN

INSERT INTO #MOC(NCIF_ID)
SELECT DISTINCT NCIF_ID
FROM NPA_IntegrationDetails
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND ISNULL(FlgProcessing,'N')='Y'
END

INSERT INTO OTHER_PROV_ReverseFeedDetails(AsOnDate,SourceName,Prov_Amount,IS_MOC)
select @DATE As_On_Processing_Date,b.SourceName,sum(TotalProvision)TotalProvision, CASE WHEN @IS_MOC='Y' THEN 'Y' ELSE  'N' END IS_MOC
from [dbo].[NPA_IntegrationDetails] a
inner join [dbo].[DimSourceSystem] b on a.SrcSysAlt_Key=b.SourceAlt_Key
                                                  and b.EffectiveFromTimeKey<=@TimeKey AND b.EffectiveToTimeKey>=@TimeKey
												  and  a.EffectiveFromTimeKey<=@TimeKey AND a.EffectiveToTimeKey>=@TimeKey
LEFT JOIN #MOC MOC ON A.NCIF_Id=MOC.NCIF_ID
where b.SourceName not in ('Prolendz','PT Smart')  
and isnull(NCIF_AssetClassAlt_Key,1)<>1
AND  A.NCIF_ID = (CASE WHEN @IS_MOC='Y' THEN MOC.NCIF_ID ELSE A.NCIF_Id END)
group by b.SourceName


UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='OTHER_PROV_Reverse_Feed' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0
GO