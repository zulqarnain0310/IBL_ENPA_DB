SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[AssetClassDegradation_BKP_20250509] --27468
@TIMEKEY INT
WITH RECOMPILE
AS 
DECLARE @Ext_Date DATE=(select Date from IBL_ENPA_DB.dbo.SysDataMatrix  where TimeKey=27468)
--DECLARE @STD SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='STANDARD' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
--DECLARE @SubSTD SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='SUBSTANDARD' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
--DECLARE @DB1 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='DOUBTFUL-1' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
--DECLARE @DB2 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='DOUBTFUL-2' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
--DECLARE @DB3 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='DOUBTFUL-3' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
--DECLARE @LOS SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='LOSS' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
--DECLARE @WRE SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='WRITE OFF' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)

-----Changed on 16-06-2021 by Sunil

DECLARE @CUTOVERDATE DATE='2024-01-24'--ADDED FOR FINACLE PROLEDZ SAME SOURCE  SYSTEM :- PROLENDZ CLASSIFICATION IN D2K 20231110 ON PROD 20240127
DECLARE @DATE DATE=(SELECT DATE FROM SysDataMatrix WHERE CurrentStatus='C')--ADDED FOR FINACLE PROLEDZ SAME SOURCE  SYSTEM :- PROLENDZ CLASSIFICATION IN D2K 20231110 ON PROD 20240117
DECLARE @STD SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='STD' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @SubSTD SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='SUB' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @DB1 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='DB1' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @DB2 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='DB2' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @DB3 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='DB3' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @LOS SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='LOS' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @WRE SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='WO' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
/* START RESTRUCTURE DEPLOYMENT - 17062023  - NEW VARIABLE DECLARATION FOR RESTRUCTURE DEGRATDE*/
DECLARE @NaturalCalamity	INT=(SELECT ParameterAlt_Key FROM   DimParameter WHERE EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468 AND DimParameterName='TypeofRestructuring' AND ParameterName='Natural Calamity')
DECLARE @DCCO				INT=(SELECT ParameterAlt_Key FROM   DimParameter WHERE EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468 AND DimParameterName='TypeofRestructuring' AND ParameterName='DCCO')
DECLARE @Others_COMGT		INT=(SELECT ParameterAlt_Key FROM   DimParameter WHERE EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468 AND DimParameterName='TypeofRestructuring' AND ParameterName='Others_COMGT')
/* END RESTRUCTURE DEPLOYMENT - 17062023 */



DECLARE @RES_TYE_OTH INT=(SELECT ParameterAlt_Key FROm DimParameter WHERE EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468 AND DimParameterName='TypeofRestructuring' and ParameterName='Others')
DECLARE @Others_Jun19 INT=(SELECT ParameterAlt_Key FROM   DimParameter WHERE EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468 AND DimParameterName='TypeofRestructuring' AND ParameterName='Others_Jun19')

 


IF OBJECT_ID('TEMPDB..#NCIF_ASSET') IS NOT NULL
   DROP TABLE #NCIF_ASSET

BEGIN TRY
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='AssetClassDegradation' AND [EXT_DATE]=@Ext_Date AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Ext_Date,27468,'AssetClassDegradation',GETDATE()
BEGIN TRAN
BEGIN
--Update NPA DATE and asset class For StockStatementDate if stock statement DPD >180 days  
UPDATE NPA_IntegrationDetails_20250509
SET NCIF_NPA_Date=CASE WHEN IsFraud='Y' And AC_AssetClassAlt_Key=1  THEN @Ext_Date
					   WHEN IsFraud='Y' And AC_AssetClassAlt_Key<>1  THEN AC_NPA_Date
                       WHEN ISNULL(DPD_StockStmt,0)>180 THEN DATEADD(DAY,(-(DPD_StockStmt))+181,@Ext_Date)
					  --- WHEN DPD_StockStmt=0 THEN @Ext_Date----29102021 dpd zero bug
				ELSE AC_NPA_Date 
			    END 
   ,FlgDeg=CASE WHEN ISNULL(DPD_StockStmt,0)>180 OR IsFraud='Y' -----OR DPD_StockStmt=0--29102021 dpd zero bug
   THEN 'Y' 
                WHEN AC_NPA_Date IS NOT NULL THEN 'Y' 
			END 
   ,NCIF_AssetClassAlt_Key=(Case WHEN IsFraud='Y' THEN @LOS
                                ----- WHEN DPD_StockStmt=0 THEN @SubSTD----29102021 dpd zero bug 
                                 When ISNULL(DPD_StockStmt,0)>180 
                                       THEN (CASE when DATEDIFF(DAY,DATEADD(DAY,(-(DPD_StockStmt))+181,@Ext_Date),@Ext_Date) between 0 and 365 then @SubSTD
							                      when DATEDIFF(DAY,DATEADD(DAY,(-(DPD_StockStmt))+181,@Ext_Date),@Ext_Date) between 366 and 730 then @DB1
							                      when DATEDIFF(DAY,DATEADD(DAY,(-(DPD_StockStmt))+181,@Ext_Date),@Ext_Date) between 731 and 1460 then @DB2
							                      when DATEDIFF(DAY,DATEADD(DAY,(-(DPD_StockStmt))+181,@Ext_Date),@Ext_Date) between 1461 and 99997 then @DB3
							                      when DATEDIFF(DAY,DATEADD(DAY,(-(DPD_StockStmt))+181,@Ext_Date),@Ext_Date) =99998 then @LOS
							                ELSE AC_AssetClassAlt_Key
							              END)
						  ELSE  AC_AssetClassAlt_Key
						  END) 
   ,DegReason=(Case WHEN IsFraud='Y' THEN 'Degrade due to Fraud'
                    ---- WHEN DPD_StockStmt=0 THEN 'Degrade due to Stock Statement'-----29102021 dpd zero bug
                     When ISNULL(DPD_StockStmt,0)>180 THEN 'Degrade due to Stock Statement'
					 ELSE  NULL
				END) 
FROM NPA_IntegrationDetails_20250509 A
WHERE (((DPD_StockStmt>180 )---OR DPD_StockStmt=0) -----29102021 dpd zero bug
and ISNULL(PrincipleOutstanding,0)>0)
      OR IsFraud='Y'
	 /* OR SrcSysAlt_Key=(SELECT SourceAlt_Key FROm DimSourceSystem 
                                                     WHERE EffectiveFromTimeKey<=27468 
                                                       AND EffectiveToTimeKey>=27468 
                                                       AND SourceName='VISION PLUS')*/--Shifted to merge
													   ) 
AND AC_AssetClassAlt_Key =(Case when IsFraud='Y' And AC_AssetClassAlt_Key<>@LOS Then AC_AssetClassAlt_Key Else @STD End)    ------ Added On 16-06-2021 for Fraud
AND EffectiveFromTimeKey<=27468 
AND EffectiveToTimeKey>=27468 
AND AC_Closed_Date IS NULL

--Deg account if (IsOTS='Y' OR IsARC_Sale='Y'
UPDATE NPA_IntegrationDetails_20250509 
SET    NCIF_AssetClassAlt_Key=@SubSTD,
       FlgDeg='Y',
	   NCIF_NPA_Date=@Ext_Date,
	   DegReason=CASE WHEN IsOTS='Y' THEN 'Degrade Due to OTS Flag' When IsARC_Sale='Y' Then 'Degrade Due to ARC Flag' ELSE 'Degrade Due to DCCO Date'  END
WHERE EffectiveFromTimeKey<=27468
AND EffectiveToTimeKey>=27468
AND AC_AssetClassAlt_Key=@STD
AND ISNULL(NCIF_AssetClassAlt_Key,@STD)=@STD 
AND (IsOTS='Y' OR IsARC_Sale='Y' OR 
     (DCCO_Date<@Ext_Date AND PROJ_COMPLETION_DATE IS NULL)--Project completion date is added on 12-09-2021
	 )
/* START RESTRUCTURE DEPLOYMENT ON 17062023 --CODE COMMENTED AND ALTERNATE CODE ADDED */
--Restructure
/*   COMMENTED  BY AMAR ON 17-03-2032 FOR RESSTRUCTURE CHANGES */ --- to be confirmed with amar by ssk
--------Changed by Sunil on 18-06-2021  for Handling Restructure and Stockstatement

----UPDATE NI
----SET NCIF_AssetClassAlt_Key=(CASE WHEN AC_AssetClassAlt_Key=@STD 
----								 AND RES.RestructureTypeAlt_Key in (@RES_TYE_OTH,@Others_Jun19)
----                                   THEN @SubSTD
----                              ELSE NCIF_AssetClassAlt_Key
----                         END)
----       ,NCIF_NPA_Date=CASE WHEN RES.RestructureDt<ISNULL(NCIF_NPA_Date,'2099-01-01') 
----							AND AC_AssetClassAlt_Key=@STD 
----							AND RES.RestructureTypeAlt_Key in (@RES_TYE_OTH,@Others_Jun19)
----                              THEN RES.RestructureDt
----                         WHEN (RES.RestructureDt<ISNULL(NCIF_NPA_Date,'2099-01-01')
----						   OR  ISNULL(AC_NPA_Date,'2099-01-01')<ISNULL(NCIF_NPA_Date,'2099-01-01'))
----						  AND RES.RestructureDt<ISNULL(AC_NPA_Date,'2099-01-01') 
----						  AND AC_AssetClassAlt_Key<>@STD 
----						  AND ISNULL(RES.RestructureTypeAlt_Key,0)not in (@RES_TYE_OTH,@Others_Jun19)
----                              THEN RES.RestructureDt
----                         ELSE ISNULL(NCIF_NPA_Date,AC_NPA_Date)
----		               END,
----		FlgDeg=(CASE WHEN AC_AssetClassAlt_Key=@STD 
----					  AND RES.RestructureTypeAlt_Key in (@RES_TYE_OTH,@Others_Jun19)
----                          THEN 'Y'
----                     ELSE FlgDeg
----                END),
----         DegReason= (CASE WHEN AC_AssetClassAlt_Key=@STD 
----								 AND RES.RestructureTypeAlt_Key in (@RES_TYE_OTH,@Others_Jun19)
----                                   THEN 'Degrade Due to Restructure Account'
----                              ELSE DegReason
----                         END) 
----FROM NPA_IntegrationDetails_20250509 NI 
----INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=27468 
----                                     AND NI.EffectiveToTimeKey>=27468 
----									 AND RES.EffectiveFromTimeKey<=27468 
----                                     AND RES.EffectiveToTimeKey>=27468 
----									---- and ni.NCIF_Id=RES.RefCustomer_CIF
----									 AND NI.CustomerId=RES.RefCustomerId
----									 AND NI.CustomerACID=RES.RefSystemAcId
----WHERE IsRestructured='Y'
----AND DATEADD(YEAR,1,ISNULL(RES.RepaymentStartDate,RES.RestructureDt))>=@Ext_Date


--------Changed for Multiple Restructure Accounts of single ncif 21-03-2022
/*
If OBJECT_ID('TempDB..#Restructure') is not Null
Drop Table #Restructure

Select * into #Restructure from CURDAT.AdvAcRestructureDetail where EffectiveFromTimeKey<=27468 and EffectiveToTimeKey>=27468

ALter Table #Restructure Add RestructureDt_Min DAte


Update A set RestructureDt_Min=B.RestructureDt
 from #Restructure A
inner Join (select RefCustomer_CIF,MIN(RestructureDt)RestructureDt from #Restructure group by RefCustomer_CIF)B On A.RefCustomer_CIF=B.RefCustomer_CIF

Update NI Set NCIF_NPA_Date=CASE WHEN RES.RestructureDt_MIn<ISNULL(NCIF_NPA_Date,'2099-01-01') 
							AND AC_AssetClassAlt_Key=@STD 
							AND RES.RestructureTypeAlt_Key in (@RES_TYE_OTH,@Others_Jun19)
                              THEN RES.RestructureDt
                         WHEN (RES.RestructureDt_MIn<ISNULL(NCIF_NPA_Date,'2099-01-01')
						   OR  ISNULL(AC_NPA_Date,'2099-01-01')<ISNULL(NCIF_NPA_Date,'2099-01-01'))
						  AND RES.RestructureDt_MIn<ISNULL(AC_NPA_Date,'2099-01-01') 
						  AND AC_AssetClassAlt_Key<>@STD 
						  AND ISNULL(RES.RestructureTypeAlt_Key,0)not in (@RES_TYE_OTH,@Others_Jun19)
                              THEN RES.RestructureDt_MIn
                         ELSE ISNULL(NCIF_NPA_Date,AC_NPA_Date)
		               END

FROM NPA_IntegrationDetails_20250509 NI 
INNER JOIN #Restructure RES ON NI.EffectiveFromTimeKey<=27468 
                                     AND NI.EffectiveToTimeKey>=27468 
									 AND RES.EffectiveFromTimeKey<=27468 
                                     AND RES.EffectiveToTimeKey>=27468 
									---- and ni.NCIF_Id=RES.RefCustomer_CIF
									 AND NI.CustomerId=RES.RefCustomerId
									 AND NI.CustomerACID=RES.RefSystemAcId
WHERE IsRestructured='Y'
AND DATEADD(YEAR,1,ISNULL(RES.RepaymentStartDate,RES.RestructureDt))>=@Ext_Date
  */
  /* END RESTRUCTURE DEPLOYMENT ON 17062023 --CODE COMMENTED AND ALTERNATE CODE ADDED*/

/* START  17062023 DEPLOYMENT FOR RESSTRUCTURE CHANGES*/
/*  ADDED BY AMAR ON 17-03-2032 FOR RESSTRUCTURE CHANGES*/
	UPDATE NI
			SET	 NCIF_AssetClassAlt_Key=@SubSTD
				,NCIF_NPA_Date=RES.RestructureDt
				,FlgDeg='Y'
				,DegReason=  'Degrade Due to Restructure Account'
	FROM NPA_IntegrationDetails_20250509 NI 
	INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=27468 
										 AND NI.EffectiveToTimeKey>=27468 
										 AND RES.EffectiveFromTimeKey<=27468 
										 AND RES.EffectiveToTimeKey>=27468 
										 AND NI.CustomerId=RES.RefCustomerId
										 AND NI.CustomerACID=RES.RefSystemAcId
	WHERE IsRestructured='Y'
		AND AC_AssetClassAlt_Key=@STD
		AND ISNULL(RES.RestructureTypeAlt_Key,0) NOT IN (@NaturalCalamity,@DCCO,@Others_COMGT) 
		AND ISNULL(RestructureDt,'1900-01-01')>'2021-12-31'

		/* Added these code as on date 21042023 on prod for restructure accts by satish*/
	/* NEW RESTRUCTURE ACCOUNT EXISTING NPA - IF RESTRYCTURE DATE IS NCIF_NPA_Date THEN RESTRYCTURE DATE WILL BE MARKED AS NCIF_NPA_Date */

		DROP TABLE IF EXISTS #RESTRUCTURE_FINACLE_CASES
	SELECT NI.CustomerACID INTO #RESTRUCTURE_FINACLE_CASES
	FROM NPA_IntegrationDetails_20250509 NI 
	INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=27468 
										 AND NI.EffectiveToTimeKey>=27468 
										 AND RES.EffectiveFromTimeKey<=27468 
										 AND RES.EffectiveToTimeKey>=27468 
										 AND NI.CustomerId=RES.RefCustomerId
										 AND NI.CustomerACID=RES.RefSystemAcId
			
	WHERE 
		IsRestructured='Y'
		AND AC_AssetClassAlt_Key in (2,3,4,5,6)
		AND ISNULL(RestructureDt,'2099-01-01')<AC_NPA_Date
	/* NEW RESTRUCTURE ACCOUNT EXISTING NPA - IF RESTRYCTURE DATE IS NCIF_NPA_Date THEN RESTRYCTURE DATE WILL BE MARKED AS NCIF_NPA_Date */
	UPDATE NI
			SET	NCIF_NPA_Date=RES.RestructureDt
	FROM NPA_IntegrationDetails_20250509 NI 
	INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=27468 
										 AND NI.EffectiveToTimeKey>=27468 
										 AND RES.EffectiveFromTimeKey<=27468 
										 AND RES.EffectiveToTimeKey>=27468 
										 AND NI.CustomerId=RES.RefCustomerId
										 AND NI.CustomerACID=RES.RefSystemAcId
			
	WHERE 
		IsRestructured='Y'
		AND AC_AssetClassAlt_Key in (2,3,4,5,6)
		AND ISNULL(RestructureDt,'2099-01-01')<AC_NPA_Date
/* END  17062023 DEPLOYMENT FOR RESSTRUCTURE CHANGES*/

-----------------------------------
------ Finacle asset class updation based on npa dt added by satish as on date 09122022
--     REQ5562452 CR FOR CHANGE OF ASSET CLASS FOR FINACLE SYSTEM

------ Finacle asset class updation based on npa dt added by satish as on date 09122022
--     REQ5562452 CR FOR CHANGE OF ASSET CLASS FOR FINACLE SYSTEM

/* Added these code as on date 21042023 on prod for asset claasification for finacle by satish*/
DECLARE @finacleSourceAltKey as Int =(Select SourceAlt_Key from DimSourceSystem where SourceName='Finacle')
DECLARE @ProlendzSourceAltKey VARCHAR(10) =(Select STRING_AGG(SourceAlt_Key,',') from DimSourceSystem where SourceName IN ('Finacle','Prolendz'))--ADDED FOR FINACLE PROLEDZ SAME SOURCE  SYSTEM :- PROLENDZ CLASSIFICATION IN D2K 20231110 ON PROD 20240117
DECLARE @SUB_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='SUB_Days' 
AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @DB1_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB1_Days' 
AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @DB2_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB2_Days' 
AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)

