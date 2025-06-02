SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Assetclass_Reverse_Feed_20250127](@TimeKey INT,@IS_MOC CHAR(1)='N')

AS
declare @DATE DATE
select @DATE=Date from dbo.SysDataMatrix  where  TimeKey=@TimeKey
DECLARE @CUTOVERDATE DATE='2024-01-24'--changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240126
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='Assetclass_Reverse_Feed' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @DATE,@TimeKey,'Assetclass_Reverse_Feed',GETDATE()

IF(EOMONTH(@DATE)=@DATE)
BEGIN 
--INSERT INTO ReverseFeedDetails_Archive(AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC)
--SELECT AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC
--FROM ReverseFeedDetails
--END   ---commented by satish as on date 3 nov 2022

/*-- ON PROD 20240117*/
INSERT INTO ReverseFeedDetails_Archive(AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,
SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC,NatureofClassification,DateofImpacting,ImpactingAccountNo,ImpactingSourceSystemName)
select AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC
,NatureofClassification--20231025 ON UAT FOR COBO BY ZAIN 
,DateofImpacting--20231025 ON UAT FOR COBO BY ZAIN 
,ImpactingAccountNo--20231025 ON UAT FOR COBO BY ZAIN 
,ImpactingSourceSystemName--20231025 ON UAT FOR COBO BY ZAIN
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
---  AND ISNULL(FlgProcessing,'N')='Y' ---- commented by satish as on date 13032024
AND ISNULL(FlgMOC,'N')='Y'   ---- added by satish as on date 13032024
END

INSERT INTO ReverseFeedDetails(AsOnDate,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,CIF_ID,UCIF_ID,SourceName,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC
,NatureofClassification  --20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
,DateofImpacting		--20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
,ImpactingAccountNo		--20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
,ImpactingSourceSystemName	--20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
)
select @DATE As_On_Processing_Date, CustomerACID Account_No,BranchCode Sol_Id ,ProductType SchemeType,ProductCode Scheme_Code,
CustomerId Source_System_CIF,A.NCIF_Id Dedupe_ID_UCIC_Enterprise_CIF,Case when SrcSysAlt_Key=100 then 'Finacle-2' Else b.SourceName END SourceName
,case when SrcSysAlt_Key=10 then c.FinacleAssetClassCode 
             when SrcSysAlt_Key=20 And C.AssetClassAlt_Key=1 then '1'  --VISION PLUS
			when SrcSysAlt_Key=20 And C.AssetClassAlt_Key in (2,3,4,5,6) then '8'  --VISION PLUS
			 when SrcSysAlt_Key=20 And C.AssetClassAlt_Key=7 then '9' --VISION PLUS
			 when SrcSysAlt_Key=30 then c.TradeProAssetClassCode--TradePro
             when SrcSysAlt_Key=40 then c.CalypsoAssetClassCode
			 when SrcSysAlt_Key=50 then c.eCBFAssetClassCode
			 when  (@CUTOVERDATE>=@DATE AND SrcSysAlt_Key=60) then c.ProlendzAssetClassCode --d.ProlendzAssetClassCode changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240117
			 when  (@CUTOVERDATE<@DATE AND SrcSysAlt_Key=60) then C.FinacleAssetClassCode --d.ProlendzAssetClassCode changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240117
			 when SrcSysAlt_Key=70 then c.GanasevaAssetClassCode
			 when SrcSysAlt_Key=80 then c.PTSmartAssetClassCode
			 when SrcSysAlt_Key=90 then c.VeefinAssetClassCode ----Veefin
			 when SrcSysAlt_Key=100 then c.Finacle2AssetClassCode
