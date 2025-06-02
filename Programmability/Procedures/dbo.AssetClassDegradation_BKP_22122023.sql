SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROC [dbo].[AssetClassDegradation_BKP_22122023] (@TIMEKEY  INT)
WITH RECOMPILE
AS 
DECLARE @Ext_Date DATE=(select Date from IBL_ENPA_DB_LOCAL_DEV.dbo.SysDataMatrix  where TimeKey=@TIMEKEY)
--DECLARE @STD SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='STANDARD' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
--DECLARE @SubSTD SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='SUBSTANDARD' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
--DECLARE @DB1 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='DOUBTFUL-1' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
--DECLARE @DB2 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='DOUBTFUL-2' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
--DECLARE @DB3 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='DOUBTFUL-3' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
--DECLARE @LOS SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='LOSS' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
--DECLARE @WRE SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassName='WRITE OFF' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)

-----Changed on 16-06-2021 by Sunil


DECLARE @STD SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='STD' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @SubSTD SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='SUB' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @DB1 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='DB1' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @DB2 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='DB2' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @DB3 SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='DB3' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @LOS SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='LOS' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @WRE SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortNameEnum='WO' AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
/* START RESTRUCTURE DEPLOYMENT - 17062023  - NEW VARIABLE DECLARATION FOR RESTRUCTURE DEGRATDE*/
DECLARE @NaturalCalamity	INT=(SELECT ParameterAlt_Key FROM   DimParameter WHERE EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY AND DimParameterName='TypeofRestructuring' AND ParameterName='Natural Calamity')
DECLARE @DCCO				INT=(SELECT ParameterAlt_Key FROM   DimParameter WHERE EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY AND DimParameterName='TypeofRestructuring' AND ParameterName='DCCO')
DECLARE @Others_COMGT		INT=(SELECT ParameterAlt_Key FROM   DimParameter WHERE EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY AND DimParameterName='TypeofRestructuring' AND ParameterName='Others_COMGT')
/* END RESTRUCTURE DEPLOYMENT - 17062023 */



DECLARE @RES_TYE_OTH INT=(SELECT ParameterAlt_Key FROm DimParameter WHERE EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey AND DimParameterName='TypeofRestructuring' and ParameterName='Others')
DECLARE @Others_Jun19 INT=(SELECT ParameterAlt_Key FROM   DimParameter WHERE EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey AND DimParameterName='TypeofRestructuring' AND ParameterName='Others_Jun19')
IF OBJECT_ID('TEMPDB..#NCIF_ASSET') IS NOT NULL
   DROP TABLE #NCIF_ASSET

BEGIN TRY
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='AssetClassDegradation' AND [EXT_DATE]=@Ext_Date AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Ext_Date,@TimeKey,'AssetClassDegradation',GETDATE()
BEGIN TRAN
BEGIN
--Update NPA DATE and asset class For StockStatementDate if stock statement DPD >180 days  
UPDATE NPA_IntegrationDetails
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
FROM NPA_IntegrationDetails A
WHERE (((DPD_StockStmt>180 )---OR DPD_StockStmt=0) -----29102021 dpd zero bug
and ISNULL(PrincipleOutstanding,0)>0)
      OR IsFraud='Y'
	 /* OR SrcSysAlt_Key=(SELECT SourceAlt_Key FROm DimSourceSystem 
                                                     WHERE EffectiveFromTimeKey<=@TimeKey 
                                                       AND EffectiveToTimeKey>=@TimeKey 
                                                       AND SourceName='VISION PLUS')*/--Shifted to merge
													   ) 
AND AC_AssetClassAlt_Key =(Case when IsFraud='Y' And AC_AssetClassAlt_Key<>@LOS Then AC_AssetClassAlt_Key Else @STD End)    ------ Added On 16-06-2021 for Fraud
AND EffectiveFromTimeKey<=@TimeKey 
AND EffectiveToTimeKey>=@TimeKey 
AND AC_Closed_Date IS NULL