DECLARE @SUB_Year INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='SUB_Year' 
AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @DB1_Year INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB1_Year' 
AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
DECLARE @DB2_Year INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB2_Year' 
AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
--select @SUB_Days,@DB1_Days,@DB2_Days

DROP TABLE IF EXISTS #CUTSOURCEALTKEY
CREATE TABLE #CUTSOURCEALTKEY(SrcSysAlt_Key INT)
IF @CUTOVERDATE<@DATE
BEGIN
INSERT INTO #CUTSOURCEALTKEY
SELECT value FROM STRING_SPLIT(@ProlendzSourceAltKey, ',')
END
ELSE
BEGIN
INSERT INTO #CUTSOURCEALTKEY
SELECT @finacleSourceAltKey
END



Drop Table if exists #Audit_Finacle
Select NCIF_Id,CustomerId,CustomerACID,SrcSysAlt_Key 
,AC_AssetClassAlt_Key Source_AC_AssetClassAlt_Key,AC_NPA_Date Source_AC_NPA_Date,
DbtDT Source_dbtdt,Getdate() InsertDate
,Cast(0 as int )Calc_AC_AssetClassAlt_Key 
,Cast(Null as Date) Calc_AC_NPA_Date 
,Cast(null as Date) Calc_dbtdt 
,EffectiveFromTimeKey,EffectiveToTimeKey
into #Audit_Finacle
from NPA_IntegrationDetails_20250509 where EffectiveFromTimeKey<=27468 and EffectiveToTimeKey>=27468
and SrcSysAlt_Key IN (SELECT SrcSysAlt_Key FROM #CUTSOURCEALTKEY)--2024-01-27
/* START 17062023 DEPLOYMENT FOR RESSTRUCTURE CHANGES*/
/* AMAR  - 18092023 - FILTERED RESTRUCTURE ACCOUNTS NCIF IDs FOR USE IN AGING */
---???? to be created on the temp table basis

	DROP TABLE IF EXISTS #RESTR_ACS
	SELECT NI.CustomerACID --- ???? Acccount related cols to be taken
		INTO #RESTR_ACS
	FROM NPA_IntegrationDetails_20250509 NI 
		INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=27468 
					AND NI.EffectiveToTimeKey>=27468 
					AND RES.EffectiveFromTimeKey<=27468 
					AND RES.EffectiveToTimeKey>=27468 
					AND NI.CustomerId=RES.RefCustomerId
					AND NI.CustomerACID=RES.RefSystemAcId
	WHERE IsRestructured='Y'
		AND 
		( 
			(AC_AssetClassAlt_Key in (2,3,4,5,6) AND ISNULL(RestructureDt,'1900-01-01')>'2021-12-31') 
		 OR 
			( AC_AssetClassAlt_Key=@STD AND RES.RestructureTypeAlt_Key NOT IN (@NaturalCalamity,@DCCO,@Others_COMGT) 
			AND ISNULL(RestructureDt,'1900-01-01')>'2021-12-31')	
		)
/* END  17062023 DEPLOYMENT FOR RESSTRUCTURE CHANGES*/	

Update NPA_IntegrationDetails_20250509 set  
dbtdt=case when DbtDT IS NULL and 
--DATEDIFF(YEAR,coalesce(NCIF_NPA_Date,AC_NPA_Date),@Ext_Date)>@SUB_Year 
 IBL_ENPA_DB.[dbo].[GetLeapYearDate] (coalesce(NCIF_NPA_Date,AC_NPA_Date),@DB1_Year)<=@Ext_Date --As per discussion SSK Change to implement Yearly Logic Added by Pranay on 03032023
--then DATEADD(year,1,coalesce(NCIF_NPA_Date,AC_NPA_Date))
	then IBL_ENPA_DB.[dbo].[GetLeapYearDate] (coalesce(NCIF_NPA_Date,AC_NPA_Date),@DB1_Year)
when DbtDT IS not null then DbtDT  ---  added by satish 
end 
from NPA_IntegrationDetails_20250509 A 
INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When A.NCIF_AssetClassAlt_Key is not null then A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
WHERE B.AssetClassShortName NOT IN('LOS','WO') ------ Added by SSK to prevent classification of written of accounts on date 22042023 
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(A.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 AND ISNULL(A.FlgErosion,'N')<>'Y'
 AND  A.EffectiveFromTimeKey=27468 AND A.EffectiveToTimeKey=27468
--and SrcSysAlt_Key=@finacleSourceAltKey
 --- ???? or (RES.RestructureDt<AC_NPA_Date )
 AND (SrcSysAlt_Key IN (SELECT SrcSysAlt_Key FROM #CUTSOURCEALTKEY)--2024-01-27
		OR EXISTS (SELECT CustomerACID FROM #RESTR_ACS RES WHERE RES.CustomerACID=A.CustomerACID) ---/* 17062023 DEPLOYMENT FOR RESSTRUCTURE CHANGES*/
		OR EXISTS (SELECT CustomerACID FROM #RESTRUCTURE_FINACLE_CASES RES1 WHERE RES1.CustomerACID=A.CustomerACID)
	 )

	
 /* If DBT Dt is available , then we need to do Asset Classification ( Logic as implemented for Finacle )
	    added by satish as on date 09052023 */
		Drop table if exists #Erosion_Accts
		Select CustomerACID Into #Erosion_Accts   from NPA_IntegrationDetails_20250509 where EffectiveFromTimeKey<=27468
		and EffectiveToTimeKey>=27468 --and SecuredFlag='Y' and IsFunded='Y'
		and dbtdt is not null and LossDT is null  ----- added on 22052023 for erosion cases asset class
/* If loss Dt is available , then we need to maintain Asset Classification as loss added by satish as on date 09052023 */
  Update NPA_IntegrationDetails_20250509 set  
NCIF_AssetClassAlt_Key=@LOS
from NPA_IntegrationDetails_20250509 A
INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When A.NCIF_AssetClassAlt_Key is not null then A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
WHERE 
   B.AssetClassShortName NOT IN ('WO') ------ Added by SSK to prevent classification of written of accounts on date 22042023 
AND (ISNULL(A.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 ---AND ISNULL(NI.FlgErosion,'N')<>'Y' /* as per discussion with ssk records,with erosion will also undergo ageing on the basis of dbt dt */
 AND  A.EffectiveFromTimeKey=27468 AND A.EffectiveToTimeKey=27468
 and LossDT is not null ----- added on 22052023 for erosion cases asset class

Update NPA_IntegrationDetails_20250509 set  
NCIF_AssetClassAlt_Key=Case when --DbtDT is null and DATEDIFF(YEAR,AC_NPA_Date,@Ext_Date)<=@SUB_Year then @SubSTD   --- dbtdt came in source
        DbtDT is null and IBL_ENPA_DB.[dbo].[GetLeapYearDate] (COALESCE(NCIF_NPA_Date,AC_NPA_DATE),@SUB_Year)>@Ext_Date then @SubSTD  
	  --when DbtDT is not null and DATEDIFF(YEAR,DbtDT,@Ext_Date)<=@DB1_Year then @DB1
	   when DbtDT is not null and  -- As per discussion SSK Change to implement Yearly Logic Added by Pranay on 03032023
	   IBL_ENPA_DB.[dbo].[GetLeapYearDate] (DbtDT,@DB1_Year) > @Ext_Date then @DB1
      --when DbtDT is not null and DATEDIFF(YEAR,DbtDT,@Ext_Date)<=(@DB1_Year+@DB2_Year) then @DB2
	    when DbtDT is not null and  -- As per discussion SSK Change to implement Yearly Logic Added by Pranay on 03032023
	   IBL_ENPA_DB.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) > @Ext_Date then @DB2

	  --when DbtDT is not null and DATEDIFF(YEAR,DbtDT,@Ext_Date) >=(@DB1_Year+@DB2_Year) then @DB3 end  
	    when DbtDT is not null and  -- As per discussion SSK Change to implement Yearly Logic Added by Pranay on 03032023
	   IBL_ENPA_DB.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) <= @Ext_Date then @DB3 END

from NPA_IntegrationDetails_20250509 A
INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When A.NCIF_AssetClassAlt_Key is not null then A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
WHERE --B.AssetClassShortName NOT IN('LOS')
   B.AssetClassShortName NOT IN ('LOS','WO') ------ Added by SSK to prevent classification of written of accounts on date 22042023 
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(A.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 --AND ISNULL(A.FlgErosion,'N')<>'Y' /* as per discussion with ssk records,with erosion will also undergo ageing on the basis of dbt dt */ ----- added on 22052023 for erosion cases asset class
 AND  A.EffectiveFromTimeKey=27468 AND A.EffectiveToTimeKey=27468
 ---------AND (SrcSysAlt_Key=@finacleSourceAltKey 
 --- ???? or (RES.RestructureDt<AC_NPA_Date )
 AND (SrcSysAlt_Key IN (SELECT SrcSysAlt_Key FROM #CUTSOURCEALTKEY)--2024-01-27
		OR EXISTS (SELECT CustomerACID FROM #RESTR_ACS RES WHERE RES.CustomerACID=A.CustomerACID)  ---/* 17062023 DEPLOYMENT FOR RESSTRUCTURE CHANGES*/
	    OR EXISTS (SELECT CustomerACID FROM #RESTRUCTURE_FINACLE_CASES RES1 WHERE RES1.CustomerACID=A.CustomerACID)
	    OR EXISTS (SELECT CustomerACID FROM #Erosion_Accts RES2 WHERE RES2.CustomerACID=A.CustomerACID)   /* If DBT Dt is available , then we need to do Asset Classification ( Logic as implemented for Finacle ) added by satish as on date 09052023 */
		)  ----- added on 22052023 for erosion cases asset class
	
 Update A set a.Calc_AC_AssetClassAlt_Key=b.AC_AssetClassAlt_Key
 ,a.Calc_AC_NPA_Date=b.AC_NPA_Date
 ,a.Calc_dbtdt=b.DbtDT
 from #Audit_Finacle A inner Join
 NPA_IntegrationDetails_20250509 b
 on a.EffectiveFromTimeKey<=27468 and a.EffectiveToTimeKey>=27468
 and b.EffectiveFromTimeKey<=27468 and b.EffectiveToTimeKey>=27468
Delete from AuditTrailAssetClassChange where SrcSysAlt_Key IN (SELECT SrcSysAlt_Key FROM #CUTSOURCEALTKEY)--2024-01-27
 and EffectiveFromTimeKey<=27468 and EffectiveToTimeKey>=27468

 Insert into AuditTrailAssetClassChange
 (
 NCIF_Id
,CustomerId
,CustomerACID	
,SrcSysAlt_Key	
,Source_AC_AssetClassAlt_Key	
,Source_AC_NPA_Date	
,Source_dbtdt	
,InsertDate	
,Calc_AC_AssetClassAlt_Key	
,Calc_AC_NPA_Date	
,Calc_dbtdt	
,EffectiveFromTimeKey	
,EffectiveToTimeKey
)
 Select 
 NCIF_Id
,CustomerId
,CustomerACID	
,SrcSysAlt_Key	
,Source_AC_AssetClassAlt_Key	
,Source_AC_NPA_Date	
,Source_dbtdt	
,InsertDate	
,Calc_AC_AssetClassAlt_Key	
,Calc_AC_NPA_Date	
,Calc_dbtdt	
,EffectiveFromTimeKey	
,EffectiveToTimeKey
 from #Audit_Finacle 
 where ISNULL(Calc_AC_AssetClassAlt_Key,0)<>ISNULL(Source_AC_AssetClassAlt_Key,0)
 or ISNULL(Calc_AC_NPA_Date,'')<>ISNULL(Source_AC_NPA_Date,'')
 or ISNULL(Calc_dbtdt,'')<>ISNULL(Source_dbtdt,'')
------------------Finacle-2 ----

--Exec Finacle2Degradation

--------------------

------------------------------------------Finacle-2  Added on 29/12/2021 DPD Calculation ANd NPA Date Calculation -------
Declare @SourceAltKey as Int =(Select SourceAlt_Key from DimSourceSystem where SourceName='Finacle2')


Update A set NCIF_AssetClassAlt_Key=2,NCIF_NPA_Date=DATEADD(D,-(A.MaxDPD-91),@Ext_Date)     ------DATEADD(D,-90,PrincOverdueSinceDt) 
--select DateDiff(DAY,PrincOverdueSinceDt,'2021-12-22'),PrincOverdueSinceDt,DATEADD(D,-90,PrincOverdueSinceDt),* 
from NPA_IntegrationDetails_20250509 A where A.SrcSysAlt_Key=@SourceAltKey and ISNULL(A.MaxDPD,0)>=91   -----------A.dpd_overdueloans>90
AND  A.EffectiveFromTimeKey<=27468 AND A.EffectiveToTimeKey>=27468
--And ISNUll(A.Balance,0)>0 ANd ISNULL(A.PrincipleOutstanding,0)>0
And ISNULL(A.AC_AssetClassAlt_Key,0)=1 And ISNULL(A.NCIF_AssetClassAlt_Key,1)<>6




------------------------Aging   Added on 29/12/2021 for Finacle-2 Aging------- 




/* Declared this days variables above for finacle asset class handling added as on date 21042023*/
--DECLARE @SUB_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='SUB_Days' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468 )
--DECLARE @DB1_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB1_Days' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468 )
--DECLARE @DB2_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB2_Days' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468 )

--Select A.*
--FROM NPA_IntegrationDetails_20250509 A 
--INNER JOIN DimAssetClass B  ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
--AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
--WHERE B.AssetClassShortName NOT IN('STD','LOS')
-- AND ISNULL(A.FlgDeg,'N')<>'Y'  AND (ISNULL(A.FlgProcessing,'N')='N')
-- AND A.NCIF_NPA_Date IS NOT NULL  AND ISNULL(A.FlgErosion,'N')<>'Y'
-- AND  A.EffectiveFromTimeKey=27468 AND A.EffectiveToTimeKey=27468
-- And A.SrcSysAlt_Key=@SourceAltKey
-- And A.NCIF_Id='69700941'

 
--Select A.*
--FROM NPA_IntegrationDetails_20250509 A 
----INNER JOIN DimAssetClass B  ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
----AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
--WHERE A.NCIF_Id='69700941'
 
UPDATE A SET A.NCIF_AssetClassAlt_Key= (
                                        CASE  WHEN  DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date   THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='SUB' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
										  WHEN     DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date   THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB1' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
									      WHEN     DATEADD(DAY,@SUB_Days+@DB1_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days+@DB2_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB2' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
									       WHEN    DATEADD(DAY,(@DB1_Days+@SUB_Days+@DB2_Days),(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date  THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB3' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
									     --  WHEN    DATEADD(DD,1,DATEADD(MONTH,(@DB1_Days+@SUB_Days+@DB2_Days),A.SysNPA_Dt))<=@Ext_Date  THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB3' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
										 --  ELSE A.SysAssetClassAlt_Key
									   END)
          ,A.DBTDT= (CASE 
									       WHEN  DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date  THEN DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))
									       WHEN  DATEADD(DAY,@SUB_Days+@DB1_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days+@DB2_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date   THEN DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))
									       WHEN  DATEADD(DAY,(@DB1_Days+@SUB_Days+@DB2_Days),(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date THEN DATEADD(DAY,(@SUB_Days),(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))
									     --  WHEN  DATEADD(DD,1,DATEADD(MONTH,(@DB1_Days+@SUB_Days+@DB2_Days),A.SysNPA_Dt))<=@Ext_Date THEN DATEADD(DD,1,DATEADD(MONTH,(@SUB_Days),A.SysNPA_Dt))
										 --  ELSE DBTDT 
									   END)

FROM NPA_IntegrationDetails_20250509 A 
INNER JOIN DimAssetClass B  ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
WHERE B.AssetClassShortName NOT IN('STD','LOS')
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(A.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 AND ISNULL(A.FlgErosion,'N')<>'Y'
 AND  A.EffectiveFromTimeKey=27468 AND A.EffectiveToTimeKey=27468
 And A.SrcSysAlt_Key=@SourceAltKey

 /*
UPDATE A SET A.NCIF_AssetClassAlt_Key= (
                                        CASE  WHEN  DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)>@Ext_Date   THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='SUB' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
										  WHEN     DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days,A.NCIF_NPA_Date)>@Ext_Date   THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB1' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
									      WHEN     DATEADD(DAY,@SUB_Days+@DB1_Days,A.NCIF_NPA_Date)<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days+@DB2_Days,A.NCIF_NPA_Date)>@Ext_Date THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB2' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
									       WHEN    DATEADD(DAY,(@DB1_Days+@SUB_Days+@DB2_Days),A.NCIF_NPA_Date)<=@Ext_Date  THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB3' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
									     --  WHEN    DATEADD(DD,1,DATEADD(MONTH,(@DB1_Days+@SUB_Days+@DB2_Days),A.SysNPA_Dt))<=@Ext_Date  THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB3' AND EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey>=27468)
										 --  ELSE A.SysAssetClassAlt_Key
									   END)
          ,A.DBTDT= (CASE 
									       WHEN  DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days,A.NCIF_NPA_Date)>@Ext_Date  THEN DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)
									       WHEN  DATEADD(DAY,@SUB_Days+@DB1_Days,A.NCIF_NPA_Date)<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days+@DB2_Days,A.NCIF_NPA_Date)>@Ext_Date   THEN DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)
									       WHEN  DATEADD(DAY,(@DB1_Days+@SUB_Days+@DB2_Days),A.NCIF_NPA_Date)<=@Ext_Date THEN DATEADD(DAY,(@SUB_Days),A.NCIF_NPA_Date)
									     --  WHEN  DATEADD(DD,1,DATEADD(MONTH,(@DB1_Days+@SUB_Days+@DB2_Days),A.SysNPA_Dt))<=@Ext_Date THEN DATEADD(DD,1,DATEADD(MONTH,(@SUB_Days),A.SysNPA_Dt))
										 --  ELSE DBTDT 
									   END)

FROM NPA_IntegrationDetails_20250509 A 
INNER JOIN DimAssetClass B  ON  A.NCIF_AssetClassAlt_Key =B.AssetClassAlt_Key 
AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
WHERE B.AssetClassShortName NOT IN('STD','LOS')
 AND ISNULL(A.FlgDeg,'N')<>'Y'  AND (ISNULL(A.FlgProcessing,'N')='N')
 AND A.NCIF_NPA_Date IS NOT NULL  AND ISNULL(A.FlgErosion,'N')<>'Y'
 AND  A.EffectiveFromTimeKey=27468 AND A.EffectiveToTimeKey=27468
 And A.SrcSysAlt_Key=@SourceAltKey
*/

 --Select NCIF_AssetClassAlt_Key,NCIF_NPA_Date,DbtDT,AC_AssetClassAlt_Key,AC_NPA_Date,PrincOverdueSinceDt,* from NPA_IntegrationDetails_20250509 where NCIF_Id='69700941'
/* Added on 20052023 at prod for 1 restructure accts and 1 non restructure account  */
-----------------------------------------------------
/* added by satish as on date 03052023 to handle 1 ncif restructure and another non restructe asset downgrade purpse */
			Drop table if exists #NCIF_RestDual
			Select NCIF_Id into #NCIF_RestDual from NPA_IntegrationDetails_20250509 where EffectiveFromTimeKey<=27468 and EffectiveToTimeKey>=27468
			and isnull(IsRestructured,'')='Y' and AC_AssetClassAlt_Key=1
			intersect
			Select NCIF_Id from NPA_IntegrationDetails_20250509 where EffectiveFromTimeKey<=27468 and EffectiveToTimeKey>=27468
			and isnull(IsRestructured,'')='N' and AC_AssetClassAlt_Key<>1

/* 18042023 AMAR -- NPA DATE PERCOLATION AT ENCIF ID LEVEL */
	
			/* FIND MINIMUM NPA DATE AT NCIF IID LEVEL */
			Drop table if exists #Rest_NCIF_Records
			SELECT NI.NCIF_Id, MIN(CASE WHEN NI.NCIF_NPA_Date<=ISNULL(RES.RestructureDt,NCIF_NPA_Date) THEN NCIF_NPA_Date ELSE REs.RestructureDt END) NCIF_NPA_Date--- ???? Acccount related cols to be taken
			into #Rest_NCIF_Records
			FROM NPA_IntegrationDetails_20250509 NI 
				INNER JOIN #NCIF_RestDual NID
					ON NI.NCIF_Id=NID.NCIF_Id
				LEFT JOIN [CurDat].AdvAcRestructureDetail RES 
					ON RES.EffectiveFromTimeKey<=27468 AND RES.EffectiveToTimeKey>=27468 
					AND NI.CustomerId=RES.RefCustomerId
					AND NI.CustomerACID=RES.RefSystemAcId
			WHERE  NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
			GROUP BY NI.NCIF_Id
    	
	/* UPDATE NCIF_NPA_Date */
	UPDATE NI
		SET NI.NCIF_NPA_Date=RES.NCIF_NPA_Date
		,DbtDT=case when DbtDT IS NULL and IBL_ENPA_DB.[dbo].[GetLeapYearDate] (RES.NCIF_NPA_Date,@DB1_Year)<=@Ext_Date 
	                then IBL_ENPA_DB.[dbo].[GetLeapYearDate] (RES.NCIF_NPA_Date,@DB1_Year)
                    when DbtDT IS not null then DbtDT end 
		FROM NPA_IntegrationDetails_20250509 NI
		INNER JOIN #Rest_NCIF_Records RES
		ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
		AND NI.NCIF_Id=RES.NCIF_Id
		INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
WHERE B.AssetClassShortName NOT IN('LOS','WO')
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(NI.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 AND ISNULL(NI.FlgErosion,'N')<>'Y'

/* 18042023 AMAR -- NPA DATE PERCOLATION AT ENCIF ID LEVEL */

	UPDATE NI set
 NCIF_AssetClassAlt_Key=Case when 
        DbtDT is null and IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@Ext_Date then @SubSTD  
	  	   when DbtDT is not null and 
	   IBL_ENPA_DB.[dbo].[GetLeapYearDate] (DbtDT,@DB1_Year) > @Ext_Date then @DB1
       when DbtDT is not null and  
	   IBL_ENPA_DB.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) > @Ext_Date then @DB2
	   when DbtDT is not null and  
	   IBL_ENPA_DB.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) <= @Ext_Date then @DB3 end
	    FROM NPA_IntegrationDetails_20250509 NI
		INNER JOIN #Rest_NCIF_Records RES
		ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
		AND NI.NCIF_Id=RES.NCIF_Id
		INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
WHERE B.AssetClassShortName NOT IN('LOS','WO')
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(NI.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 ---AND ISNULL(NI.FlgErosion,'N')<>'Y' /* as per discussion with ssk records,with erosion will also undergo ageing on the basis of dbt dt */

 
/* END OF NPA DATE PERCOLATION */

----Security Errison
--EXEC [dbo].[SecurityErosion] 27468

------NCIF_ASSETCLASSALT_KEY And NCIF_NPA_DATE IS UPDATED AS NULL BECAUSE FROM  EXTRACTION PROCESS NCIF_ASSETCLASSALT_KEY IS UPDATED AS 0
------Added for With Out WriteOff NCIF_ID---
IF OBJECT_ID('TEMPDB..#NCIF_ID') IS NOT NULL
   DROP TABLE #NCIF_ID

Select distinct A.NCIF_Id 
into #NCIF_ID 
from NPA_IntegrationDetails_20250509 A 
Where EffectiveFromTimeKey<=27468
And EffectiveToTimeKey>=27468
And ISNULL(WriteOffFlag,'N')='Y'
AND A.NCIF_Id NOT IN(SELECT DISTINCT NCIF_Id FROM NPA_IntegrationDetails_20250509 WHERE EffectiveFromTimeKey<=27468 AND EffectiveToTimeKey<=27468 AND IsFraud='Y')
--And ISNULL(WriteOffDate,'1900-01-01')>='2019-04-01'     -----changed on 16-06-2021 for writeoff null
And ISNULL(WriteOffDate,'2019-04-01')>='2019-04-01'     ------Null is handled 2019-04-01
AND AC_Closed_Date IS NULL

------------
	SELECT	 A.NCIF_Id
			,CustomerACID
			,CASE WHEN NCIF_AssetClassAlt_Key IS NULL THEN  AC_AssetClassAlt_Key
			      WHEN IsFraud='Y' THEN @LOS ELSE NCIF_AssetClassAlt_Key END AC_AssetClassAlt_Key
			,CASE WHEN NCIF_NPA_Date IS NULL THEN  AC_NPA_Date ELSE NCIF_NPA_Date END AC_NPA_Date
			,WriteOffFlag				---Added on 05032020 for WriteOff Accounts
			,CAST(NULL AS TINYINT)NEWAC_AssetClassAlt_Key
			, CAST(NULL AS DATE)NEW_AC_NPA_Date
	INTO #NCIF_ASSET
	FROM NPA_IntegrationDetails_20250509 A
	--Inner Join DIMPRODUCT C On C.ProductCode=A.ProductCode   ---------------------Added on 14-06-2021 by Sunil
	--And C.EffectiveFromTimeKey<=27468 AND c.EffectiveToTimeKey>=27468
	WHERE (a.EffectiveFromTimeKey<=27468 AND a.EffectiveToTimeKey>=27468) 
	AND ISNULL(AC_AssetClassAlt_Key,0)<>0
	AND ISNULL(FlgUpg,'N')='N'
	AND AC_Closed_Date IS NULL
	AND Not Exists (Select 1 from #NCIF_ID B Where B.NCIF_Id=A.NCIF_Id)
	AND (CASE WHEN A.IsFraud='Y' THEN 1 ELSE A.AC_AssetClassAlt_Key END )<>7  ----EXCLUDE  WRITE OFF  --------------Added on 14-06-2021
	AND ISNULL(A.ProductCode,'')<>'CX999' -------added on 14-06-2021


	CREATE NONCLUSTERED INDEX NCI_NCIF_ASSET ON #NCIF_ASSET(NCIF_Id)


	--UDPATNG A MAX ASSET CLASS and MIN NPA DATE NCIF WISE
	UPDATE A
	SET NEWAC_AssetClassAlt_Key = B.AC_AssetClassAlt_Key,NEW_AC_NPA_Date = B.AC_NPA_Date
	 FROM #NCIF_ASSET A
	INNER JOIN
	(SELECT NCIF_Id,MAX(AC_AssetClassAlt_Key) AC_AssetClassAlt_Key,MIN(AC_NPA_Date) AC_NPA_Date
	 FROM #NCIF_ASSET
	  GROUP BY NCIF_Id
	)B ON A.NCIF_Id = B.NCIF_Id
	
	
	 UPDATE A
	 SET  NCIF_AssetClassAlt_Key = B.NEWAC_AssetClassAlt_Key
	    , NCIF_NPA_Date = B.NEW_AC_NPA_Date
	 FROM NPA_IntegrationDetails_20250509 A
	 INNER JOIN #NCIF_ASSET B
		ON  (A.EffectiveFromTimeKey <= 27468 AND A.EffectiveToTimeKey >= 27468)
		AND A.NCIF_Id = B.NCIF_Id
		AND A.CustomerACID = B.CustomerACID
	WHERE ISNULL(A.AC_AssetClassAlt_Key,'')<>''           
	AND AC_Closed_Date IS NULL

--------Added FOR Write Off Accounts  

IF OBJECT_ID('TEMPDB..#NCIF_ASSETWriteOff') IS NOT NULL
   DROP TABLE #NCIF_ASSETWriteOff

SELECT	     A.NCIF_Id
			,CustomerACID
			,CASE WHEN NCIF_AssetClassAlt_Key IS NULL THEN  AC_AssetClassAlt_Key ELSE NCIF_AssetClassAlt_Key END AC_AssetClassAlt_Key
			,CASE WHEN NCIF_NPA_Date IS NULL THEN  AC_NPA_Date ELSE NCIF_NPA_Date END AC_NPA_Date
			,WriteOffFlag				---Added on 11032020 for WriteOff Accounts
			,WriteOffDate
			,CAST(NULL AS TINYINT)NEWAC_AssetClassAlt_Key
			, CAST(NULL AS DATE)NEW_AC_NPA_Date
			,AC_AssetClassAlt_Key As AC_AssetClassAlt_Key_WriteOff
	INTO #NCIF_ASSETWriteOff
	FROM NPA_IntegrationDetails_20250509 A
	Inner Join #NCIF_ID B On A.NCIF_Id=B.NCIF_Id
	WHERE (A.EffectiveFromTimeKey<=27468 AND A.EffectiveToTimeKey>=27468) 
	AND (Case When A.AC_AssetClassAlt_Key in (1,2,3,4,5,6) Then 1
			--When  isnull(A.writeoffdate,'1900-01-01')>='2019-04-01' 
			When  isnull(A.writeoffdate,'2019-04-01')>='2019-04-01'    -----handled for Null writeoff Date
			and isnull(A.WriteOffFlag,'N')='Y' then 1 else 0 end)=1
	AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
    AND AC_Closed_Date IS NULL

	Update 	#NCIF_ASSETWriteOff set AC_AssetClassAlt_Key=(Case  
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB.dbo.SysDataMatrix  where TimeKey=27468))between 0 and 365 then @SubSTD
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB.dbo.SysDataMatrix  where TimeKey=27468))between 366 and 730 then @DB1
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB.dbo.SysDataMatrix  where TimeKey=27468))between 731 and 1460 then @DB2
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB.dbo.SysDataMatrix  where TimeKey=27468))between 1461 and 99997 then @DB3
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB.dbo.SysDataMatrix  where TimeKey=27468))=99998 then @LOS
												ELSE AC_AssetClassAlt_Key
												END ) 
	from #NCIF_ASSETWriteOff Where WriteOffFlag='Y'

UPDATE A
	SET NEW_AC_NPA_Date = B.AC_NPA_Date,NEWAC_AssetClassAlt_Key = B.AC_AssetClassAlt_Key
	 FROM #NCIF_ASSETWriteOff A
	INNER JOIN
	(SELECT  NCIF_Id,MIN(ISNULL(AC_NPA_Date,WriteOffDate)) AC_NPA_Date,MAX(AC_AssetClassAlt_Key) AC_AssetClassAlt_Key      ------Changed by Sunil handled in  acnpaddate is null on 21-06-2021
	 FROM #NCIF_ASSETWriteOff
	 GROUP BY NCIF_Id
	)B ON A.NCIF_Id = B.NCIF_Id

Update #NCIF_ASSETWriteOff 
set NEWAC_AssetClassAlt_Key =(Case when AC_AssetClassAlt_Key_WriteOff=7 then AC_AssetClassAlt_Key_WriteOff
								Else NEWAC_AssetClassAlt_Key end)

-------Added on 17-03-2020 if Orginal is greater then original asset class else computed asset class

Update #NCIF_ASSETWriteOff
Set NEWAC_AssetClassAlt_Key=AC_AssetClassAlt_Key_WriteOff where NEWAC_AssetClassAlt_Key<AC_AssetClassAlt_Key_WriteOff
								
--select * 
Update A  
SET A.NCIF_AssetClassAlt_Key = B.NEWAC_AssetClassAlt_Key
  , A.NCIF_NPA_Date = B.NEW_AC_NPA_Date
from NPA_IntegrationDetails_20250509 A
Inner join #NCIF_ASSETWriteOff B ON A.NCIF_Id=B.NCIF_Id
                                And A.CustomerACID=B.CustomerACID
Where A.EffectiveFromTimeKey<=27468
And A.EffectiveToTimeKey>=27468	
AND AC_Closed_Date IS NULL


UPDATE NPA_IntegrationDetails_20250509 SET 
NCIF_AssetClassAlt_Key=AC_AssetClassAlt_Key,
NCIF_NPA_Date=AC_NPA_Date
WHERE EffectiveFromTimeKey<=27468
AND EffectiveToTimeKey>=27468
AND WriteOffFlag='Y'
AND IsFraud<>'Y'
AND isnull(writeoffdate,'2019-04-01')<'2019-04-01'
AND NCIF_AssetClassAlt_Key IS NULL

------------------------------------------------------------- Amar sir, jayadev  - 26112023---ON PROD 20240117
----------------------------------------------------------------COBORROWER DEPLOYMENNT START ON PROD 20240117--
			SET @SourceAltKey=100
			DROP TABLE IF EXISTS #CVDMark
			select NCIF_Id,CustomerACID into #CVDMark from NPA_IntegrationDetails_20250509 A 
				where ( 
						((DPD_StockStmt>180  AND ISNULL(PrincipleOutstanding,0)>0))
						OR (IsFraud='Y')
						OR (IsOTS='Y' )
						--OR (IsARC_Sale='Y' ) --COMMENTED BECAUSE SHOULD NOT IMPACT COBO 20240108
						OR (isnull(DCCO_Date,'2099-12-31')<@Ext_Date AND PROJ_COMPLETION_DATE IS NULL)
						OR ((ISNULL(A.MaxDPD,0)>=91) AND SrcSysAlt_Key=@SourceAltKey)-- COMMENTED BY ZAIN 20231026
						OR (isnull(NatureofClassification,'')='C' AND AC_AssetClassAlt_Key<>1 )--AND DateofImpacting is not null) --20231017 by dev
			  )
			AND EffectiveFromTimeKey<=27468
			AND EffectiveToTimeKey>=27468 
			AND AC_Closed_Date IS NULL
			
/*TO UPDATE NATURE OF CLASSIFICATION AS 'C' FOR THE CASES WHICH WE DEGRADED ON OUR END FORALL SOURCE SYSTEM AS REQUESTED BY BANK --CHANGED BY ZAIN ON 20231221*/
			/* ADDED TO MERGE RECORDS DEGRADED BY D2KAND RECORDS CAMES NPA FROM SOURCE*/


	UPDATE  A SET A.NatureofClassification='C'
	FROM NPA_IntegrationDetails_20250509 A
				where ( 
						((DPD_StockStmt>180  AND ISNULL(PrincipleOutstanding,0)>0))
						OR (IsFraud='Y')
						OR (IsOTS='Y' )
						--OR (IsARC_Sale='Y' ) -- COMMENTED ON 20240107 BY ZAIN 
						OR (isnull(DCCO_Date,'2099-12-31')<@Ext_Date  AND PROJ_COMPLETION_DATE IS NULL)
						OR (IsRestructured='Y' AND A.NCIF_AssetClassAlt_Key<>1  AND AC_AssetClassAlt_Key=1)
						)
						AND ISNULL(A.NATUREOFCLASSIFICATION,'') NOT IN ('C')
						--AND AC_AssetClassAlt_Key = 1 --COMMENTED ON 20240106 BECAUSE IT WAS NOT UPDATING NOC WHERE CLASSIFICATION WAS NPA BUT DUE TO NON FINANCIAL PARAMETER
						--AND NCIF_AssetClassAlt_Key<>1
						AND A.EffectiveFromTimeKey<=27468
						AND A.EffectiveToTimeKey>=27468
						AND AC_Closed_Date IS NULL

			update A set NatureofClassification='C' from NPA_IntegrationDetails_20250509 A
					inner join #CVDMark B on A.NCIF_Id=B.NCIF_Id
					and A.CustomerACID=B.CustomerACID
			where EffectiveFromTimeKey<=27468
					AND EffectiveToTimeKey>=27468 
					and ISNULL(NatureofClassification,'')<>'C'
					AND SrcSysAlt_Key=@SourceAltKey
					AND IsARC_Sale<>'Y' -- ADDED  ON 20240107 BY ZAIN TO EXCLUDE DUE TO ARC ,SHOULD NOT IMPACT COBO

			select A.NCIF_Id,STRING_AGG(CAST(A.CustomerACID AS VARCHAR(MAX)),',') as ImpactingAccount into #CVDMark_Acc
			from NPA_IntegrationDetails_20250509 A
			--inner join #CVDMark B on A.NCIF_Id=B.NCIF_Id
		where EffectiveFromTimeKey<=27468
			AND EffectiveToTimeKey>=27468 
			and NatureofClassification='C'
			and NCIF_AssetClassAlt_Key not in (1,7)
			group by A.NCIF_Id

		update A set NatureofClassification='V' from NPA_IntegrationDetails_20250509 A
			inner join #CVDMark_Acc B on A.NCIF_Id=B.NCIF_Id
		where EffectiveFromTimeKey<=27468
			AND EffectiveToTimeKey>=27468 
			and ISNULL(NatureofClassification,'')=''
			and NCIF_AssetClassAlt_Key not in (1,7)

			update A set ImpactingAccountNo=ImpactingAccount from NPA_IntegrationDetails_20250509 A
			inner join #CVDMark_Acc B on A.NCIF_Id=B.NCIF_Id
		where EffectiveFromTimeKey<=27468
			AND EffectiveToTimeKey>=27468 
			and NatureofClassification='V'
			and NCIF_AssetClassAlt_Key not in (1,7)

/*below code may shifted to the step before acl processing/acl main process */
	/*Amar -- 11102023 -- all close accounts - to be shifted from CoBorrowerData to CoBorrowerData_CloseAcs with Flag Upgrade */
	INSERT INTO [CoBorrowerData_Hist]
		(
			AsOnDate
			,SourceSystemName_PrimaryAccount
			,NCIFID_PrimaryAccount
			,CustomerId_PrimaryAccount
			,CustomerACID_PrimaryAccount
			,NCIFID_COBORROWER
			,AcDegFlg
			,AcDegDate
			,AcUpgFlg
			,AcUpgDate
			,Flag
			,EFFECTIVEFROMTIMEKEY
			,EFFECTIVETOTIMEKEY
		
		)
	SELECT 	AsOnDate
		,SourceSystemName_PrimaryAccount
		,NCIFID_PrimaryAccount
		,CustomerId_PrimaryAccount
		,CustomerACID_PrimaryAccount
		,NCIFID_COBORROWER
		,AcDegFlg
		,AcDegDate
		,AcUpgFlg
		,AcUpgDate
		,'Close'
		,27468
		,27468
	FROM [CoBorrowerData_Curnt] a
		LEFT JOIN NPA_IntegrationDetails_20250509 B
			ON (B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468)
			AND A.CustomerACID_PrimaryAccount=B.CustomerACID
		WHERE B.CustomerACID IS NULL
	/*Amar - 11102023 - Co-Borrower Percolation */

	/*MAINTAINING TOTAL COBO HISTORY  ADDED ON 20231206 BY ZAIN*/
	INSERT INTO [CoBorrowerData_History]
	(
			AsOnDate
			,SourceSystemName_PrimaryAccount
			,NCIFID_PrimaryAccount
			,CustomerId_PrimaryAccount
			,CustomerACID_PrimaryAccount
			,NCIFID_COBORROWER
			,AcDegFlg
			,AcDegDate
			,AcUpgFlg
			,AcUpgDate
			,Flag
			,DATECREATED
			,EFFECTIVEFROMTIMEKEY--ADDED on 20240209
			,EFFECTIVETOTIMEKEY--ADDED on 20240209
		
		)
	SELECT 	AsOnDate
		,SourceSystemName_PrimaryAccount
		,NCIFID_PrimaryAccount
		,CustomerId_PrimaryAccount
		,CustomerACID_PrimaryAccount
		,NCIFID_COBORROWER
		,AcDegFlg
		,AcDegDate
		,AcUpgFlg
		,AcUpgDate
		,Flag
		,GETDATE()
		,EFFECTIVEFROMTIMEKEY
		,EFFECTIVETOTIMEKEY
	FROM [CoBorrowerData_Hist]

	/*Amar -- 11102023 delete closed account from CoBorrowerData table */
	DELETE A
	FROM CoBorrowerData_Curnt a
		LEFT JOIN NPA_IntegrationDetails_20250509 B
			ON (B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468)
			AND A.NCIFID_PrimaryAccount=B.NCIF_Id
			AND A.CustomerACID_PrimaryAccount=B.CustomerACID
		WHERE B.CustomerACID IS NULL
	
/*AMAR-11102023 - GET THE LIST OF ACCOUNT - DEGRADE WITH SELF REEASON EVEN ALREADY NPA  */
	DROP TABLE IF EXISTS #DEGACS
	SET @SourceAltKey =(Select SourceAlt_Key from DimSourceSystem where SourceName='Finacle2')

	SELECT A.CustomerAcID,NCIF_Id
		INTO #DEGACS	
FROM NPA_IntegrationDetails_20250509 A
		WHERE 	(   ((DPD_StockStmt>180  AND ISNULL(PrincipleOutstanding,0)>0))
				OR (IsFraud='Y')
				OR (IsOTS='Y' )
				--OR (IsARC_Sale='Y' )
				OR (isnull(DCCO_Date,'2099-12-31')<@Ext_Date AND PROJ_COMPLETION_DATE IS NULL)
				OR ((ISNULL(A.MaxDPD,0)>=91) AND SrcSysAlt_Key=@SourceAltKey) --COMMENTED BY ZAIN 20231026
				OR (isnull(NatureofClassification,'')='C' AND AC_AssetClassAlt_Key<>1 AND IsARC_Sale<>'Y')--ADDED  'AND AC_AssetClassAlt_Key<>1 ' ON 20231128 BY ZAIN AS OBSERVED BBY JAYDEV
			  )
		AND EffectiveFromTimeKey<=27468
		AND EffectiveToTimeKey>=27468 
		AND AC_Closed_Date IS NULL

		INSERT INTO #DEGACS
		SELECT NI.CustomerACID,NCIF_Id
		FROM NPA_IntegrationDetails_20250509 NI 
			INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=27468 
											 AND NI.EffectiveToTimeKey>=27468 
											 AND RES.EffectiveFromTimeKey<=27468 
											 AND RES.EffectiveToTimeKey>=27468 
											 AND NI.CustomerId=RES.RefCustomerId
											 AND NI.CustomerACID=RES.RefSystemAcId
			WHERE IsRestructured='Y'
				AND ISNULL(RES.RestructureTypeAlt_Key,0) NOT IN (@NaturalCalamity,@DCCO,@Others_COMGT) 
				AND ISNULL(RestructureDt,'1900-01-01')>'2021-12-31'


	/*TO UPDATE NATURE OF CLASSIFICATION AS 'C' FOR THE CASES WHICH WE DEGRADED ON OUR END FORALL SOURCE SYSTEM AS REQUESTED BY BANK --CHANGED BY ZAIN ON 20231221*/
			/* ADDED TO MERGE RECORDS DEGRADED BY D2KAND RECORDS CAMES NPA FROM SOURCE*/
			
	UPDATE  A SET A.NatureofClassification='C'
	FROM NPA_IntegrationDetails_20250509 A
				where ( 
						((DPD_StockStmt>180  AND ISNULL(PrincipleOutstanding,0)>0))
						OR (IsFraud='Y')
						OR (IsOTS='Y' )
						--OR (IsARC_Sale='Y' )
						OR (isnull(DCCO_Date,'2099-12-31')<@Ext_Date AND PROJ_COMPLETION_DATE IS NULL)
						OR (IsRestructured='Y' AND ISNULL(A.NCIF_AssetClassAlt_Key,1)<>1  AND AC_AssetClassAlt_Key=1)
						)
						AND ISNULL(A.NATUREOFCLASSIFICATION,'') NOT IN ('C')
						AND AC_AssetClassAlt_Key = 1
						and NCIF_AssetClassAlt_Key<>1
						AND A.EffectiveFromTimeKey<=27468
						AND A.EffectiveToTimeKey>=27468
						AND AC_Closed_Date IS NULL





	/* AMAR 11102023 - FOR UPDATE DEG FLAG AT ACCOUNT LEVEL- FRESH NPA/EXISTING NPA DUE TO PERCOLATION AND 90 DPD CCORESSED AT PROCESSING DATE/NPA MARKED IN SOURCE SYSTEM*/
	UPDATE A
		SET  A.AcDegFlg='Y'
			,A.AcDegDate=CASE WHEN (isnull(NatureofClassification,'')='C' AND IsRestructured='Y')---CHANGED ON OBSER VATION OF 20231228 BY ZAIN
									THEN NCIF_NPA_Date
								WHEN (isnull(NatureofClassification,'')='C' AND DateofImpacting is not null  and IsRestructured <>'Y')
									THEN DateofImpacting
							ELSE @Ext_Date
							END
			,A.AcUpgFlg='N'
			,A.AcUpgDate=null
	FROM CoBorrowerData_Curnt A
	INNER JOIN NPA_IntegrationDetails_20250509 B
		ON (B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468)
		AND A.NCIFID_PrimaryAccount=B.NCIF_Id
		AND A.CustomerACID_PrimaryAccount=B.CustomerACID
		------AND B.SrcSysAlt_Key=@SourceAltKey
		AND (	------(ISNULL(B.AC_AssetClassAlt_Key,0)=1 And ISNULL(B.NCIF_AssetClassAlt_Key,1)>1 ) /*  FOR FRESH DEGRADE */
			    ------OR (ISNULL(B.MaxDPD,0)>=91 AND ISNULL(B.AC_AssetClassAlt_Key,0)>1) /*---- FOR EXISTING NPA AT NCIF LEVEL 90 DPD COROSSES AT ACCOUNT LEVEL */
			   ---- (isnull(NatureofClassification,'')='C' AND DateofImpacting is not null) /* NPA PARK IN SOURCE SYSTEM */
			   -----OR B.FlgDeg='Y'
			    EXISTS (SELECT CustomerACID FROM #DEGACS D WHERE D.CustomerACID=B.CustomerACID)
			)
		AND ISNULL(A.AcDegFlg,'N')='N' --20231017 by dev

	/* AMAR 1102023 - FIND MAX ASSTE CLASS AND MIN NPA DATE FROM PRIMARY BORROWER FOR UPDATE AT COBORROWER LEVEL  */
		DROP TABLE IF EXISTS #CO_BORR_NCIF

			SELECT NCIFID_COBORROWER,
					 CASE WHEN B.FlgErosion ='Y' THEN NULL 
							ELSE MAX(CASE WHEN NCIF_AssetClassAlt_Key=6 THEN 2  ELSE NCIF_AssetClassAlt_Key END ) END NCIF_AssetClassAlt_Key,----CHANGED ON 20231226 BY ZAIN AS PER OBSERVATION
					 MAX(B.AC_AssetClassAlt_Key)AC_AssetClassAlt_Key,
					
					MIN(case when A.AcDegDate  is NOT null AND B.NatureofClassification='C' THEN  A.AcDegDate 
							  ELSE B.NCIF_NPA_Date  END) NCIF_NPA_Date--ADDED ON 20231226 BY ZAIN AS PER OBSERVATION
					--MIN(CASE WHEN B.NCIF_NPA_Date<A.AcDegDate AND B.NatureofClassification='C' THEN B.NCIF_NPA_Date  ELSE A.AcDegDate END) NCIF_NPA_Date--ADDED ON 20231226 BY ZAIN AS PER OBSERVATION
				INTO #CO_BORR_NCIF
			FROM CoBorrowerData_Curnt A
				INNER JOIN NPA_IntegrationDetails_20250509 B
					ON A.CustomerACID_PrimaryAccount=B.CustomerACID
					AND ( B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468)
				WHERE A.AcDegFlg='Y' 
				--AND AC_AssetClassAlt_Key=1
				and NCIF_AssetClassAlt_Key NOT IN (7)--added by zain on 20240121
				and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
				--AND IsARC_Sale<>'Y' -- ADDED ON 20240108 BY ZAIN
			GROUP BY NCIFID_COBORROWER,B.FlgErosion

	/*FINDING RESTRUCTURED ACCOUNT'S NCIF ID'S NPA DATE  */
	DROP TABLE IF EXISTS #CTE_RESTR_CO_BOR
		SELECT NCIF_Id, MIN(ISNULL(RES.RestructureDt,NCIF_NPA_Date)) NCIF_NPA_Date --ADDED RESTRUCTURE DATE ON 20231226 BY ZAIN AS PER OBSERVATION
			INTO #CTE_RESTR_CO_BOR
		FROM NPA_IntegrationDetails_20250509 NI 
				INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=27468 
						AND NI.EffectiveToTimeKey>=27468 
						AND RES.EffectiveFromTimeKey<=27468 
						AND RES.EffectiveToTimeKey>=27468 
						AND NI.CustomerId=RES.RefCustomerId
						AND NI.CustomerACID=RES.RefSystemAcId
			WHERE IsRestructured='Y'
				GROUP BY NCIF_Id
		
	/*AMAR 11102023 - UPDATE MAIN BORROWER'S ASSETCLASS AND NPA DATE TO CO-BORROWER IN CASE OF LINKE ACCOUNT DEGRADE BY D2K OR IN SOURCE SYSTEM */
	/* UPDATING ASSET CLASS AND NPA DATE FOR CO-BORROWER WITH COMPARING RESTRICTUREED ACCOUNT NPA DATE */
	UPDATE A
		SET A.NCIF_AssetClassAlt_Key= CASE WHEN B.NCIF_AssetClassAlt_Key = 6 THEN 2 ELSE B.NCIF_AssetClassAlt_Key END--20240121 OBSRVATION
			,A.NCIF_NPA_Date=CASE WHEN C.NCIF_ID IS NOT NULL AND C.NCIF_NPA_Date<ISNULL(B.NCIF_NPA_Date,CONVERT(DATE,@Ext_Date,103)) --CHANGED BY ZAIN 20231027
										THEN C.NCIF_NPA_Date 
									ELSE ISNULL(B.NCIF_NPA_Date,CONVERT(DATE,@Ext_Date,103))--CHANGED BY ZAIN 20231027
								END
	 FROM NPA_IntegrationDetails_20250509 A
		INNER JOIN #CO_BORR_NCIF B--changed 20231017 by zain
			ON A.NCIF_Id=B.NCIFID_COBORROWER
			AND A.EffectiveFromTimeKey<=27468 
			AND A.EffectiveToTimeKey>=27468 
		LEFT JOIN #CTE_RESTR_CO_BOR C
			ON C.NCIF_Id=A.NCIF_Id
		WHERE isnull(A.NCIF_AssetClassAlt_Key,1)=1-- 20231017 by dev
		

		UPDATE NI set
				NCIF_AssetClassAlt_Key=Case when DbtDT is null and IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@Ext_Date
												then @SubSTD  
	  										when DbtDT is not null and IBL_ENPA_DB.[dbo].[GetLeapYearDate] (DbtDT,@DB1_Year) > @Ext_Date
												then @DB1
											when DbtDT is not null and  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) > @Ext_Date
												then @DB2
											when DbtDT is not null and IBL_ENPA_DB.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) <= @Ext_Date
												then @DB3 
												else NI.NCIF_AssetClassAlt_Key
												end
				FROM NPA_IntegrationDetails_20250509 NI
					INNER JOIN #CTE_RESTR_CO_BOR RES
						ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
					AND NI.NCIF_Id=RES.NCIF_Id
						INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
								ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key 
									Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
						AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
				WHERE B.AssetClassShortName NOT IN('LOS','WO')
					AND (ISNULL(NI.FlgProcessing,'N')='N')


				--			UPDATE NI set
				--NCIF_AssetClassAlt_Key=Case when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@Ext_Date
				--								then @SubSTD  
	  	--									when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@DB1_Year+@SUB_Year) > @Ext_Date
				--								then @DB1
				--							when IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) > @Ext_Date
				--								then @DB2
				--							when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) <= @Ext_Date
				--								then @DB3 
				--								else NI.NCIF_AssetClassAlt_Key
				--								end
				--FROM NPA_IntegrationDetails_20250509 NI
				--	INNER JOIN #CO_BORR_NCIF RES
				--		ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
				--	AND NI.NCIF_Id=RES.NCIFID_COBORROWER
				--		INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
				--				ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key 
				--					Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
				--		AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
				--WHERE B.AssetClassShortName NOT IN('LOS','WO')
				--	AND (ISNULL(NI.FlgProcessing,'N')='N')
				--	AND NI.DBTDT IS NULL

	UPDATE NI set
				NCIF_AssetClassAlt_Key=Case when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@EXT_DATE
												then 2  
	  										when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@DB1_Year+@SUB_Year) > @EXT_DATE
												then 3
											when IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) > @EXT_DATE
												then 4
											when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) <= @EXT_DATE
												then 5
												else NI.NCIF_AssetClassAlt_Key
												end
				FROM NPA_IntegrationDetails_20250509 NI
					INNER JOIN #CO_BORR_NCIF RES
						ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
					AND NI.NCIF_Id=RES.NCIFID_COBORROWER
						INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
								ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key 
									Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
						AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
				WHERE B.AssetClassShortName NOT IN('LOS','WO')
					AND (ISNULL(NI.FlgProcessing,'N')='N')
					AND NI.DbtDT IS NULL

					
	UPDATE NI set
				NCIF_AssetClassAlt_Key=Case when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@EXT_DATE
												then 2  
	  										when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.DbtDT,@DB1_Year) > @EXT_DATE
												then 3
											when IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.DbtDT,(@DB1_Year+@DB2_Year)) > @EXT_DATE
												then 4
											when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.DbtDT,(@DB1_Year+@DB2_Year)) <= @EXT_DATE
												then 5
												else NI.NCIF_AssetClassAlt_Key
												end
				FROM NPA_IntegrationDetails_20250509 NI
					INNER JOIN #CO_BORR_NCIF RES
						ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
					AND NI.NCIF_Id=RES.NCIFID_COBORROWER
						INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
								ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key 
									Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
						AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
				WHERE B.AssetClassShortName NOT IN('LOS','WO')
					AND (ISNULL(NI.FlgProcessing,'N')='N')
					AND NI.DbtDT IS NOT NULL
					AND DATEDIFF(MONTH,NI.NCIF_NPA_DATE,NI.DBTDT)<=12
					

	UPDATE NI set
				NCIF_AssetClassAlt_Key=Case when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@EXT_DATE
												then 2  
	  										when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@DB1_Year+@SUB_Year) > @EXT_DATE
												then 3
											when IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) > @EXT_DATE
												then 4
											when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) <= @EXT_DATE
												then 5
												else NI.NCIF_AssetClassAlt_Key
												end
				FROM NPA_IntegrationDetails_20250509 NI
					INNER JOIN #CO_BORR_NCIF RES
						ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
					AND NI.NCIF_Id=RES.NCIFID_COBORROWER
						INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
								ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key 
									Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
						AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
				WHERE B.AssetClassShortName NOT IN('LOS','WO')
					AND (ISNULL(NI.FlgProcessing,'N')='N')
					AND NI.DbtDT IS NOT NULL
					AND DATEDIFF(MONTH,NI.NCIF_NPA_DATE,NI.DBTDT)>12
					
