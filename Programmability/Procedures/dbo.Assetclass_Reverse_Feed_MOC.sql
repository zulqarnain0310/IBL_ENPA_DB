SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[Assetclass_Reverse_Feed_MOC]
@TimeKey INT 
,@IS_MOC CHAR(1)='N' 

AS
BEGIN
DECLARE @DATE DATE
select @DATE=Date from dbo.SysDataMatrix  where  TimeKey=@TimeKey
DECLARE @CUTOVERDATE DATE='2024-01-24'--changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240126

DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='Assetclass_Reverse_Feed_MOC' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @DATE,@TimeKey,'Assetclass_Reverse_Feed_MOC',GETDATE() 



TRUNCATE TABLE  ReverseFeedDetails_MOC

INSERT INTO ReverseFeedDetails_MOC(AsOnDate,AccountNo,SOL_ID,Scheme_Type,Scheme_Code,CIF_ID,UCIF_ID,SourceName,SrcAssetClass,HomogenizedAssetClass,HomogenizedNpaDt,IS_MOC
,NatureofClassification  --20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
,DateofImpacting		--20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
,ImpactingAccountNo		--20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
,ImpactingSourceSystemName	--20231025 ON UAT FOR COBO BY ZAIN -- ON PROD 20240117
)
Select distinct @DATE As_On_Processing_Date, a.CustomerACID Account_No,a.BranchCode Sol_Id ,
a.ProductType SchemeType,a.ProductCode Scheme_Code,
a.CustomerId Source_System_CIF,A.NCIF_Id Dedupe_ID_UCIC_Enterprise_CIF,
Case when a.SrcSysAlt_Key=100 then 'Finacle-2' Else b.SourceName END SourceName
,case when a.SrcSysAlt_Key=10 then c.FinacleAssetClassCode 
             when a.SrcSysAlt_Key=20 And C.AssetClassAlt_Key=1 then '1'  --VISION PLUS
			when a.SrcSysAlt_Key=20 And C.AssetClassAlt_Key in (2,3,4,5,6) then '8'  --VISION PLUS
			 when a.SrcSysAlt_Key=20 And C.AssetClassAlt_Key=7 then '9' --VISION PLUS
			 when a.SrcSysAlt_Key=30 then c.TradeProAssetClassCode--TradePro
             when a.SrcSysAlt_Key=40 then c.CalypsoAssetClassCode
			 when a.SrcSysAlt_Key=50 then c.eCBFAssetClassCode
			 when  (@CUTOVERDATE>=@DATE AND a.SrcSysAlt_Key=60) then c.ProlendzAssetClassCode --d.ProlendzAssetClassCode changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240117
			 when  (@CUTOVERDATE<@DATE AND a.SrcSysAlt_Key=60) then C.FinacleAssetClassCode --d.ProlendzAssetClassCode changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240117
			 when a.SrcSysAlt_Key=70 then c.GanasevaAssetClassCode
			 when a.SrcSysAlt_Key=80 then c.PTSmartAssetClassCode
			 when a.SrcSysAlt_Key=90 then c.VeefinAssetClassCode ----Veefin
			 when a.SrcSysAlt_Key=100 then c.Finacle2AssetClassCode