--Deg account if (IsOTS='Y' OR IsARC_Sale='Y'
UPDATE NPA_IntegrationDetails 
SET    NCIF_AssetClassAlt_Key=@SubSTD,
       FlgDeg='Y',
	   NCIF_NPA_Date=@Ext_Date,
	   DegReason=CASE WHEN IsOTS='Y' THEN 'Degrade Due to OTS Flag' When IsARC_Sale='Y' Then 'Degrade Due to ARC Flag' ELSE 'Degrade Due to DCCO Date'  END
WHERE EffectiveFromTimeKey<=@TIMEKEY
AND EffectiveToTimeKey>=@TIMEKEY
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
----FROM NPA_IntegrationDetails NI 
----INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=@TimeKey 
----                                     AND NI.EffectiveToTimeKey>=@TimeKey 
----									 AND RES.EffectiveFromTimeKey<=@TimeKey 
----                                     AND RES.EffectiveToTimeKey>=@TimeKey 
----									---- and ni.NCIF_Id=RES.RefCustomer_CIF
----									 AND NI.CustomerId=RES.RefCustomerId
----									 AND NI.CustomerACID=RES.RefSystemAcId
----WHERE IsRestructured='Y'
----AND DATEADD(YEAR,1,ISNULL(RES.RepaymentStartDate,RES.RestructureDt))>=@Ext_Date


--------Changed for Multiple Restructure Accounts of single ncif 21-03-2022
/*
If OBJECT_ID('TempDB..#Restructure') is not Null
Drop Table #Restructure

Select * into #Restructure from CURDAT.AdvAcRestructureDetail where EffectiveFromTimeKey<=@TIMEKEY and EffectiveToTimeKey>=@TIMEKEY

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

FROM NPA_IntegrationDetails NI 
INNER JOIN #Restructure RES ON NI.EffectiveFromTimeKey<=@TimeKey 
                                     AND NI.EffectiveToTimeKey>=@TimeKey 
									 AND RES.EffectiveFromTimeKey<=@TimeKey 
                                     AND RES.EffectiveToTimeKey>=@TimeKey 
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
	FROM NPA_IntegrationDetails NI 
	INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=@TimeKey 
										 AND NI.EffectiveToTimeKey>=@TimeKey 
										 AND RES.EffectiveFromTimeKey<=@TimeKey 
										 AND RES.EffectiveToTimeKey>=@TimeKey 
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
	FROM NPA_IntegrationDetails NI 
	INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=@TimeKey 
										 AND NI.EffectiveToTimeKey>=@TimeKey 
										 AND RES.EffectiveFromTimeKey<=@TimeKey 
										 AND RES.EffectiveToTimeKey>=@TimeKey 
										 AND NI.CustomerId=RES.RefCustomerId
										 AND NI.CustomerACID=RES.RefSystemAcId
			
	WHERE 
		IsRestructured='Y'
		AND AC_AssetClassAlt_Key in (2,3,4,5,6)
		AND ISNULL(RestructureDt,'2099-01-01')<AC_NPA_Date
	/* NEW RESTRUCTURE ACCOUNT EXISTING NPA - IF RESTRYCTURE DATE IS NCIF_NPA_Date THEN RESTRYCTURE DATE WILL BE MARKED AS NCIF_NPA_Date */
	UPDATE NI
			SET	NCIF_NPA_Date=RES.RestructureDt
	FROM NPA_IntegrationDetails NI 
	INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=@TimeKey 
										 AND NI.EffectiveToTimeKey>=@TimeKey 
										 AND RES.EffectiveFromTimeKey<=@TimeKey 
										 AND RES.EffectiveToTimeKey>=@TimeKey 
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
DECLARE @SUB_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='SUB_Days' 
AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @DB1_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB1_Days' 
AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @DB2_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB2_Days' 
AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)

DECLARE @SUB_Year INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='SUB_Year' 
AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @DB1_Year INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB1_Year' 
AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @DB2_Year INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB2_Year' 
AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
--select @SUB_Days,@DB1_Days,@DB2_Days