/*C,V,D FLAG MARKING FOR CO-BORROWER ADDED BY ZAIN 20231019 ON LOCAL*/
--DROP TABLE IF EXISTS #DEGACS
--SELECT DISTINCT NCIF_Id,A.CustomerAcID
--		INTO #DEGACS		
--	FROM NPA_IntegrationDetails_20250509 A 
--		WHERE (	   ((DPD_StockStmt>180  AND ISNULL(PrincipleOutstanding,0)>0))
--				OR (IsFraud='Y')
--				OR (IsOTS='Y' )
--				OR (IsARC_Sale='Y' )
--				OR (ISNULL(DCCO_Date,'1900-01-01')<CAST(GETDATE() AS DATE) AND PROJ_COMPLETION_DATE IS NULL)
--				OR (ISNULL(A.MaxDPD,0)>=91)-- AND SrcSysAlt_Key=@SourceAltKey)
--			  )
--		AND EffectiveFromTimeKey<=27468 
--		AND EffectiveToTimeKey>=27468 
--		AND AC_Closed_Date IS NULL
--GROUP BY  NCIF_Id,A.CustomerAcID

--SELECT * FROM CoBorrowerData_Curnt
DROP TABLE IF EXISTS #COBORROWER_IMPACTINGACCOUNTS_PRE
	SELECT DISTINCT A.NCIFID_COBORROWER,B.SrcSysAlt_Key,b.CUSTOMERACID,A.CustomerACID_PrimaryAccount
	INTO #COBORROWER_IMPACTINGACCOUNTS_PRE
	 FROM [CoBorrowerData_Curnt] A INNER JOIN NPA_IntegrationDetails_20250509 B
		ON A.NCIFID_COBORROWER=B.NCIF_ID
		AND B.EffectiveFromTimeKey=27468 AND B.EffectiveToTimeKey=27468
 		INNER JOIN #DEGACS C ON (C.NCIF_Id=A.NCIFID_COBORROWER)
 		AND C.CustomerACID=B.CustomerACID
		and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
		GROUP BY A.NCIFID_COBORROWER,B.SrcSysAlt_Key,b.CUSTOMERACID,A.CustomerACID_PrimaryAccount

		union all
		
		SELECT DISTINCT A.NCIFID_COBORROWER,B.SrcSysAlt_Key,b.CUSTOMERACID,A.CustomerACID_PrimaryAccount
	 FROM [CoBorrowerData_Curnt] A INNER JOIN NPA_IntegrationDetails_20250509 B
		ON A.NCIFID_COBORROWER=B.NCIF_ID
		AND B.EffectiveFromTimeKey=27468 AND B.EffectiveToTimeKey=27468
 		INNER JOIN #DEGACS C ON 
		C.NCIF_Id=A.NCIFID_PrimaryAccount
 		AND C.CustomerACID=A.CustomerACID_PrimaryAccount
		and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
		GROUP BY A.NCIFID_COBORROWER,B.SrcSysAlt_Key,b.CUSTOMERACID,A.CustomerACID_PrimaryAccount


