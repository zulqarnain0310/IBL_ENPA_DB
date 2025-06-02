SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Assetclass_Reverse_Feed_BKP_17042023](@TimeKey INT,@IS_MOC CHAR(1)='N')
--@DATE VARCHAR(10)
AS
declare @DATE DATE
select @DATE=Date from dbo.SysDataMatrix  where  TimeKey=@TimeKey

DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='Assetclass_Reverse_Feed' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @DATE,@TimeKey,'Assetclass_Reverse_Feed',GETDATE()

IF(EOMONTH(@DATE)=@DATE)
BEGIN 
INSERT INTO ReverseFeedDetails_Archive(AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC)
SELECT AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC
FROM ReverseFeedDetails
END

TRUNCATE TABLE ReverseFeedDetails

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

INSERT INTO ReverseFeedDetails(AsOnDate,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,CIF_ID,UCIF_ID,SourceName,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC)
select @DATE As_On_Processing_Date, CustomerACID Account_No,BranchCode Sol_Id ,ProductType SchemeType,ProductCode Scheme_Code,
CustomerId Source_System_CIF,A.NCIF_Id Dedupe_ID_UCIC_Enterprise_CIF,Case when SrcSysAlt_Key=100 then 'Finacle-2' Else b.SourceName END SourceName
,case when SrcSysAlt_Key=10 then c.FinacleAssetClassCode 
             when SrcSysAlt_Key=20 And C.AssetClassAlt_Key=1 then '1'  --VISION PLUS
			when SrcSysAlt_Key=20 And C.AssetClassAlt_Key in (2,3,4,5,6) then '8'  --VISION PLUS
			 when SrcSysAlt_Key=20 And C.AssetClassAlt_Key=7 then '9' --VISION PLUS
			 when SrcSysAlt_Key=30 then c.TradeProAssetClassCode--TradePro
             when SrcSysAlt_Key=40 then c.CalypsoAssetClassCode
			 when SrcSysAlt_Key=50 then c.eCBFAssetClassCode
			 when   SrcSysAlt_Key=60 then c.ProlendzAssetClassCode
			 when SrcSysAlt_Key=70 then c.GanasevaAssetClassCode
			 when SrcSysAlt_Key=80 then c.PTSmartAssetClassCode
			 when SrcSysAlt_Key=90 then c.VeefinAssetClassCode ----Veefin
			 when SrcSysAlt_Key=100 then c.Finacle2AssetClassCode
			 end  Source_System_Asset_Classification
      	,case when SrcSysAlt_Key=10 then d.FinacleAssetClassCode 
	         when SrcSysAlt_Key=20 then d.VP_AssetClassCode --VISION PLUS
			 when SrcSysAlt_Key=30 then d.TradeProAssetClassCode--TradePro
             when SrcSysAlt_Key=40 then d.CalypsoAssetClassCode
			 when SrcSysAlt_Key=50 then d.eCBFAssetClassCode
			 when SrcSysAlt_Key=60 then d.ProlendzAssetClassCode
			 when SrcSysAlt_Key=70 then d.GanasevaAssetClassCode
			 when SrcSysAlt_Key=80 then d.PTSmartAssetClassCode 
			 when SrcSysAlt_Key=90 then d.VeefinAssetClassCode ----Veefin
			 when SrcSysAlt_Key=100 then d.Finacle2AssetClassCode
			 end 
			 Homogenized_Asset_Classification
,NCIF_NPA_Date Homogenized_NPA_Date,CASE WHEN @IS_MOC='Y' THEN 'Y'ELSE 'N' END IS_MOC
from [dbo].[NPA_IntegrationDetails] a
inner join [dbo].[DimSourceSystem] b on a.SrcSysAlt_Key=b.SourceAlt_Key
                                    and b.EffectiveFromTimeKey<=@TimeKey 
									AND b.EffectiveToTimeKey>=@TimeKey
									and  a.EffectiveFromTimeKey<=@TimeKey 
									AND a.EffectiveToTimeKey>=@TimeKey
inner join [dbo].[DimAssetClass] c on a.AC_AssetClassAlt_Key=c.AssetClassAlt_Key
                                  and  c.EffectiveFromTimeKey<=@TimeKey AND c.EffectiveToTimeKey>=@TimeKey
INNER join [dbo].[DimAssetClass] d on a.NCIF_AssetClassAlt_Key=d.AssetClassAlt_Key
                                  and  d.EffectiveFromTimeKey<=@TimeKey 
							      AND d.EffectiveToTimeKey>=@TimeKey
LEFT JOIN #MOC MOC ON A.NCIF_Id=MOC.NCIF_ID
where (
(
isnull(AC_AssetClassAlt_Key,0)<>isnull(NCIF_AssetClassAlt_Key,0)
OR ISNULL(AC_NPA_Date,'1900-01-01')<>ISNULL(NCIF_NPA_Date,'1900-01-01')
OR (ISNULL(Retail_Corpo,'N')='Y' AND @TimeKey=26557) -----  Added on 17092022 for identifying force asset class update
OR (A.NCIF_ID='68991477' AND @TimeKey=26658)  ---- ADDED ON 27122022 FOR REVERSE FEED OF EAGLE ELECTRONICS INDIA PVT LTD
)
       )
AND  A.NCIF_ID = (CASE WHEN @IS_MOC='Y' THEN MOC.NCIF_ID ELSE A.NCIF_Id END)

UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='Assetclass_Reverse_Feed' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0
GO