Drop Table if exists #Audit_Finacle
Select NCIF_Id,CustomerId,CustomerACID,SrcSysAlt_Key 
,AC_AssetClassAlt_Key Source_AC_AssetClassAlt_Key,AC_NPA_Date Source_AC_NPA_Date,
DbtDT Source_dbtdt,Getdate() InsertDate
,Cast(0 as int )Calc_AC_AssetClassAlt_Key 
,Cast(Null as Date) Calc_AC_NPA_Date 
,Cast(null as Date) Calc_dbtdt 
,EffectiveFromTimeKey,EffectiveToTimeKey
into #Audit_Finacle
from NPA_IntegrationDetails where EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey
and SrcSysAlt_Key=@finacleSourceAltKey
/* START 17062023 DEPLOYMENT FOR RESSTRUCTURE CHANGES*/
/* AMAR  - 18092023 - FILTERED RESTRUCTURE ACCOUNTS NCIF IDs FOR USE IN AGING */
---???? to be created on the temp table basis

	DROP TABLE IF EXISTS #RESTR_ACS
	SELECT NI.CustomerACID --- ???? Acccount related cols to be taken
		INTO #RESTR_ACS
	FROM NPA_IntegrationDetails NI 
		INNER JOIN [CurDat].AdvAcRestructureDetail RES ON NI.EffectiveFromTimeKey<=@TimeKey 
					AND NI.EffectiveToTimeKey>=@TimeKey 
					AND RES.EffectiveFromTimeKey<=@TimeKey 
					AND RES.EffectiveToTimeKey>=@TimeKey 
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

Update NPA_IntegrationDetails set  
dbtdt=case when DbtDT IS NULL and 
--DATEDIFF(YEAR,coalesce(NCIF_NPA_Date,AC_NPA_Date),@Ext_Date)>@SUB_Year 
 IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (coalesce(NCIF_NPA_Date,AC_NPA_Date),@DB1_Year)<=@Ext_Date --As per discussion SSK Change to implement Yearly Logic Added by Pranay on 03032023
--then DATEADD(year,1,coalesce(NCIF_NPA_Date,AC_NPA_Date))
	then IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (coalesce(NCIF_NPA_Date,AC_NPA_Date),@DB1_Year)