/* IMPLEMENTATION FOR NON COBO RELATION MARKINGS */
DROP TABLE IF EXISTS #COBORROWER_IMPACTINGACCOUNTS_PRE_NOCOBO
	SELECT DISTINCT B.NCIF_ID NCIFID_COBORROWER,B.SrcSysAlt_Key,b.CUSTOMERACID,A.CustomerACID_PrimaryAccount
	INTO #COBORROWER_IMPACTINGACCOUNTS_PRE_NOCOBO
	 FROM [CoBorrowerData_Curnt] A RIGHT JOIN NPA_IntegrationDetails_20250509 B
		ON A.NCIFID_PRIMARYACCOUNT=B.NCIF_ID
		AND B.NCIF_ID IS NULL
		AND B.EffectiveFromTimeKey=27468 AND B.EffectiveToTimeKey=27468
		WHERE B.NCIF_ID IN (SELECT NCIF_Id FROM #DEGACS )

 		--AND C.CustomerACID=B.CustomerACID
		GROUP BY B.NCIF_ID,B.SrcSysAlt_Key,b.CUSTOMERACID,A.CustomerACID_PrimaryAccount
--ALTER TABLE [CoBorrowerData_Curnt] ALTER COLUMN CustomerACID_PrimaryAccount VARCHAR(4000) BHOLA

		--SELECT * FROM #COBORROWER_IMPACTINGACCOUNTS_PRE
		--SELECT * FROM #COBORROWER_IMPACTINGACCOUNTS_PRE_NOCOBO 

DROP TABLE IF EXISTS #COBORROWER_IMPACTINGACCOUNTS
;WITH CTE AS(
SELECT DISTINCT ROW_NUMBER() OVER(PARTITION BY A.CUSTOMERACID_COBORROWER ORDER BY A.CUSTOMERACID_COBORROWER)RN
,A.NCIFID_COBORROWER,A.SrcSysAlt_Key,A.CUSTOMERACID_COBORROWER,B.CustomerACID_PrimaryAccount   FROM (
 SELECT A.NCIFID_COBORROWER,A.SourceName SrcSysAlt_Key
 ,STRING_AGG(CAST(A.CUSTOMERACID AS VARCHAR(MAX)),',') CUSTOMERACID_COBORROWER 
 --,B.CustomerACID_PrimaryAccount
 FROM
 --INTO #COBORROWER_IMPACTINGACCOUNTS_PRE1
 (SELECT DISTINCT NCIFID_COBORROWER ,SourceName,CUSTOMERACID FROM #COBORROWER_IMPACTINGACCOUNTS_PRE A 
 INNER JOIN DIMSOURCESYSTEM D ON D.SourceAlt_Key=A.SrcSysAlt_Key
 and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
 		GROUP BY NCIFID_COBORROWER,SourceName,CUSTOMERACID
		)A 
		where A.NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
		GROUP BY A.NCIFID_COBORROWER,A.SourceName)A
		INNER JOIN 
(SELECT A.NCIFID_COBORROWER,A.SourceName SrcSysAlt_Key
 ,STRING_AGG(CAST(A.CustomerACID_PrimaryAccount AS VARCHAR(MAX)),',') CustomerACID_PrimaryAccount
 --,B.CustomerACID_PrimaryAccount
 FROM
 --INTO #COBORROWER_IMPACTINGACCOUNTS_PRE1
 (SELECT DISTINCT NCIFID_COBORROWER ,SourceName,CustomerACID_PrimaryAccount FROM #COBORROWER_IMPACTINGACCOUNTS_PRE A 
 INNER JOIN DIMSOURCESYSTEM D ON D.SourceAlt_Key=A.SrcSysAlt_Key
 and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
 		GROUP BY NCIFID_COBORROWER,SourceName,CustomerACID_PrimaryAccount
		)A 
		where A.NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
		GROUP BY A.NCIFID_COBORROWER,A.SourceName)B
		ON A.NCIFID_COBORROWER=B.NCIFID_COBORROWER
	), CTE2 AS
	(SELECT DISTINCT ROW_NUMBER() OVER(PARTITION BY CustomerACID_PrimaryAccount ORDER BY CustomerACID_PrimaryAccount)RN
	,NCIFID_COBORROWER,STRING_AGG(SrcSysAlt_Key,',')SrcSysAlt_Key,STRING_AGG(CAST(CUSTOMERACID_COBORROWER AS VARCHAR(MAX)),',')CUSTOMERACID_COBORROWER,CustomerACID_PrimaryAccount
	FROM CTE WHERE RN=1
	and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
	GROUP BY NCIFID_COBORROWER,CustomerACID_PrimaryAccount
	)SELECT NCIFID_COBORROWER,SrcSysAlt_Key,CUSTOMERACID_COBORROWER,CustomerACID_PrimaryAccount
	INTO #COBORROWER_IMPACTINGACCOUNTS FROM CTE2 ORDER BY 1,3,4

DROP TABLE IF EXISTS #COBORROWER_IMPACTINGACCOUNTS_NOCOBO
;WITH CTE AS(
SELECT DISTINCT ROW_NUMBER() OVER(PARTITION BY A.CUSTOMERACID_COBORROWER ORDER BY A.CUSTOMERACID_COBORROWER)RN
,A.NCIFID_COBORROWER,A.SrcSysAlt_Key,A.CUSTOMERACID_COBORROWER,B.CustomerACID_PrimaryAccount   FROM (
 SELECT A.NCIFID_COBORROWER,A.SourceName SrcSysAlt_Key
 ,STRING_AGG(CAST(A.CUSTOMERACID AS VARCHAR(MAX)),',') CUSTOMERACID_COBORROWER 
 --,B.CustomerACID_PrimaryAccount
 FROM
 --INTO #COBORROWER_IMPACTINGACCOUNTS_PRE1
 (SELECT DISTINCT NCIFID_COBORROWER ,SourceName,CUSTOMERACID FROM #COBORROWER_IMPACTINGACCOUNTS_PRE_NOCOBO A 
 INNER JOIN DIMSOURCESYSTEM D ON D.SourceAlt_Key=A.SrcSysAlt_Key
 and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
 		GROUP BY NCIFID_COBORROWER,SourceName,CUSTOMERACID
		)A 
		where A.NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
		GROUP BY A.NCIFID_COBORROWER,A.SourceName)A
		INNER JOIN 
(SELECT A.NCIFID_COBORROWER,A.SourceName SrcSysAlt_Key
 ,STRING_AGG(CAST(A.CustomerACID_PrimaryAccount AS VARCHAR(MAX)),',') CustomerACID_PrimaryAccount
 --,B.CustomerACID_PrimaryAccount
 FROM
 --INTO #COBORROWER_IMPACTINGACCOUNTS_PRE1
 (SELECT DISTINCT NCIFID_COBORROWER ,SourceName,CustomerACID_PrimaryAccount FROM #COBORROWER_IMPACTINGACCOUNTS_PRE_NOCOBO A 
 INNER JOIN DIMSOURCESYSTEM D ON D.SourceAlt_Key=A.SrcSysAlt_Key
 and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
 		GROUP BY NCIFID_COBORROWER,SourceName,CustomerACID_PrimaryAccount
		)A 
		where A.NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
		GROUP BY A.NCIFID_COBORROWER,A.SourceName)B
		ON A.NCIFID_COBORROWER=B.NCIFID_COBORROWER
	), CTE2 AS
	(SELECT DISTINCT ROW_NUMBER() OVER(PARTITION BY CustomerACID_PrimaryAccount ORDER BY CustomerACID_PrimaryAccount)RN
	,NCIFID_COBORROWER,STRING_AGG(SrcSysAlt_Key,',')SrcSysAlt_Key,STRING_AGG(CAST(CUSTOMERACID_COBORROWER AS VARCHAR(MAX)),',')CUSTOMERACID_COBORROWER,CustomerACID_PrimaryAccount
	FROM CTE WHERE RN=1
	and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
	GROUP BY NCIFID_COBORROWER,CustomerACID_PrimaryAccount
	)SELECT NCIFID_COBORROWER,SrcSysAlt_Key,CUSTOMERACID_COBORROWER,CustomerACID_PrimaryAccount
	INTO #COBORROWER_IMPACTINGACCOUNTS_NOCOBO FROM CTE2 ORDER BY 1,3,4


--		SELECT * FROM #COBORROWER_IMPACTINGACCOUNTS
--		SELECT * FROM #COBORROWER_IMPACTINGACCOUNTS_NOCOBO ORDER BY 1


DROP TABLE IF EXISTS #COBORROWER_IMPACTINGACCOUNTS_FINAL
SELECT A.*,B.NCIFID_PrimaryAccount 
	INTO #COBORROWER_IMPACTINGACCOUNTS_FINAL
	FROM #COBORROWER_IMPACTINGACCOUNTS A INNER JOIN CoBorrowerData_Curnt B
		ON A.NCIFID_COBORROWER=B.NCIFID_COBORROWER
		and A.NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
	GROUP BY A.NCIFID_COBORROWER,A.SrcSysAlt_Key,A.CUSTOMERACID_COBORROWER,A.CustomerACID_PrimaryAccount,b.NCIFID_PrimaryAccount

	DROP TABLE IF EXISTS #COBORROWER_IMPACTINGACCOUNTS_FINAL_NOCOBO
SELECT A.NCIFID_COBORROWER,A.SrcSysAlt_Key,A.CustomerACID_PrimaryAccount,B.NCIF_ID NCIFID_PrimaryAccount 
	INTO #COBORROWER_IMPACTINGACCOUNTS_FINAL_NOCOBO
	FROM #COBORROWER_IMPACTINGACCOUNTS_NOCOBO A INNER JOIN NPA_IntegrationDetails_20250509 B
		ON A.NCIFID_COBORROWER=B.NCIF_ID
		and A.NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
		AND B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468--20240121
	GROUP BY A.NCIFID_COBORROWER,A.SrcSysAlt_Key,A.CustomerACID_PrimaryAccount,b.NCIF_ID

/*TO DEGRADE HANDLE CO-BORROWER OF A PRIMARY BORROWER WHERE PRIMARY BORROWER IS WRITE-OFF added on 20231206*/ 

		DROP TABLE IF EXISTS #WRITEOFF_PRIM_COBO_DEG 
			SELECT A.NCIF_Id,A.CustomerACID,B.NCIFID_COBORROWER,A.NCIF_AssetClassAlt_Key,A.AC_NPA_Date INTO  #WRITEOFF_PRIM_COBO_DEG 
					FROM NPA_IntegrationDetails_20250509 A INNER JOIN CoBorrowerData_Curnt B ON A.CUSTOMERACID=B.CustomerACID_PrimaryAccount
					WHERE   (A.NCIF_AssetClassAlt_Key IN (7) OR WriteOffFlag='Y') --CHANGED BY ZAIN DUE TO OBSERVATION 20231211/ADDED WRITEOFFFLG LOGIC ON 20231216
						AND A.IsARC_Sale<>'Y' --CHANGED BY ZAIN DUE TO OBSERVATION 20240108/ADDED WRITEOFFFLG LOGIC BUT SHOULDNOT BE ARC TO SALE ON 20231216
						AND A.EffectiveFromTimeKey<=27468 AND A.EffectiveToTimeKey>=27468

		UPDATE A SET A.NCIF_AssetClassAlt_Key=2,
					A.NCIF_NPA_Date=B.AC_NPA_Date,--@Ext_Date,CHANGE BY ZAIN ON 20231225 AS PER OBSERVATION
					A.FlgDeg='Y',
					A.NATUREOFCLASSIFICATION='D',---ADDED DUE TO OBSERVATION OF WRONG FLAG MARKING .BY ZAIN ON 20231218
				A.DegReason = 'DEGRADE DUE TO PRIMARY BORROWER ACCOUNT WO'
		FROM NPA_IntegrationDetails_20250509 A INNER JOIN #WRITEOFF_PRIM_COBO_DEG B ON A.NCIF_ID=B.NCIFID_COBORROWER
		WHERE ISNULL(A.NCIF_AssetClassAlt_Key,1)=1 
			AND A.EffectiveFromTimeKey<=27468 
			AND A.EffectiveToTimeKey>=27468 

		


	/*AGING FOR WO DRAGGED CASES 20240108*/
	
		UPDATE NI set
				NCIF_AssetClassAlt_Key=Case when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@EXT_DATE
												then 2  
	  										when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@DB1_Year+@SUB_Year) > @EXT_DATE
												then 3
											when IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) > @EXT_DATE
												then 4
											when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) <= @EXT_DATE
												then 5
												else NI.NCIF_AssetClassAlt_Key
												end
				FROM NPA_IntegrationDetails_20250509 NI
					INNER JOIN #WRITEOFF_PRIM_COBO_DEG  RES
						ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
					AND NI.NCIF_Id=RES.NCIFID_COBORROWER
						INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
								ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key 
									Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
						AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
				WHERE B.AssetClassShortName NOT IN('LOS','WO')
					AND (ISNULL(NI.FlgProcessing,'N')='N')
					AND NI.DbtDT IS NULL
					AND NI.DegReason LIKE 'DEGRADE DUE TO PRIMARY BORROWER ACCOUNT WO'
					AND NI.EffectiveFromTimeKey<=27468 
					AND NI.EffectiveToTimeKey>=27468 

					
	UPDATE NI set
				NCIF_AssetClassAlt_Key=Case when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@EXT_DATE
												then 2  
	  										when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.DbtDT,@DB1_Year) > @EXT_DATE
												then 3
											when IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.DbtDT,(@DB1_Year+@DB2_Year)) > @EXT_DATE
												then 4
											when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.DbtDT,(@DB1_Year+@DB2_Year)) <= @EXT_DATE
												then 5
												else NI.NCIF_AssetClassAlt_Key
												end
				FROM NPA_IntegrationDetails_20250509 NI
					INNER JOIN #WRITEOFF_PRIM_COBO_DEG  RES
						ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
					AND NI.NCIF_Id=RES.NCIFID_COBORROWER
						INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
								ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key 
									Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
						AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
				WHERE B.AssetClassShortName NOT IN('LOS','WO')
					AND (ISNULL(NI.FlgProcessing,'N')='N')
					AND NI.DbtDT IS NOT NULL
					AND DATEDIFF(MONTH,NI.NCIF_NPA_DATE,NI.DBTDT)<=12
					AND NI.DegReason LIKE 'DEGRADE DUE TO PRIMARY BORROWER ACCOUNT WO'
					AND NI.EffectiveFromTimeKey<=27468 
					AND NI.EffectiveToTimeKey>=27468 


	UPDATE NI set
				NCIF_AssetClassAlt_Key=Case when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@EXT_DATE
												then 2  
	  										when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@DB1_Year+@SUB_Year) > @EXT_DATE
												then 3
											when IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) > @EXT_DATE
												then 4
											when  IBL_ENPA_DB.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,(@DB1_Year+@DB2_Year+@SUB_Year)) <= @EXT_DATE
												then 5
												else NI.NCIF_AssetClassAlt_Key
												end
				FROM NPA_IntegrationDetails_20250509 NI
					INNER JOIN #WRITEOFF_PRIM_COBO_DEG  RES
						ON NI.EffectiveFromTimeKey<=27468 AND NI.EffectiveToTimeKey>=27468 
					AND NI.NCIF_Id=RES.NCIFID_COBORROWER
						INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
								ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key 
									Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
						AND  B.EffectiveFromTimeKey<=27468 AND B.EffectiveToTimeKey>=27468
				WHERE B.AssetClassShortName NOT IN('LOS','WO')
					AND (ISNULL(NI.FlgProcessing,'N')='N')
					AND NI.DbtDT IS NOT NULL
					AND DATEDIFF(MONTH,NI.NCIF_NPA_DATE,NI.DBTDT)>12
					AND NI.DegReason LIKE 'DEGRADE DUE TO PRIMARY BORROWER ACCOUNT WO'
					AND NI.EffectiveFromTimeKey<=27468 
					AND NI.EffectiveToTimeKey>=27468 