when a.SrcSysAlt_Key=120 And C.AssetClassAlt_Key=1 AND ISNULL(a.MaxDPD,0)=0 then 'STD'  --M2P
			 when a.SrcSysAlt_Key=120 And C.AssetClassAlt_Key=1 AND ISNULL(a.MaxDPD,0) BETWEEN 1 AND 30 then 'SMA0'
			 when a.SrcSysAlt_Key=120 And C.AssetClassAlt_Key=1 AND ISNULL(a.MaxDPD,0) BETWEEN 31 AND 60 then 'SMA1'
			 when a.SrcSysAlt_Key=120 And C.AssetClassAlt_Key=1 AND ISNULL(a.MaxDPD,0) BETWEEN 61 AND 89 then 'SMA2'
			 when a.SrcSysAlt_Key=120 And C.AssetClassAlt_Key =2 then 'SUB'  --M2P
			 when a.SrcSysAlt_Key=120 And C.AssetClassAlt_Key in (3,4,5) then 'DBT'---M2P
			 when a.SrcSysAlt_Key=120 And C.AssetClassAlt_Key=6 then 'DBT' --M2P  -- CURRENTLY LOSS NOT AVAILABLE
			 end  Source_System_Asset_Classification
      	,case when a.SrcSysAlt_Key=10 then d.FinacleAssetClassCode 
	         when a.SrcSysAlt_Key=20 then d.VP_AssetClassCode --VISION PLUS
			 when a.SrcSysAlt_Key=30 then d.TradeProAssetClassCode--TradePro
             when a.SrcSysAlt_Key=40 then d.CalypsoAssetClassCode
			 when a.SrcSysAlt_Key=50 then d.eCBFAssetClassCode
			 when  (@CUTOVERDATE>=@DATE AND a.SrcSysAlt_Key=60) then D.ProlendzAssetClassCode --d.ProlendzAssetClassCode changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240117
			 when  (@CUTOVERDATE<@DATE AND a.SrcSysAlt_Key=60) then D.FinacleAssetClassCode --d.ProlendzAssetClassCode changed on 20231021 by zain for finacle prolendz same source-- ON PROD 20240117
			 when a.SrcSysAlt_Key=70 then d.GanasevaAssetClassCode
			 when a.SrcSysAlt_Key=80 then d.PTSmartAssetClassCode 
			 when a.SrcSysAlt_Key=90 then d.VeefinAssetClassCode ----Veefin
			 when a.SrcSysAlt_Key=100 then d.Finacle2AssetClassCode
	 when a.SrcSysAlt_Key=120 And D.AssetClassAlt_Key=1 AND ISNULL(a.MaxDPD,0)=0 then 'STD'  --M2P
			 when a.SrcSysAlt_Key=120 And D.AssetClassAlt_Key=1 AND ISNULL(a.MaxDPD,0) BETWEEN 1 AND 30 then 'SMA0'
			 when a.SrcSysAlt_Key=120 And D.AssetClassAlt_Key=1 AND ISNULL(a.MaxDPD,0) BETWEEN 31 AND 60 then 'SMA1'
			 when a.SrcSysAlt_Key=120 And D.AssetClassAlt_Key=1 AND ISNULL(a.MaxDPD,0) BETWEEN 61 AND 89 then 'SMA2'
			 when a.SrcSysAlt_Key=120 And D.AssetClassAlt_Key =2 then 'SUB'  --M2P
			 when a.SrcSysAlt_Key=120 And D.AssetClassAlt_Key in (3,4,5) then 'DBT'---M2P
			 when a.SrcSysAlt_Key=120 And D.AssetClassAlt_Key=6 then 'DBT' --M2P  -- CURRENTLY LOSS NOT AVAILABLE
			--when a.SrcSysAlt_Key=120 And D.AssetClassAlt_Key=7 then 'WRITE OFF NOT AVLABLE' --M2P
			 end 
			 Homogenized_Asset_Classification
			,a.NCIF_NPA_Date Homogenized_NPA_Date
			,CASE WHEN @IS_MOC='Y' THEN 'Y'ELSE 'N' END IS_MOC
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
inner join NPA_IntegrationDetails_Mod f on a.EffectiveFromTimeKey=@Timekey
and a.NCIF_Id=f.NCIF_Id
and a.CustomerACID=f.CustomerACID
and a.CustomerId=f.customerid 
--and Cast(a.MOC_Date as date) in (CAST(Getdate() as date)) ---–current date commented on 20250129 
/* Added to pull only assetclass change  in MOC customer MOC start*/
Where (isnull(a.AC_AssetClassAlt_Key,0)<>isnull(a.NCIF_AssetClassAlt_Key,0)
OR ISNULL(a.AC_NPA_Date,'1900-01-01')<>ISNULL(a.NCIF_NPA_Date,'1900-01-01'))
	
/* Added to pull only assetclass change in MOC customer MOC end*/

UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='Assetclass_Reverse_Feed_MOC' AND [EXT_DATE]=@DATE AND ISNULL([Audit_Flg],0)=0

END
GO