when SrcSysAlt_Key=120 And C.AssetClassAlt_Key=1 AND ISNULL(MaxDPD,0)=0 then 'STD'  --M2P
			 when SrcSysAlt_Key=120 And C.AssetClassAlt_Key=1 AND ISNULL(MaxDPD,0) BETWEEN 1 AND 30 then 'SMA0'
			 when SrcSysAlt_Key=120 And C.AssetClassAlt_Key=1 AND ISNULL(MaxDPD,0) BETWEEN 31 AND 60 then 'SMA1'
			 when SrcSysAlt_Key=120 And C.AssetClassAlt_Key=1 AND ISNULL(MaxDPD,0) BETWEEN 61 AND 89 then 'SMA2'
			 when SrcSysAlt_Key=120 And C.AssetClassAlt_Key =2 then 'SUB'  --M2P
			 when SrcSysAlt_Key=120 And C.AssetClassAlt_Key in (3,4,5) then 'DBT'---M2P
			 when SrcSysAlt_Key=120 And C.AssetClassAlt_Key=6 then 'DBT' --M2P  -- CURRENTLY LOSS NOT AVAILABLE
			 end  Source_System_Asset_Classification
      	,case when SrcSysAlt_Key=10 then d.FinacleAssetClassCode 
	         when SrcSysAlt_Key=20 then d.VP_AssetClassCode --VISION PLUS
			 when SrcSysAlt_Key=30 then d.TradeProAssetClassCode--TradePro
             when SrcSysAlt_Key=40 then d.CalypsoAssetClassCode
			 when SrcSysAlt_Key=50 then d.eCBFAssetClassCode
			 when  (@CUTOVERDATE>=@DATE AND SrcSysAlt_Key=60) then D.ProlendzAssetClassCode --d.ProlendzAssetClassCode changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240117
			 when  (@CUTOVERDATE<@DATE AND SrcSysAlt_Key=60) then D.FinacleAssetClassCode --d.ProlendzAssetClassCode changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240117
			 when SrcSysAlt_Key=70 then d.GanasevaAssetClassCode
			 when SrcSysAlt_Key=80 then d.PTSmartAssetClassCode 
			 when SrcSysAlt_Key=90 then d.VeefinAssetClassCode ----Veefin
			 when SrcSysAlt_Key=100 then d.Finacle2AssetClassCode
	 when SrcSysAlt_Key=120 And D.AssetClassAlt_Key=1 AND ISNULL(MaxDPD,0)=0 then 'STD'  --M2P
			 when SrcSysAlt_Key=120 And D.AssetClassAlt_Key=1 AND ISNULL(MaxDPD,0) BETWEEN 1 AND 30 then 'SMA0'
			 when SrcSysAlt_Key=120 And D.AssetClassAlt_Key=1 AND ISNULL(MaxDPD,0) BETWEEN 31 AND 60 then 'SMA1'
			 when SrcSysAlt_Key=120 And D.AssetClassAlt_Key=1 AND ISNULL(MaxDPD,0) BETWEEN 61 AND 89 then 'SMA2'
			 when SrcSysAlt_Key=120 And D.AssetClassAlt_Key =2 then 'SUB'  --M2P
			 when SrcSysAlt_Key=120 And D.AssetClassAlt_Key in (3,4,5) then 'DBT'---M2P
			 when SrcSysAlt_Key=120 And D.AssetClassAlt_Key=6 then 'DBT' --M2P  -- CURRENTLY LOSS NOT AVAILABLE
			--when SrcSysAlt_Key=120 And D.AssetClassAlt_Key=7 then 'WRITE OFF NOT AVLABLE' --M2P
			 end 
			 Homogenized_Asset_Classification
,NCIF_NPA_Date Homogenized_NPA_Date,CASE WHEN @IS_MOC='Y' THEN 'Y'ELSE 'N' END IS_MOC
,NatureofClassification  --20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
,DateofImpacting		--20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
,ImpactingAccountNo		--20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
,ImpactingSourceSystemName	--20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
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
			OR (A.NCIF_ID='1724180' AND @TimeKey=26946) ---- ADDED ON 20231011 FOR REVERSE FEED OF VAIBHAV INTERNATION CASES
			)
       )
AND  A.NCIF_ID = (CASE WHEN @IS_MOC='Y' THEN MOC.NCIF_ID ELSE A.NCIF_Id END)


IF @TimeKey=26841 ---select * from SysDaymatrix where Date='2023-06-27'
	BEGIN
		INSERT INTO ReverseFeedDetails (AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC)
		SELECT AsOnDate,SourceName,UCIF_ID,CIF_ID,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC
		from ReverseFeedDetails_22062023 
	END
	   	
/*** Single reversefeed after MOC Logic  ***/
	IF (Select 1 From ReverseFeedDetails_MOC) IS NOT NULL
		Begin
			Exec [dbo].[Single_Reverse_Feed_PostMOC] 
		End 

UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='Assetclass_Reverse_Feed' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0
GO