------------------------------------------END OF WO COBO DRAG AGING------------------------------------
/*FOR PRIMARY CAUSED*/
UPDATE A SET A.NatureofClassification='C'
			,ImpactingSourceSystemName=B.SrcSysAlt_Key
			,A.ImpactingAccountNo=COALESCE(B.CUSTOMERACID_PRIMARYACCOUNT,A.CUSTOMERACID)
			,A.DateofImpacting=@Ext_Date
FROM NPA_IntegrationDetails_20250509 A INNER JOIN #COBORROWER_IMPACTINGACCOUNTS_FINAL B ON A.NCIF_ID=B.NCIFID_PrimaryAccount
														--AND A.CUSTOMERACID = B.CUSTOMERACID_COBORROWER
								INNER JOIN  #DEGACS D ON D.NCIF_ID=A.NCIF_ID
											AND A.CustomerACID=D.CustomerACID--ADDED ON 20231110 BY ZAIN
AND EffectiveFromTimeKey=27468 AND EffectiveToTimeKey=27468
WHERE A.CustomerACID IN (SELECT CustomerACID_PrimaryAccount FROM [CoBorrowerData_Curnt] ) 
AND A.NCIF_AssetClassAlt_Key not in		(1)
AND A.SrcSysAlt_Key=100--UPDATING ONLY FOR FINACLE-2 ACCOUNTS ADDED BY ZAIN ON 20231208