when DbtDT IS not null then DbtDT  ---  added by satish 
end 
from NPA_IntegrationDetails A 
INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When A.NCIF_AssetClassAlt_Key is not null then A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY
WHERE B.AssetClassShortName NOT IN('LOS','WO') ------ Added by SSK to prevent classification of written of accounts on date 22042023 
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(A.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 AND ISNULL(A.FlgErosion,'N')<>'Y'
 AND  A.EffectiveFromTimeKey=@TIMEKEY AND A.EffectiveToTimeKey=@TIMEKEY
--and SrcSysAlt_Key=@finacleSourceAltKey
 --- ???? or (RES.RestructureDt<AC_NPA_Date )
 AND (SrcSysAlt_Key=@finacleSourceAltKey 
		OR EXISTS (SELECT CustomerACID FROM #RESTR_ACS RES WHERE RES.CustomerACID=A.CustomerACID) ---/* 17062023 DEPLOYMENT FOR RESSTRUCTURE CHANGES*/
		OR EXISTS (SELECT CustomerACID FROM #RESTRUCTURE_FINACLE_CASES RES1 WHERE RES1.CustomerACID=A.CustomerACID)
	 )

	
 /* If DBT Dt is available , then we need to do Asset Classification ( Logic as implemented for Finacle )
	    added by satish as on date 09052023 */
		Drop table if exists #Erosion_Accts
		Select CustomerACID Into #Erosion_Accts   from NPA_IntegrationDetails where EffectiveFromTimeKey<=@TIMEKEY
		and EffectiveToTimeKey>=@TIMEKEY --and SecuredFlag='Y' and IsFunded='Y'
		and dbtdt is not null and LossDT is null  ----- added on 22052023 for erosion cases asset class
/* If loss Dt is available , then we need to maintain Asset Classification as loss added by satish as on date 09052023 */
  Update NPA_IntegrationDetails set  
NCIF_AssetClassAlt_Key=@LOS
from NPA_IntegrationDetails A
INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When A.NCIF_AssetClassAlt_Key is not null then A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY
WHERE 
   B.AssetClassShortName NOT IN ('WO') ------ Added by SSK to prevent classification of written of accounts on date 22042023 
AND (ISNULL(A.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 ---AND ISNULL(NI.FlgErosion,'N')<>'Y' /* as per discussion with ssk records,with erosion will also undergo ageing on the basis of dbt dt */
 AND  A.EffectiveFromTimeKey=@TIMEKEY AND A.EffectiveToTimeKey=@TIMEKEY
 and LossDT is not null ----- added on 22052023 for erosion cases asset class

Update NPA_IntegrationDetails set  
NCIF_AssetClassAlt_Key=Case when --DbtDT is null and DATEDIFF(YEAR,AC_NPA_Date,@Ext_Date)<=@SUB_Year then @SubSTD   --- dbtdt came in source
        DbtDT is null and IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (COALESCE(NCIF_NPA_Date,AC_NPA_DATE),@SUB_Year)>@Ext_Date then @SubSTD  
	  --when DbtDT is not null and DATEDIFF(YEAR,DbtDT,@Ext_Date)<=@DB1_Year then @DB1
	   when DbtDT is not null and  -- As per discussion SSK Change to implement Yearly Logic Added by Pranay on 03032023
	   IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (DbtDT,@DB1_Year) > @Ext_Date then @DB1
      --when DbtDT is not null and DATEDIFF(YEAR,DbtDT,@Ext_Date)<=(@DB1_Year+@DB2_Year) then @DB2
	    when DbtDT is not null and  -- As per discussion SSK Change to implement Yearly Logic Added by Pranay on 03032023
	   IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) > @Ext_Date then @DB2

	  --when DbtDT is not null and DATEDIFF(YEAR,DbtDT,@Ext_Date) >=(@DB1_Year+@DB2_Year) then @DB3 end  
	    when DbtDT is not null and  -- As per discussion SSK Change to implement Yearly Logic Added by Pranay on 03032023
	   IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) <= @Ext_Date then @DB3 END

from NPA_IntegrationDetails A
INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When A.NCIF_AssetClassAlt_Key is not null then A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY
WHERE --B.AssetClassShortName NOT IN('LOS')
   B.AssetClassShortName NOT IN ('LOS','WO') ------ Added by SSK to prevent classification of written of accounts on date 22042023 
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(A.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 --AND ISNULL(A.FlgErosion,'N')<>'Y' /* as per discussion with ssk records,with erosion will also undergo ageing on the basis of dbt dt */ ----- added on 22052023 for erosion cases asset class
 AND  A.EffectiveFromTimeKey=@TIMEKEY AND A.EffectiveToTimeKey=@TIMEKEY
 ---------AND (SrcSysAlt_Key=@finacleSourceAltKey 
 --- ???? or (RES.RestructureDt<AC_NPA_Date )
 AND (SrcSysAlt_Key=@finacleSourceAltKey 
		OR EXISTS (SELECT CustomerACID FROM #RESTR_ACS RES WHERE RES.CustomerACID=A.CustomerACID)  ---/* 17062023 DEPLOYMENT FOR RESSTRUCTURE CHANGES*/
	    OR EXISTS (SELECT CustomerACID FROM #RESTRUCTURE_FINACLE_CASES RES1 WHERE RES1.CustomerACID=A.CustomerACID)
	    OR EXISTS (SELECT CustomerACID FROM #Erosion_Accts RES2 WHERE RES2.CustomerACID=A.CustomerACID)   /* If DBT Dt is available , then we need to do Asset Classification ( Logic as implemented for Finacle ) added by satish as on date 09052023 */
		)  ----- added on 22052023 for erosion cases asset class
	
 Update A set a.Calc_AC_AssetClassAlt_Key=b.AC_AssetClassAlt_Key
 ,a.Calc_AC_NPA_Date=b.AC_NPA_Date
 ,a.Calc_dbtdt=b.DbtDT
 from #Audit_Finacle A inner Join
 NPA_IntegrationDetails b
 on a.EffectiveFromTimeKey<=@TIMEKEY and a.EffectiveToTimeKey>=@TIMEKEY
 and b.EffectiveFromTimeKey<=@TIMEKEY and b.EffectiveToTimeKey>=@TIMEKEY
Delete from AuditTrailAssetClassChange where SrcSysAlt_Key=@finacleSourceAltKey 
 and EffectiveFromTimeKey<=@TIMEKEY and EffectiveToTimeKey>=@TIMEKEY

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
from NPA_IntegrationDetails A where A.SrcSysAlt_Key=@SourceAltKey and ISNULL(A.MaxDPD,0)>=91   -----------A.dpd_overdueloans>90
AND  A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY
--And ISNUll(A.Balance,0)>0 ANd ISNULL(A.PrincipleOutstanding,0)>0
And ISNULL(A.AC_AssetClassAlt_Key,0)=1 And ISNULL(A.NCIF_AssetClassAlt_Key,1)<>6




------------------------Aging   Added on 29/12/2021 for Finacle-2 Aging------- 




/* Declared this days variables above for finacle asset class handling added as on date 21042023*/
--DECLARE @SUB_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='SUB_Days' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY )
--DECLARE @DB1_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB1_Days' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY )
--DECLARE @DB2_Days INT =(SELECT RefValue FROM RefPeriod WHERE BusinessRule='DB2_Days' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY )

--Select A.*
--FROM NPA_IntegrationDetails A 
--INNER JOIN DimAssetClass B  ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
--AND  B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY
--WHERE B.AssetClassShortName NOT IN('STD','LOS')
-- AND ISNULL(A.FlgDeg,'N')<>'Y'  AND (ISNULL(A.FlgProcessing,'N')='N')
-- AND A.NCIF_NPA_Date IS NOT NULL  AND ISNULL(A.FlgErosion,'N')<>'Y'
-- AND  A.EffectiveFromTimeKey=@TIMEKEY AND A.EffectiveToTimeKey=@TIMEKEY
-- And A.SrcSysAlt_Key=@SourceAltKey
-- And A.NCIF_Id='69700941'

 
--Select A.*
--FROM NPA_IntegrationDetails A 
----INNER JOIN DimAssetClass B  ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
----AND  B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY
--WHERE A.NCIF_Id='69700941'
 
UPDATE A SET A.NCIF_AssetClassAlt_Key= (
                                        CASE  WHEN  DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date   THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='SUB' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
										  WHEN     DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date   THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB1' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
									      WHEN     DATEADD(DAY,@SUB_Days+@DB1_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days+@DB2_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB2' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
									       WHEN    DATEADD(DAY,(@DB1_Days+@SUB_Days+@DB2_Days),(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date  THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB3' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
									     --  WHEN    DATEADD(DD,1,DATEADD(MONTH,(@DB1_Days+@SUB_Days+@DB2_Days),A.SysNPA_Dt))<=@Ext_Date  THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB3' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
										 --  ELSE A.SysAssetClassAlt_Key
									   END)
          ,A.DBTDT= (CASE 
									       WHEN  DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date  THEN DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))
									       WHEN  DATEADD(DAY,@SUB_Days+@DB1_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days+@DB2_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))>@Ext_Date   THEN DATEADD(DAY,@SUB_Days,(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))
									       WHEN  DATEADD(DAY,(@DB1_Days+@SUB_Days+@DB2_Days),(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))<=@Ext_Date THEN DATEADD(DAY,(@SUB_Days),(Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_NPA_Date Else A.AC_NPA_Date End))
									     --  WHEN  DATEADD(DD,1,DATEADD(MONTH,(@DB1_Days+@SUB_Days+@DB2_Days),A.SysNPA_Dt))<=@Ext_Date THEN DATEADD(DD,1,DATEADD(MONTH,(@SUB_Days),A.SysNPA_Dt))
										 --  ELSE DBTDT 
									   END)

FROM NPA_IntegrationDetails A 
INNER JOIN DimAssetClass B  ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
AND  B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY
WHERE B.AssetClassShortName NOT IN('STD','LOS')
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(A.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 AND ISNULL(A.FlgErosion,'N')<>'Y'
 AND  A.EffectiveFromTimeKey=@TIMEKEY AND A.EffectiveToTimeKey=@TIMEKEY
 And A.SrcSysAlt_Key=@SourceAltKey

 /*
UPDATE A SET A.NCIF_AssetClassAlt_Key= (
                                        CASE  WHEN  DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)>@Ext_Date   THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='SUB' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
										  WHEN     DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days,A.NCIF_NPA_Date)>@Ext_Date   THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB1' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
									      WHEN     DATEADD(DAY,@SUB_Days+@DB1_Days,A.NCIF_NPA_Date)<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days+@DB2_Days,A.NCIF_NPA_Date)>@Ext_Date THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB2' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
									       WHEN    DATEADD(DAY,(@DB1_Days+@SUB_Days+@DB2_Days),A.NCIF_NPA_Date)<=@Ext_Date  THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB3' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
									     --  WHEN    DATEADD(DD,1,DATEADD(MONTH,(@DB1_Days+@SUB_Days+@DB2_Days),A.SysNPA_Dt))<=@Ext_Date  THEN (SELECT AssetClassAlt_Key FROM DimAssetClass WHERE AssetClassShortName='DB3' AND EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey>=@TIMEKEY)
										 --  ELSE A.SysAssetClassAlt_Key
									   END)
          ,A.DBTDT= (CASE 
									       WHEN  DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days,A.NCIF_NPA_Date)>@Ext_Date  THEN DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)
									       WHEN  DATEADD(DAY,@SUB_Days+@DB1_Days,A.NCIF_NPA_Date)<=@Ext_Date AND  DATEADD(DAY,@SUB_Days+@DB1_Days+@DB2_Days,A.NCIF_NPA_Date)>@Ext_Date   THEN DATEADD(DAY,@SUB_Days,A.NCIF_NPA_Date)
									       WHEN  DATEADD(DAY,(@DB1_Days+@SUB_Days+@DB2_Days),A.NCIF_NPA_Date)<=@Ext_Date THEN DATEADD(DAY,(@SUB_Days),A.NCIF_NPA_Date)
									     --  WHEN  DATEADD(DD,1,DATEADD(MONTH,(@DB1_Days+@SUB_Days+@DB2_Days),A.SysNPA_Dt))<=@Ext_Date THEN DATEADD(DD,1,DATEADD(MONTH,(@SUB_Days),A.SysNPA_Dt))
										 --  ELSE DBTDT 
									   END)

FROM NPA_IntegrationDetails A 
INNER JOIN DimAssetClass B  ON  A.NCIF_AssetClassAlt_Key =B.AssetClassAlt_Key 
AND  B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY
WHERE B.AssetClassShortName NOT IN('STD','LOS')
 AND ISNULL(A.FlgDeg,'N')<>'Y'  AND (ISNULL(A.FlgProcessing,'N')='N')
 AND A.NCIF_NPA_Date IS NOT NULL  AND ISNULL(A.FlgErosion,'N')<>'Y'
 AND  A.EffectiveFromTimeKey=@TIMEKEY AND A.EffectiveToTimeKey=@TIMEKEY
 And A.SrcSysAlt_Key=@SourceAltKey
*/

 --Select NCIF_AssetClassAlt_Key,NCIF_NPA_Date,DbtDT,AC_AssetClassAlt_Key,AC_NPA_Date,PrincOverdueSinceDt,* from NPA_IntegrationDetails where NCIF_Id='69700941'
/* Added on 20052023 at prod for 1 restructure accts and 1 non restructure account  */
-----------------------------------------------------
/* added by satish as on date 03052023 to handle 1 ncif restructure and another non restructe asset downgrade purpse */
			Drop table if exists #NCIF_RestDual
			Select NCIF_Id into #NCIF_RestDual from NPA_IntegrationDetails where EffectiveFromTimeKey<=@TIMEKEY and EffectiveToTimeKey>=@TIMEKEY
			and isnull(IsRestructured,'')='Y' and AC_AssetClassAlt_Key=1
			intersect
			Select NCIF_Id from NPA_IntegrationDetails where EffectiveFromTimeKey<=@TIMEKEY and EffectiveToTimeKey>=@TIMEKEY
			and isnull(IsRestructured,'')='N' and AC_AssetClassAlt_Key<>1

/* 18042023 AMAR -- NPA DATE PERCOLATION AT ENCIF ID LEVEL */
	
			/* FIND MINIMUM NPA DATE AT NCIF IID LEVEL */
			Drop table if exists #Rest_NCIF_Records
			SELECT NI.NCIF_Id, MIN(CASE WHEN NI.NCIF_NPA_Date<=ISNULL(RES.RestructureDt,NCIF_NPA_Date) THEN NCIF_NPA_Date ELSE REs.RestructureDt END) NCIF_NPA_Date--- ???? Acccount related cols to be taken
			into #Rest_NCIF_Records
			FROM NPA_IntegrationDetails NI 
				INNER JOIN #NCIF_RestDual NID
					ON NI.NCIF_Id=NID.NCIF_Id
				LEFT JOIN [CurDat].AdvAcRestructureDetail RES 
					ON RES.EffectiveFromTimeKey<=@TimeKey AND RES.EffectiveToTimeKey>=@TimeKey 
					AND NI.CustomerId=RES.RefCustomerId
					AND NI.CustomerACID=RES.RefSystemAcId
			WHERE  NI.EffectiveFromTimeKey<=@TimeKey AND NI.EffectiveToTimeKey>=@TimeKey 
			GROUP BY NI.NCIF_Id
    	
	/* UPDATE NCIF_NPA_Date */
	UPDATE NI
		SET NI.NCIF_NPA_Date=RES.NCIF_NPA_Date
		,DbtDT=case when DbtDT IS NULL and IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (RES.NCIF_NPA_Date,@DB1_Year)<=@Ext_Date 
	                then IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (RES.NCIF_NPA_Date,@DB1_Year)
                    when DbtDT IS not null then DbtDT end 
		FROM NPA_IntegrationDetails NI
		INNER JOIN #Rest_NCIF_Records RES
		ON NI.EffectiveFromTimeKey<=@TimeKey AND NI.EffectiveToTimeKey>=@TimeKey 
		AND NI.NCIF_Id=RES.NCIF_Id
		INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY
WHERE B.AssetClassShortName NOT IN('LOS','WO')
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(NI.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 AND ISNULL(NI.FlgErosion,'N')<>'Y'

/* 18042023 AMAR -- NPA DATE PERCOLATION AT ENCIF ID LEVEL */

	UPDATE NI set
 NCIF_AssetClassAlt_Key=Case when 
        DbtDT is null and IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (NI.NCIF_NPA_Date,@SUB_Year)>@Ext_Date then @SubSTD  
	  	   when DbtDT is not null and 
	   IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (DbtDT,@DB1_Year) > @Ext_Date then @DB1
       when DbtDT is not null and  
	   IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) > @Ext_Date then @DB2
	   when DbtDT is not null and  
	   IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] (DbtDT,(@DB1_Year+@DB2_Year)) <= @Ext_Date then @DB3 end
	    FROM NPA_IntegrationDetails NI
		INNER JOIN #Rest_NCIF_Records RES
		ON NI.EffectiveFromTimeKey<=@TimeKey AND NI.EffectiveToTimeKey>=@TimeKey 
		AND NI.NCIF_Id=RES.NCIF_Id
		INNER JOIN DimAssetClass B  --ON Case When A.AC_AssetClassAlt_Key=1 then  A.NCIF_AssetClassAlt_Key Else A.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key 
ON Case When NI.NCIF_AssetClassAlt_Key is not null then NI.NCIF_AssetClassAlt_Key Else NI.AC_AssetClassAlt_Key End  =B.AssetClassAlt_Key
AND  B.EffectiveFromTimeKey<=@TIMEKEY AND B.EffectiveToTimeKey>=@TIMEKEY
WHERE B.AssetClassShortName NOT IN('LOS','WO')
 --AND ISNULL(A.FlgDeg,'N')<>'Y'
 AND (ISNULL(NI.FlgProcessing,'N')='N')
 --AND A.NCIF_NPA_Date IS NOT NULL  
 ---AND ISNULL(NI.FlgErosion,'N')<>'Y' /* as per discussion with ssk records,with erosion will also undergo ageing on the basis of dbt dt */

 
/* END OF NPA DATE PERCOLATION */

----Security Errison
--EXEC [dbo].[SecurityErosion] @TimeKey

------NCIF_ASSETCLASSALT_KEY And NCIF_NPA_DATE IS UPDATED AS NULL BECAUSE FROM  EXTRACTION PROCESS NCIF_ASSETCLASSALT_KEY IS UPDATED AS 0
------Added for With Out WriteOff NCIF_ID---
IF OBJECT_ID('TEMPDB..#NCIF_ID') IS NOT NULL
   DROP TABLE #NCIF_ID

Select distinct A.NCIF_Id 
into #NCIF_ID 
from NPA_IntegrationDetails A 
Where EffectiveFromTimeKey<=@Timekey
And EffectiveToTimeKey>=@Timekey
And ISNULL(WriteOffFlag,'N')='Y'
AND A.NCIF_Id NOT IN(SELECT DISTINCT NCIF_Id FROM NPA_IntegrationDetails WHERE EffectiveFromTimeKey<=@TIMEKEY AND EffectiveToTimeKey<=@TIMEKEY AND IsFraud='Y')
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
	FROM NPA_IntegrationDetails A
	--Inner Join DIMPRODUCT C On C.ProductCode=A.ProductCode   ---------------------Added on 14-06-2021 by Sunil
	--And C.EffectiveFromTimeKey<=@TIMEKEY AND c.EffectiveToTimeKey>=@TIMEKEY
	WHERE (a.EffectiveFromTimeKey<=@TIMEKEY AND a.EffectiveToTimeKey>=@TIMEKEY) 
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
	 FROM NPA_IntegrationDetails A
	 INNER JOIN #NCIF_ASSET B
		ON  (A.EffectiveFromTimeKey <= @Timekey AND A.EffectiveToTimeKey >= @Timekey)
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
	FROM NPA_IntegrationDetails A
	Inner Join #NCIF_ID B On A.NCIF_Id=B.NCIF_Id
	WHERE (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY) 
	AND (Case When A.AC_AssetClassAlt_Key in (1,2,3,4,5,6) Then 1
			--When  isnull(A.writeoffdate,'1900-01-01')>='2019-04-01' 
			When  isnull(A.writeoffdate,'2019-04-01')>='2019-04-01'    -----handled for Null writeoff Date
			and isnull(A.WriteOffFlag,'N')='Y' then 1 else 0 end)=1
	AND ISNULL(AC_AssetClassAlt_Key,'')<>'' 
    AND AC_Closed_Date IS NULL

	Update 	#NCIF_ASSETWriteOff set AC_AssetClassAlt_Key=(Case  
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB_LOCAL_DEV.dbo.SysDataMatrix  where TimeKey=@TIMEKEY))between 0 and 365 then @SubSTD
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB_LOCAL_DEV.dbo.SysDataMatrix  where TimeKey=@TIMEKEY))between 366 and 730 then @DB1
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB_LOCAL_DEV.dbo.SysDataMatrix  where TimeKey=@TIMEKEY))between 731 and 1460 then @DB2
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB_LOCAL_DEV.dbo.SysDataMatrix  where TimeKey=@TIMEKEY))between 1461 and 99997 then @DB3
												when WriteOffFlag='Y' and 
													DATEDIFF(day, ISNULL(AC_NPA_Date,WriteOffDate),(select Date from IBL_ENPA_DB_LOCAL_DEV.dbo.SysDataMatrix  where TimeKey=@TIMEKEY))=99998 then @LOS
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
from NPA_IntegrationDetails A
Inner join #NCIF_ASSETWriteOff B ON A.NCIF_Id=B.NCIF_Id
                                And A.CustomerACID=B.CustomerACID
Where A.EffectiveFromTimeKey<=@TIMEKEY
And A.EffectiveToTimeKey>=@TIMEKEY	
AND AC_Closed_Date IS NULL


UPDATE NPA_IntegrationDetails SET 
NCIF_AssetClassAlt_Key=AC_AssetClassAlt_Key,
NCIF_NPA_Date=AC_NPA_Date
WHERE EffectiveFromTimeKey<=@TIMEKEY
AND EffectiveToTimeKey>=@TIMEKEY
AND WriteOffFlag='Y'
AND IsFraud<>'Y'
AND isnull(writeoffdate,'2019-04-01')<'2019-04-01'
AND NCIF_AssetClassAlt_Key IS NULL

------------Write off Accounts Closed


--Security Errison
--EXEC [dbo].[SecurityErosion] @TimeKey


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