/* UPDATING ''C' FOR NON COBO RELATION IN MAIN TABLE*/
UPDATE A SET A.NatureofClassification='C'
			,ImpactingSourceSystemName=B.SrcSysAlt_Key
			,A.ImpactingAccountNo=COALESCE(B.CUSTOMERACID_PRIMARYACCOUNT,A.CUSTOMERACID)
			,A.DateofImpacting=@Ext_Date
 FROM NPA_IntegrationDetails_20250509 A INNER JOIN #COBORROWER_IMPACTINGACCOUNTS_FINAL_NOCOBO B ON A.NCIF_ID=B.NCIFID_PrimaryAccount
														--AND A.CUSTOMERACID = B.CUSTOMERACID_COBORROWER
								INNER JOIN  #DEGACS D ON D.NCIF_ID=A.NCIF_ID
								AND A.CustomerACID=D.CustomerACID--ADDED ON 20231110 BY ZAIN
								AND D.CUSTOMERACID IN (SELECT VALUE FROM string_split( B.CustomerACID_PrimaryAccount,',') WHERE RTRIM(VALUE)<>'')
AND EffectiveFromTimeKey=27468 AND EffectiveToTimeKey=27468
AND A.NCIF_AssetClassAlt_Key not in (1)
AND A.SrcSysAlt_Key=100--UPDATING ONLY FOR FINACLE-2 ACCOUNTS ADDED BY ZAIN ON 20231208
--AND A.NatureofClassification is null
--SELECT * FROM #COBORROWER_IMPACTINGACCOUNTS_FINAL_NOCOBO


/*FOR COBO DRAG*/
UPDATE A SET A.NatureofClassification='D'
			,ImpactingSourceSystemName=B.SrcSysAlt_Key
			,A.ImpactingAccountNo=B.CustomerACID_PrimaryAccount
			,A.DateofImpacting=@Ext_Date
FROM NPA_IntegrationDetails_20250509 A INNER JOIN #COBORROWER_IMPACTINGACCOUNTS_FINAL B 
										ON A.NCIF_ID=B.NCIFID_COBORROWER
										AND A.CUSTOMERACID <> B.CUSTOMERACID_COBORROWER
								--INNER JOIN #COBORROWER_IMPACTINGSRCALTKEY_FINAL C ON A.NCIF_ID=C.NCIFID_COBORROWER
								INNER JOIN  #DEGACS D ON D.NCIF_ID=A.NCIF_ID
								AND A.CustomerACID=D.CustomerACID--ADDED ON 20231110 BY ZAIN
AND EffectiveFromTimeKey=27468 AND EffectiveToTimeKey=27468
WHERE A.CustomerACID NOT IN (SELECT CustomerACID_PrimaryAccount FROM [CoBorrowerData_Curnt] )
AND isnull(A.NatureofClassification,'')='' --ADDED 0N 20231031 FOR AN OBSERVARTION
AND A.NCIF_AssetClassAlt_Key not in (1)


/*FOR PRIMARY DRAG*/

;WITH CTE_COBOR_NCIF
AS(
	SELECT NCIFID_COBORROWER,C.SourceName SOURCESYSTEMNAME_COBORROWER,CustomerACID_PrimaryAccount
	FROM NPA_IntegrationDetails_20250509 A 
	 INNER JOIN #COBORROWER_IMPACTINGACCOUNTS_FINAL B 
	ON A.NCIF_ID=B.NCIFID_PrimaryAccount
	INNER JOIN DimSourceSystem C ON SourceAlt_Key=A.SrcSysAlt_Key
	AND A.EffectiveFromTimeKey<=27468 AND A.EffectiveToTimeKey>=27468
	WHERE A.NatureofClassification IN ('C')
	and NCIFID_COBORROWER is not null --- added by zain and vinit 20231210
	GROUP BY NCIFID_COBORROWER,SourceName,CustomerACID_PrimaryAccount
)
UPDATE A SET A.NatureofClassification='D'
			,ImpactingSourceSystemName=B.SOURCESYSTEMNAME_COBORROWER
			,A.ImpactingAccountNo=B.CustomerACID_PrimaryAccount
			,A.DateofImpacting=@Ext_Date
--SELECT DISTINCT A.NCIF_ID,A.NatureofClassification,B.NCIFID_COBORROWER
--,B.NCIFID_PrimaryAccount 
FROM NPA_IntegrationDetails_20250509 A INNER JOIN CTE_COBOR_NCIF B 
										ON A.NCIF_ID=B.NCIFID_COBORROWER
										AND A.EffectiveFromTimeKey<=27468 AND A.EffectiveToTimeKey>=27468
										--AND ISNULL(A.NatureofClassification,'')<>'C'
										AND ISNULL(A.NatureofClassification,'') =''
										AND A.NCIF_AssetClassAlt_Key not in (1)
										AND ISNULL(A.NatureofClassification,'') =''--ADDED ON 20231221AS OBSERVATION OF MARKING WRONG ACCOUNTS IN IMPACTING ACCOUNT NUMBER
										
/*FOR COBO VICTIM*/
UPDATE A SET A.NatureofClassification='V'
			,ImpactingSourceSystemName=B.SrcSysAlt_Key
			,A.ImpactingAccountNo=case when A.ImpactingAccountNo is null then B.CustomerACID_PrimaryAccount else A.ImpactingAccountNo end
			,A.DateofImpacting=@Ext_Date
 --SELECT ImpactingAccountNo,A.CustomerACID,B.NCIFID_COBORROWER,B.NCIFID_PrimaryAccount,A.NCIF_ID,A.* 
FROM NPA_IntegrationDetails_20250509 A INNER JOIN #COBORROWER_IMPACTINGACCOUNTS_FINAL B 
																	ON A.NCIF_ID=B.NCIFID_COBORROWER
																	AND B.NCIFID_COBORROWER IS NOT NULL
								--INNER JOIN #COBORROWER_IMPACTINGSRCALTKEY_FINAL C ON A.NCIF_ID=C.NCIFID_COBORROWER
								INNER JOIN  #DEGACS D ON D.NCIF_ID=A.NCIF_ID
								AND A.CustomerACID=D.CustomerACID--ADDED ON 20231110 BY ZAIN
AND EffectiveFromTimeKey=27468 AND EffectiveToTimeKey=27468
--WHERE A.NatureofClassificatioN NOT IN ('C','D')
where ISNULL(A.NatureofClassification,'') =''
AND A.NCIF_AssetClassAlt_Key not in (1)

/*FOR PRIMARY VICTIM*/
UPDATE A SET A.NatureofClassification='V'
			,ImpactingSourceSystemName=B.SrcSysAlt_Key
			,A.ImpactingAccountNo=case when A.ImpactingAccountNo is null then B.CustomerACID_PrimaryAccount else A.ImpactingAccountNo end
			,A.DateofImpacting=@Ext_Date
 --SELECT ImpactingAccountNo,A.CustomerACID,B.NCIFID_COBORROWER,B.NCIFID_PrimaryAccount,A.NCIF_ID,A.* 
FROM NPA_IntegrationDetails_20250509 A INNER JOIN #COBORROWER_IMPACTINGACCOUNTS_FINAL B 
													ON A.NCIF_ID=B.NCIFID_PrimaryAccount
							INNER JOIN  #DEGACS D ON D.NCIF_ID=A.NCIF_ID--ADDED ON 20231110 BY ZAIN
													AND A.CustomerACID<>D.CustomerACID--ADDED ON 20231110 BY ZAIN
													AND A.NatureofClassification NOT IN ('C','D')
AND EffectiveFromTimeKey=27468 AND EffectiveToTimeKey=27468
--WHERE A.NatureofClassificatioN NOT IN ('C','D')
where ISNULL(A.NatureofClassification,'') =''
AND A.NCIF_AssetClassAlt_Key not in (1)

/* UPDATING 'V' FOR NON COBO RELATION IN MAIN TABLE*/
UPDATE A SET A.NatureofClassification='V'
			,ImpactingSourceSystemName=B.SrcSysAlt_Key
			,A.ImpactingAccountNo =case when A.ImpactingAccountNo is null then B.CustomerACID_PrimaryAccount else A.ImpactingAccountNo end
			,A.DateofImpacting=@Ext_Date
 --SELECT B.CustomerACID_PrimaryAccount,B.SrcSysAlt_Key,A.NCIF_ID,A.CUSTOMERACID,A.NatureofClassification 
FROM NPA_IntegrationDetails_20250509 A INNER JOIN #COBORROWER_IMPACTINGACCOUNTS_FINAL_NOCOBO B 
																	ON A.NCIF_ID=B.NCIFID_COBORROWER
																	AND B.NCIFID_COBORROWER IS NOT NULL
								--INNER JOIN #COBORROWER_IMPACTINGSRCALTKEY_FINAL_NOCOBO C ON A.NCIF_ID=C.NCIFID_COBORROWER
								INNER JOIN  #DEGACS D ON D.NCIF_ID=A.NCIF_ID
								AND D.CustomerACID<>A.CustomerACID--ADDED ON 20231110 BY ZAIN
								--AND D.CUSTOMERACID --ADDED ON 20231110 BY ZAIN
								--NOT IN (SELECT VALUE FROM string_split( B.CustomerACID_PrimaryAccount,',') WHERE RTRIM(VALUE)<>'')--ADDED ON 20231110 BY ZAIN
AND EffectiveFromTimeKey=27468 AND EffectiveToTimeKey=27468
--WHERE A.NatureofClassificatioN NOT IN ('C','D')
where NatureofClassificatioN is null
AND A.NCIF_AssetClassAlt_Key not in (1)

/*UPDATING IMPACTING ACCOUNT NO OF THE DRAGGED CASES WHERE WE RECEIVE C FROM THE SOURCE*/

DROP TABLE IF EXISTS #UPDATING_ACCNO_FROM_SRC_AS_C
select b.CustomerACID_PrimaryAccount,NCIFID_COBORROWER,a.*  INTO #UPDATING_ACCNO_FROM_SRC_AS_C 
			from NPA_IntegrationDetails_20250509 A inner join CoBorrowerData_Curnt B on a.NCIF_Id=b.NCIFID_COBORROWER
			where a.NatureofClassification='D'
			AND A.SrcSysAlt_Key<>100
			AND ImpactingAccountNo is null
			AND A.EffectiveFromTimeKey<=27468 
			AND A.EffectiveToTimeKey>=27468


UPDATE A SET A.IMPACTINGACCOUNTNO=B.CustomerACID_PrimaryAccount
			,A.CO_BORROWER_IMPACTED='Y'
			,A.PBOS_CULPRIT_IMPACT='Y'
			from NPA_IntegrationDetails_20250509 a inner join #UPDATING_ACCNO_FROM_SRC_AS_C b on a.NCIF_Id=b.NCIFID_COBORROWER
			where A.NatureofClassification='D'
			AND A.SrcSysAlt_Key<>100
			AND A.EffectiveFromTimeKey<=27468 
			AND A.EffectiveToTimeKey>=27468

			--SELECT * FROM #UPDATING_ACCNO_FROM_SRC_AS_C
/*GETTING SOURCE NAME OF PRIMARY ACCOUNT TO UPDATE IMPACTING SOURCE SYSTEM NAME*/
UPDATE A SET A.ImpactingSourceSystemName=C.SourceName
			from NPA_IntegrationDetails_20250509 a inner join #UPDATING_ACCNO_FROM_SRC_AS_C b on a.CustomerACID=b.CustomerACID_PrimaryAccount
			INNER JOIN DimSourceSystem C ON A.SrcSysAlt_Key=C.SourceAlt_Key
			WHERE A.NatureofClassification='C'
			AND A.SrcSysAlt_Key<>100
			AND A.EffectiveFromTimeKey<=27468 
			AND A.EffectiveToTimeKey>=27468

----------------------Changes done by Sudesh & Jaydev --------23112023-----------


update NPA_IntegrationDetails_20250509 
set NatureofClassification = 'C'
where NCIF_ID in (
select NCIF_ID from NPA_IntegrationDetails_20250509 
where NatureofClassification is null 
and NCIF_AssetClassAlt_Key not in (1))
AND  ( ((DPD_StockStmt>180  AND ISNULL(PrincipleOutstanding,0)>0))
				OR (IsFraud='Y')
				OR (IsOTS='Y' )
				OR (IsARC_Sale='Y' )
				OR (isnull(DCCO_Date,'2099-12-31')<@Ext_Date AND PROJ_COMPLETION_DATE IS NULL)
				OR (ISNULL(MaxDPD,0)>=91)
		)
AND SrcSysAlt_Key=100--CHANGED AS PER OBSERVATION OF MARKING C ON SOURCE SYSTEM EXCEPT FINACLE-2 ON 20231221 BY ZAIN
					AND EffectiveFromTimeKey<=27468 
					AND EffectiveToTimeKey>=27468 

		
update NPA_IntegrationDetails_20250509 set NatureofClassification = 'V'
where CustomerACID in (select CustomerACID from NPA_IntegrationDetails_20250509 where NatureofClassification is null and NCIF_AssetClassAlt_Key not in (1))
					AND EffectiveFromTimeKey<=27468 
					AND EffectiveToTimeKey>=27468 
					AND ISNULL(NatureofClassification,'')=''--20240121 AS PER OBSRVATION
					AND NCIF_AssetClassAlt_Key not in (1)--20240121 AS PER OBSRVATION

/*  END OF Changes */


/* UPDATING NULL FOR STD ACCOUNTS IN MAIN TABLE AS PER OBSERVATION IN IN TESTING*/
UPDATE A SET A.NatureofClassification=NULL
			,ImpactingSourceSystemName=NULL
			,A.ImpactingAccountNo=NULL
			,A.DateofImpacting=NULL
 --SELECT B.CustomerACID_PrimaryAccount,B.SrcSysAlt_Key,A.NCIF_ID,A.CUSTOMERACID,A.NatureofClassification 
FROM NPA_IntegrationDetails_20250509 A 
WHERE EffectiveFromTimeKey=27468 AND EffectiveToTimeKey=27468
AND A.NCIF_AssetClassAlt_Key in (1)


/*FOR UPDATING NULL SOURCE SYSTEM*/
SELECT CustomerACID,SrcSysAlt_Key INTO #NPA_IntegrationDetails_20250509 FROM NPA_IntegrationDetails_20250509 WHERE CustomerACID IN (
SELECT ImpactingAccountNo FROM NPA_IntegrationDetails_20250509 A WHERE A.EffectiveFromTimeKey<=27468 AND A.EffectiveToTimeKey>=27468
)


UPDATE A SET A.ImpactingSourceSystemName=C.SourceName,
			A.ImpactingAccountNo=B.CustomerACID
	FROM NPA_IntegrationDetails_20250509 A INNER JOIN #NPA_IntegrationDetails_20250509 B ON A.ImpactingAccountNo=B.CustomerACID
	INNER JOIN DimSourceSystem C ON B.SrcSysAlt_Key=C.SourceAlt_Key
	WHERE A.NatureofClassification<>'C'
	AND A.EffectiveFromTimeKey<=27468 AND A.EffectiveToTimeKey>=27468
	AND A.ImpactingSourceSystemName IS NULL

/*UPDATING IMPACTING ACCOUNT NO ,DATE OF IMPACTING AND SOURCESYSTEMNAME WHERE NCIF ARE REPEATED ADDEDON 20230512*/
DROP TABLE IF EXISTS #ImpactingAccountNo
SELECT DISTINCT NCIF_Id,CUSTOMERACID,VALUE INTO #ImpactingAccountNo
 FROM NPA_IntegrationDetails_20250509
		CROSS APPLY STRING_SPLIT(ImpactingAccountNo, ',')
	WHERE ImpactingAccountNo LIKE '%,%'
	AND EffectiveFromTimeKey<=27468
	AND EffectiveToTimeKey>=27468
	;
	
	DROP TABLE IF EXISTS #ImpactingAccountNo_SRCSYSALT
	SELECT DISTINCT A.*,C.SourceName INTO #ImpactingAccountNo_SRCSYSALT
	FROM #ImpactingAccountNo A INNER JOIN NPA_IntegrationDetails_20250509 B ON A.value=B.CustomerACID
		INNER JOIN DimSourceSystem C ON   C.SourceAlt_Key=B.SrcSysAlt_Key
		WHERE B.EffectiveFromTimeKey<=27468
				AND B.EffectiveToTimeKey>=27468
	
	--SELECT *FROM #ImpactingAccountNo_SRCSYSALT

	DROP TABLE IF EXISTS #ImpactingAccountNo_SRCSYSALT_FIN1
	SELECT CUSTOMERACID,STRING_AGG(CAST(value AS VARCHAR(MAX)),',')ImpactingAccountNo INTO #ImpactingAccountNo_SRCSYSALT_FIN1 
	FROM #ImpactingAccountNo_SRCSYSALT
	GROUP BY CUSTOMERACID


	UPDATE A SET A.VALUE=B.ImpactingAccountNo
	FROM #ImpactingAccountNo_SRCSYSALT A INNER JOIN #ImpactingAccountNo_SRCSYSALT_FIN1 B ON A.CustomerACID=B.CUSTOMERACID
	
	DROP TABLE IF EXISTS #ImpactingAccountNo_SRCSYSALT_FIN2
	SELECT DISTINCT NCIF_Id,CUSTOMERACID,VALUE,SourceNamE INTO #ImpactingAccountNo_SRCSYSALT_FIN2
	FROM #ImpactingAccountNo_SRCSYSALT
	
	DROP TABLE IF EXISTS #ImpactingAccountNo_SRCSYSALT_FINAL
	SELECT NCIF_Id,CUSTOMERACID,VALUE,STRING_AGG(SourceName,',')SourceName INTO #ImpactingAccountNo_SRCSYSALT_FINAL  FROM #ImpactingAccountNo_SRCSYSALT_FIN2 
	GROUP BY NCIF_Id,CUSTOMERACID,VALUE

	UPDATE A SET A.ImpactingAccountNo=B.VALUE
				,A.DATEOFIMPACTING=@Ext_Date
				,A.IMPACTINGSOURCESYSTEMNAME=B.SourceName
	FROM NPA_IntegrationDetails_20250509 A INNER JOIN  #ImpactingAccountNo_SRCSYSALT_FINAL B ON A.CUSTOMERACID=B.CUSTOMERACID
			WHERE A.EffectiveFromTimeKey<=27468
				AND A.EffectiveToTimeKey>=27468 
				AND A.NatureofClassification<>'C'

	UPDATE A SET A.DATEOFIMPACTING=@Ext_Date
	FROM NPA_IntegrationDetails_20250509 A
			WHERE A.EffectiveFromTimeKey<=27468
				AND A.EffectiveToTimeKey>=27468
				AND  A.DATEOFIMPACTING IS NULL
				AND A.NCIF_AssetClassAlt_Key<>1 
				AND A.AC_AssetClassAlt_Key=1


/*PBO DWN EXCL DUE TO ARC ,SHOULD NOT IMPACT COBO UPDATING COMMENT 20240107*/
	UPDATE A SET A.DegReason='PBO DWN EXCL DUE TO ARC'
	FROM NPA_IntegrationDetails_20250509 A
			WHERE A.EffectiveFromTimeKey<=27468
				AND A.EffectiveToTimeKey>=27468
				AND A.NCIF_AssetClassAlt_Key<>1 
				AND IsARC_Sale='Y'
				AND  A.DegReason IS NULL
--PBO DWN EXCL DUE TO ARC ,SHOULD NOT IMPACT COBO

--SELECT * INTO NPA_IntegrationDetails_20250509_20240121_AFTR_DEG FROM NPA_IntegrationDetails_20250509--
---------------------------------------------------------------------UPDATE ENDED	------------------------------------------------------------------


/*AMAR -- END OF CO-BORROWER*/

--Security Errison
--EXEC [dbo].[SecurityErosion] 27468


END

--UPDATE Audit Flag

COMMIT TRAN
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='AssetClassDegradation' AND [EXT_DATE]=@Ext_Date AND ISNULL([Audit_Flg],0)=0
END TRY
BEGIN CATCH
 DECLARE
   @ErMessage NVARCHAR(2048),
   @ErSeverity INT,
   @ErState INT
 
 SELECT  @ErMessage = ERROR_MESSAGE(),
   @ErSeverity = ERROR_SEVERITY(),
   @ErState = ERROR_STATE()

UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET ERROR_MESSAGE=@ErMessage 
WHERE [SP_Name]='AssetClassDegradation' AND [EXT_DATE]=@Ext_Date AND ISNULL([Audit_Flg],0)=0
 
 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )
ROLLBACK TRAN
END CATCH
GO