SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

	-- =============================================
	-- Author:		<Name:Code>
	-- Create date: <18-04-2016>
	-- Description:	<FETCH CUSTOMER DETAILS FOR Customer Remark >
	-- =============================================
CREATE PROCEDURE [dbo].[SecFlgCorrection patch] 
AS

--USE [IBL_ENPA_DB_OLD] ----- Change DB name 
--GO
 

/***************************
1. Replace tables NPA_IntegrationDetails_30APR2025DATA, 
					Curdat.AdvSecurityDetail_30APR2025DATA
					,Curdat.AdvSecurityValueDetail_30APR2025DATA
					,dbo.SecurityDistribution_30APR2025DATA 
					,CurDat.AcceleratedProv_30APR2025DATA
   with production tables having 30 April 2025 data which we need to correct
2. Create table SecuFlgImpactedAc from excel data shared for Total Ac.
3. Execute script and check result.
*************************/ 
 
DECLARE @TimeKey int=(Select Timekey FROM SysDataMatrix WHERE Date='2025-04-30')

Drop table if exists #NI_Details
select * into #NI_Details FROM NPA_IntegrationDetails_30APR2025DATA
Where EffectiveFromTimeKey=@TimeKey AND EffectiveToTimeKey=@TimeKey
AND NCIF_Id in (select distinct NCIF_Id from SecuFlgImpactedAc)  

UPDATE #NI_Details SET 
ProvisionAlt_Key=NULL     
,Provsecured=NULL			
,ProvUnSecured=NULL		
,TotalProvision=NULL	 	 
,SecurityValue=NULL
,SecuredAmt=NULL
,UnSecuredAmt=NULL
,AddlProvision=NULL
,AddlProvisionPer=NULL
 
UPDATE A SET SecuredFlag=B.finacle_flg
FROM #NI_Details A JOIN  dbo.SecuFlgImpactedAc B 
ON ISNULL(A.NCIF_Id,'')=ISNULL(B.NCIF_Id,'') AND A.CustomerACID=B.CustomerAcID  
 
select A.* into #AdvSecurityDetail FROM Curdat.AdvSecurityDetail_30APR2025DATA A JOIN  #NI_Details B 
ON  A.RefCustomer_CIF=B.NCIF_Id  AND A.RefSystemAcId=B.CustomerACID
Where A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
 
select A.* into #AdvSecurityValueDetail  FROM Curdat.AdvSecurityValueDetail_30APR2025DATA A JOIN  #AdvSecurityDetail B 
ON  A.SecurityEntityID=B.SecurityEntityID 
Where A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
 
-------------------------------  SecurityAppropriation ---------------------------------
 
DECLARE @ProcessingDate DATE = (SELECT DATE FROM SysDataMatrix WHERE TimeKey=@TimeKey)
 
IF OBJECT_ID('tempdb..#Temp') IS NOT NULL
DROP TABLE #Temp

CREATE TABLE #Temp(
NCIF_ID VARCHAR(100)
,CustomerId VARCHAR(50)
,CollateralID VARCHAR(100)
,CustomerExposer DECIMAL(30,5)
,CollTotal DECIMAL(30,5)
,CollWiseCustExposure  DECIMAL(30,5),
AppPER  DECIMAL(10,5)
,AppSecurity DECIMAL(30,5))

INSERT INTO #Temp(NCIF_ID,CustomerId,CollateralID,CollTotal)
SELECT A.RefCustomer_CIF,RefCustomerId,A.CollateralID ,B.CurrentValue
FROM #AdvSecurityDetail  A
INNER JOIN #AdvSecurityValueDetail  B ON  A.EffectiveFromTimeKey<=@TimeKey
                                            AND A.EffectiveToTimeKey>=@TimeKey
                                            AND B.EffectiveFromTimeKey<=@TimeKey
                                            AND B.EffectiveToTimeKey>=@TimeKey
											AND A.SecurityEntityID=B.SecurityEntityID
INNER JOIN #NI_Details C ON  C.EffectiveFromTimeKey=@TimeKey
                                   AND A.RefSystemAcId=C.CustomerACID
                                   AND A.RefCustomerId=C.CustomerId
								   AND A.RefCustomer_CIF=C.NCIF_Id
WHERE A.CollateralID IN(SELECT DISTINCT CollateralID 
FROM #AdvSecurityDetail 
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey)
AND ISNULL(B.ValuationExpiryDate,'1900-01-01')>=@ProcessingDate
AND C.SecuredFlag='Y'
AND C.IsFunded='Y'
AND ISNULL(B.CurrentValue,0)>0
GROUP BY A.RefCustomer_CIF,RefCustomerId,A.CollateralID,B.CurrentValue

CREATE NONCLUSTERED INDEX #Temp_IX ON #Temp(NCIF_ID,CustomerId)

UPDATE B SET CustomerExposer=PrincipleOutstanding
FROM (SELECT NCIF_Id,CustomerId,SUM(PrincipleOutstanding) PrincipleOutstanding
FROM #NI_Details A 
WHERE A.CustomerId IN(SELECT DISTINCT CustomerId FROM #TEMP)
AND EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND SecuredFlag='Y'
AND IsFunded='Y'
GROUP BY  NCIF_Id,CustomerId)A
INNER JOIN #Temp B ON A.CustomerId=B.CustomerId
                   AND A.NCIF_Id=B.NCIF_ID

UPDATE B SET CollWiseCustExposure=A.CustomerExposer
FROM
(SELECT CollateralID,SUM(CustomerExposer)  CustomerExposer
FROM #Temp
GROUP BY CollateralID) A 
INNER JOIN #Temp B ON A.CollateralID=B.CollateralID

UPDATE #Temp SET AppPER=(CustomerExposer/CollWiseCustExposure)*100
WHERE CollWiseCustExposure>0

UPDATE #Temp SET AppSecurity=(CollTotal*AppPER)/100

IF OBJECT_ID('tempdb..#AccTemp') IS NOT NULL
DROP TABLE #AccTemp

CREATE TABLE #AccTemp(NCIF_ID VARCHAR(100),CustomerId VARCHAR(50),CollateralID VARCHAR(100),CustomerExposer DECIMAL(30,5),CollTotal DECIMAL(30,5),CollWiseCustExposure  DECIMAL(30,5),
AppPER  DECIMAL(10,5),AppSecurity DECIMAL(30,5),CustomerAcID VARCHAR(50),AccountPOS DECIMAL(30,5),AccountSecPer  DECIMAL(10,5),AccountAppSecurity DECIMAL(30,5))

insert into #AccTemp
(NCIF_ID
,CustomerId
,CollateralID
,CustomerExposer,CollTotal,CollWiseCustExposure,AppPER,AppSecurity,CustomerAcID,AccountPOS)
SELECT DISTINCT A.NCIF_ID,A.CustomerId,A.CollateralID,A.CustomerExposer,A.CollTotal,A.CollWiseCustExposure,A.AppPER,A.AppSecurity,B.CustomerAcID,B.PrincipleOutstanding
FROM #Temp A
INNER JOIN #NI_Details B ON B.EffectiveFromTimeKey<=@TimeKey
                                   AND B.EffectiveToTimeKey>=@TimeKey
								   and a.NCIF_ID=b.NCIF_Id
								   and a.CustomerId=b.CustomerId
WHERE  b.SecuredFlag='Y'
AND b.IsFunded='Y'
AND B.PrincipleOutstanding>0

CREATE NONCLUSTERED INDEX #AccTemp_IX ON #AccTemp(NCIF_ID,CustomerId,CustomerACID) INCLUDE(AccountAppSecurity)

UPDATE #AccTemp SET AccountSecPer=(AccountPOS/CustomerExposer)*100
WHERE CustomerExposer>0

UPDATE #AccTemp SET AccountAppSecurity=(AccountSecPer*AppSecurity)/100


update A SET A.SecurityValue=b.AccountAppSecurity,
		            SecuredAmt=CASE WHEN ISNULL(AccountAppSecurity,0)>0
					                     THEN (CASE WHEN ISNULL(B.AccountAppSecurity,0)>ISNULL(A.PrincipleOutstanding,0) 
					                     THEN ISNULL(A.PrincipleOutstanding,0) 
								    ELSE ISNULL(B.AccountAppSecurity,0) 
							   END)
							   ELSE 0
							   END,
                    UnSecuredAmt=(CASE WHEN ISNULL(AccountAppSecurity,0)>0
					                       THEN (CASE WHEN ISNULL(B.AccountAppSecurity,0)>ISNULL(A.PrincipleOutstanding,0) 
					                                       THEN 0 
								                      ELSE ISNULL(A.PrincipleOutstanding,0)-ISNULL(B.AccountAppSecurity,0) 
							                       END)
                                       ELSE A.PrincipleOutstanding
								  END)	    
		FROM DBO.#NI_Details A
		LEFT JOIN (SELECT NCIF_ID,CustomerId,CustomerACID,SUM(AccountAppSecurity) AccountAppSecurity
		             FROM #AccTemp
					GROUP BY NCIF_ID,CustomerId,CustomerACID) b ON B.NCIF_ID =a.NCIF_Id
							                                   AND B.CustomerId=A.CustomerId
							                                   AND B.CustomerACID=A.CustomerACID
       WHERE A.EffectiveFromTimeKey<=@TimeKey
		 AND A.EffectiveToTimeKey>=@TimeKey 


DELETE from dbo.SecurityDistribution_30APR2025DATA Where 
AsOnDate=@ProcessingDate AND NCIF_ID in (Select NCIF_ID FROM SecuFlgImpactedAc)

INSERT INTO dbo.SecurityDistribution_30APR2025DATA (AsOnDate,NCIF_ID,CustomerId,CollateralID,CustomerExposer,CollTotal,CollWiseCustExposure,
AppPER,AppSecurity,CustomerAcID,AccountPOS,AccountSecPer,AccountAppSecurity)
SELECT @ProcessingDate,NCIF_ID,CustomerId,CollateralID,CustomerExposer,CollTotal,CollWiseCustExposure,
AppPER,AppSecurity,CustomerAcID,AccountPOS,AccountSecPer,AccountAppSecurity
FROM #AccTemp Where  NCIF_ID in (Select NCIF_ID FROM SecuFlgImpactedAc)
  
 ------------------------------------------ Security Erosion -----------------------------------------------------

DECLARE @EXT_Date DATE=(SELECT DATE FROM SysDataMatrix WHERE TimeKey=@TimeKey)
DECLARE @STD_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='STD')
DECLARE @SUB_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='SUB')
DECLARE @LOSS_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='LOS')
DECLARE @DB1_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='DB1')
DECLARE @WRITEOFF_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='WO')

--select @EXT_Date,@STD_Alt_Key,@SUB_Alt_Key,@LOSS_Alt_Key,@DB1_Alt_Key,@WRITEOFF_Alt_Key
 
IF OBJECT_ID('TEMPDB..#Erosion') IS NOT NULL
DROP TABLE #Erosion

IF OBJECT_ID('TEMPDB..#Security') IS NOT NULL
DROP TABLE #Security

IF OBJECT_ID('TEMPDB..#NCIF') IS NOT NULL
DROP TABLE #NCIF

Select NCIF_Id into #NCIF from #NI_Details With (nolock) where EffectiveFromTimeKey=@TimeKey and EffectiveToTimeKey=@TimeKey
ANd isnull(NCIF_AssetClassAlt_Key,1) not in (1,7) ANd SecuredFlag='Y' And IsFunded='Y'  
--AND NCIF_Id=10000759 
Group By NCIF_Id
 
SELECT A.NCIF_Id,SUM(PrincipleOutstanding) PrincipleOutstanding,SUM(SecurityValue) SecurityValue
INTO #Security
FROM #NI_Details A With (nolock)
Inner Join #NCIF B ON A.NCIF_Id=B.NCIF_Id
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
GROUP BY A.NCIF_Id



SELECT DISTINCT B.NCIF_Id as RefCustomer_CIF, PrincipleOutstanding,Prev_Value,CurrentValue,
((CurrentValue/Case When Isnull(PrincipleOutstanding,0)=0 then 1 else PrincipleOutstanding end )*100) SecurityCoverPercentage,
(100-(CurrentValue/Case when ISNULL(Prev_Value,0)=0 then 1 else Prev_Value end )*100) SecurityErosionPercentage,

  (CASE WHEN (
             ((CASE WHEN isnull(CurrentValue,0)=0 THEN 0 ELSE (CurrentValue/PrincipleOutstanding) END)*100<10) and LossDT IS null) 
             THEN @LOSS_Alt_Key   
			 WHEN  

  (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And
   ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<=50
AND (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<50
And ((CurrentValue/Case When Isnull(PrincipleOutstanding,0)=0 then 1 else PrincipleOutstanding end )*100)<50

  And NCIF_AssetClassAlt_Key=@SUB_Alt_Key and LossDT IS null and DbtDT IS null  
  THEN @DB1_Alt_Key
    ELSE NCIF_AssetClassAlt_Key
    END) NCIF_AssetClassAlt_Key,
   (CASE WHEN ((CASE WHEN ISNULL(CurrentValue,0)=0 THEN 0  ELSE (CurrentValue/PrincipleOutstanding)END)*100<10
    and LossDT IS null)
      OR
 
((CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<=50  
AND (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<50
And ((CurrentValue/Case When Isnull(PrincipleOutstanding,0)=0 then 1 else PrincipleOutstanding end )*100)<50
  And NCIF_AssetClassAlt_Key=@SUB_Alt_Key) and (LossDT IS  null and DbtDT IS null)
               THEN 'Y'
         END) Erosion_Flag
,(CASE WHEN (CASE WHEN isnull(CurrentValue,0)=0 THEN 0 ELSE (isnull(CurrentValue,0)/isnull(PrincipleOutstanding,0)) END)*100<10
                 and LossDT IS null
                THEN @EXT_Date
       END) LOSS_DATE
          ,

(CASE WHEN (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<50  
 AND (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100>10
And ((CurrentValue/Case When Isnull(PrincipleOutstanding,0)=0 then 1 else PrincipleOutstanding end )*100)<50
  And NCIF_AssetClassAlt_Key=@SUB_Alt_Key
  and (LossDT IS  null and DbtDT IS null)   
         THEN @EXT_Date
          ELSE DbtDT  
END) DBt_Date
INTO #Erosion
FROM
(SELECT RefCustomer_CIF,SUM(Case When ValuationExpiryDate IS NULL OR ValuationExpiryDate='' OR ValuationExpiryDate<@EXT_Date  then  0 Else CurrentValue End) CurrentValue,
SUM(Case When ValuationExpiryDate IS NULL OR ValuationExpiryDate='' OR     DATEADD(DAY,1,ValuationExpiryDate)<@EXT_Date  then  0 Else Prev_Value End) Prev_Value
--SUM(Case When ValuationExpiryDate IS NULL OR ValuationExpiryDate='' OR    ValuationExpiryDate<@EXT_Date  then  0 Else Prev_Value End) Prev_Value
FROM
(SELECT A.RefCustomer_CIF,A.CollateralID,ValuationExpiryDate,MIN(isnull(B.CurrentValue,0)) CurrentValue,MIN(Isnull(B.Prev_Value,0)) Prev_Value
FROM #AdvSecurityDetail A With (nolock)
INNER JOIN #AdvSecurityValueDetail B With (nolock)  ON A.EffectiveFromTimeKey<=@TimeKey
                                   AND A.EffectiveToTimeKey>=@TimeKey
  AND B.EffectiveFromTimeKey<=@Timekey
                                   AND B.EffectiveToTimeKey>=@TimeKey
                                   AND A.SecurityEntityID=B.SecurityEntityID


GROUP BY RefCustomer_CIF,A.CollateralID,ValuationExpiryDate) A
GROUP BY RefCustomer_CIF) A

Right JOIN

(SELECT A.NCIF_Id,MIN(LossDT) LossDT,MIN(DbtDT) DbtDT,MAX(NCIF_AssetClassAlt_Key) NCIF_AssetClassAlt_Key,SUM(isnull(Balance,0)) Balance,
SUM(isnull(PrincipleOutstanding,0))PrincipleOutstanding  
FROM #NI_Details A With (nolock)
WHERE EffectiveFromTimeKey<=@Timekey
AND EffectiveToTimeKey>=@Timekey
AND SecuredFlag='Y'
AND IsFunded='Y'
AND isnull(NCIF_AssetClassAlt_Key,1) NOT IN(@LOSS_Alt_Key,@WRITEOFF_Alt_Key)  
GROUP BY A.NCIF_Id) B ON A.RefCustomer_CIF=B.NCIF_Id
INNER JOIN #NCIF C on B.NCIF_Id=C.NCIF_Id
WHERE (ISNULL(A.CurrentValue,0)>=0 OR ISNULL(Prev_Value,0)>=0 )
AND ISNULL(B.PrincipleOutstanding,0)>0
AND ISNULL(B.PrincipleOutstanding,0)> ISNULL(A.CurrentValue,0)


--select * from #erosion

UPDATE  NID SET NCIF_AssetClassAlt_Key=A.NCIF_AssetClassAlt_Key,
                FlgErosion=A.Erosion_Flag,
				DbtDT=A.DBt_Date,
				LossDT=A.LOSS_DATE,
				ErosionDT=(case when A.Erosion_Flag='Y' then @EXT_Date else Null End)
FROm #Erosion A
INNER JOIN #NI_Details NID ON NID.EffectiveFromTimeKey<=@Timekey 
                                     AND NID.EffectiveToTimeKey>=@Timekey          
                                     AND NID.NCIF_Id =A.RefCustomer_CIF 
/*WHERE NID.NCIF_AssetClassAlt_Key <>@WRITEOFF_Alt_Key */
WHERE NID.NCIF_AssetClassAlt_Key NOT IN(@WRITEOFF_Alt_Key) 
		OR NID.ISTWO<>'Y' 

/*ADDED DUE TO COBORROWER OBSERVATION BY  */ 
UPDATE NID SET NID.NCIF_NPA_DATE=NIDC.NCIF_NPA_Date
				,NID.NatureofClassification='C' 
FROM #NI_Details NID INNER JOIN #NI_Details NIDC  
ON NID.ImpactingAccountNo=NIDC.CustomerACID
WHERE NID.NatureofClassification='D' AND NID.NCIF_NPA_Date IS NULL
									 AND NID.FlgErosion='Y'
                                     AND (NID.EffectiveFROMTimeKey<=@Timekey           
									 AND NID.EffectiveToTimeKey>=@Timekey)          
									 AND (NIDC.EffectiveToTimeKey>=@Timekey         
									 AND NIDC.EffectiveFROMTimeKey<=@Timekey)          
									 									 
----------------------------------- Provision Computation -----------------------------------------									  
DECLARE @Ext_DATE_1 DATE =(SELECT dateadd(dd,1,DATE) FROM SysDataMatrix WHERE TimeKey=@TimeKey)--APPLIED ON PROD 20231005 FOR BORDER DATE OBSERVATION 
DECLARE @Prol Smallint=(SELECT SourceAlt_Key FROM DimSourceSystem WHERE SourceName='Prolendz' AND EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @Fin Smallint=(SELECT SourceAlt_Key FROM DimSourceSystem WHERE SourceName='Finacle' AND EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)

DECLARE @DB2_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='DB2')
DECLARE @DB3_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='DB3') 

DECLARE @STDGEN smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='STDGEN' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @SUBGEN smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='SUBGEN' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @SUBABINT smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='SUBABINT' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB1GEN smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB1GEN' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB1PROL smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB1PROL' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB2GEN smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB2GEN' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB2PROL smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB2PROL' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB3 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB3' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @LOSS smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='LOSS' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @FITL smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='FITL' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @FINCAA smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='FINCAA' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @FIN890 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='FIN890' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB1PROL_35 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB1PROL_35' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @SUBPROL_35 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='SUBPROL_35' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB1PROL_40 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB1PROL_40' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB1PROL_45 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB1PROL_45' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB2PROL_50 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB2PROL_50' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB2PROL_60 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB2PROL_60' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB2PROL_70 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB2PROL_70' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
 
UPDATE A SET   
ProvisionAlt_Key=(CASE WHEN IsFITL='Y' THEN @FITL
                       --WHEN SrcSysAlt_Key=@Fin AND ProductCode='CAA' THEN @FINCAA
					   WHEN SrcSysAlt_Key=@Fin AND FacilityType='CAA' THEN @FINCAA -----Changed 15-06-2021 by sunil
			           WHEN  SrcSysAlt_Key=@Fin AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key AND ProductCode in ('OD890','OD896') THEN @FIN890 END)
	FROM #NI_Details A --ADDED ON PROD 20230922 
	WHERE  NCIF_AssetClassAlt_Key<>@STD_Alt_Key --ADDED ON PROD 20230922 

PRINT 'EXCEPTIONAL PROVISIONAL CASES COMPLETED' --ADDED ON PROD 20230922

/*ADDED ON BY ZAIN 20230705 ADDED ON PROD 20230922 PROVISION CALCULATION*/
/* SCHEME_CODE IS NOT NULL */
UPDATE  NID SET NID.ProvisionAlt_Key = DPP.ProvisionAlt_key
FROM #NI_Details NID  
INNER JOIN DIMPROVISIONPOLICY DPP ON DPP.Scheme_Code=NID.ProductCode
										AND DPP.Source_Alt_Key=NID.SrcSysAlt_Key
		--AND (DPP.SEGMENT IS NOT NULL) AND DPP.SCHEME_CODE IS NOT NULL ) CHANGED AS PER BANK REQUESTED 20230810 BY ZAIN
		 AND DPP.EffectiveFromTimeKey<=@TIMEKEY
                          AND DPP.EffectiveToTimeKey>=@TIMEKEY 
		WHERE  NID.NCIF_AssetClassAlt_Key<>@STD_ALT_KEY 
		AND NID.ProvisionAlt_Key IS NULL
PRINT ' SCHEME_CODE IS NOT NULL '		
 
/* SCHEME_CODE IS  NULL *//*ADDED ON BY ZAIN 20230705 ADDED ON PROD 20230922 PROVISION CALCULATION*/
		UPDATE  NID SET NID.ProvisionAlt_Key = DPP.ProvisionAlt_key
		FROM #NI_Details NID  
		INNER JOIN DIMPROVISIONPOLICY DPP ON DPP.Source_Alt_Key=NID.SrcSysAlt_Key
			AND (ISNULL(DPP.SCHEME_CODE,'')='')--ISNULL(DPP.SEGMENT,'')='' AND --CHANGED AS PER BANK REQUESTED 20230810 BY ZAIN
			 AND DPP.EffectiveFromTimeKey<=@TimeKey
			                  AND DPP.EffectiveToTimeKey>=@TimeKey 
		WHERE NID.NCIF_AssetClassAlt_Key<>@STD_Alt_Key 
							AND NID.ProvisionAlt_Key IS NULL


/*ADDED ON BY ZAIN 20230831 ADDED ON PROD 20230922 PROVISION CALCULATION */
UPDATE A SET   
ProvisionAlt_Key=(CASE WHEN NCIF_AssetClassAlt_Key=@SUB_Alt_Key
			                THEN (CASE WHEN SrcSysAlt_Key=@Prol and ProductCode IN('D_R','E_R','L_R') THEN @SUBGEN--@SUBPROL_35 CHANGED ON 20230831 BY ZAIN
							           WHEN ISNULL(SecuredFlag,'N')='N' THEN @SUBABINT ELSE @SUBGEN END) 
                       WHEN NCIF_AssetClassAlt_Key=@DB1_Alt_Key
					   /*PROVISION FOR THIS PRODUCT CODEIS MOVE TO DIMPROVISIONPOLICY FROMDIMPROVISION COMMENTED ON UAT 20230728 ON PROD 20230922 BY ZAIN*/
		                    THEN (CASE   WHEN SrcSysAlt_Key=@Prol and ProductCode IN('D_R','E_R','L_R') THEN @DB1GEN--DB1PROL CHANGED ON 20230831 BY ZAIN 
									   ELSE @DB1GEN END)
						WHEN NCIF_AssetClassAlt_Key=@DB2_Alt_Key--ADDEDON 20230801
									THEN @DB2GEN --ADDEDON 20230801
						WHEN NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN @DB3
                       WHEN NCIF_AssetClassAlt_Key=@LOSS_Alt_Key
		                    THEN @LOSS
                 ELSE @STDGEN    
                 END)
FROM #NI_Details A 
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key 
AND isnull(A.ProvisionAlt_Key,'') =''--CHANGED ON UAT 20230831 ON PROD 20230922 AND ProvisionAlt_Key IS NULL
 
/*IMPLEMENTATION OF THE ADDED PARAMETER FOR BORDER DATE OBSERVATION ON PROD 20231005 */
UPDATE  NID SET
 Provsecured=(CASE WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=3  THEN ISNULL(SecuredAmt,0)*DPP.upto_3_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>3 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=6) THEN ISNULL(SecuredAmt,0)*DPP.From_4_months_upto_6_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>6 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=9)   THEN ISNULL(SecuredAmt,0)*DPP.From_7_months_upto_9_months
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>9 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=12) THEN ISNULL(SecuredAmt,0)*DPP.From_10_months_upto_12_months
										WHEN NID.NCIF_AssetClassAlt_Key=@DB1_Alt_Key THEN ISNULL(SecuredAmt,0)*DPP.DOUBTFUL_1
										WHEN NID.NCIF_AssetClassAlt_Key=@DB2_Alt_Key THEN ISNULL(SecuredAmt,0)*DPP.DOUBTFUL_2
										WHEN NID.NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN ISNULL(SecuredAmt,0)*DPP.DOUBTFUL_3
										WHEN NID.NCIF_AssetClassAlt_Key=@LOSS_Alt_Key THEN ISNULL(SecuredAmt,0)*DPP.LOSS
										END  ),
--ProvUnsecured=ISNULL(UnSecuredAmt,0)*ISNULL(DPP.ProvisionUnSecured,0),COMMENTED ON 20230731

ProvUnsecured=(CASE WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=3 THEN ISNULL(UnSecuredAmt,0)*DPP.upto_3_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>3 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=6) THEN ISNULL(UnSecuredAmt,0)*DPP.From_4_months_upto_6_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>6 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=9)  THEN ISNULL(UnSecuredAmt,0)*DPP.From_7_months_upto_9_months
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>9 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=12) THEN ISNULL(UnSecuredAmt,0)*DPP.From_10_months_upto_12_months
										WHEN NID.NCIF_AssetClassAlt_Key=@DB1_Alt_Key THEN ISNULL(UnSecuredAmt,0)*DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@DB2_Alt_Key THEN ISNULL(UnSecuredAmt,0)*DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN ISNULL(UnSecuredAmt,0)*DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@LOSS_Alt_Key THEN ISNULL(UnSecuredAmt,0)*DPP.ProvisionUnSecured
				END)
			 
			 FROM #NI_Details NID 
		LEFT JOIN DIMPROVISIONPOLICY DPP ON DPP.ProvisionAlt_Key=NID.ProvisionAlt_Key
		 AND DPP.EffectiveFromTimeKey<=@TimeKey
                          AND DPP.EffectiveToTimeKey>=@TimeKey
						  AND NID.ProvisionAlt_Key=DPP.ProvisionAlt_key 
		WHERE  NID.NCIF_AssetClassAlt_Key<>@STD_Alt_Key 
		AND  (NID.TotalProvision IS NULL OR NID.TotalProvision=0)

--
------------END-----------------------------------------------

UPDATE NID SET
Provsecured=ISNULL(SecuredAmt,0)*ISNULL(DP.ProvisionSecured,0),
ProvUnsecured=ISNULL(UnSecuredAmt,0)*ISNULL(DP.ProvisionUnSecured,0)--,
--TotalProvision=(ISNULL(SecuredAmt,0)*ISNULL(DP.ProvisionSecured,0))+(ISNULL(UnSecuredAmt,0)*ISNULL(DP.ProvisionUnSecured,0))
FROM #NI_Details NID
INNER JOIN DimProvision DP ON DP.EffectiveFromTimeKey<=@TimeKey
                          AND DP.EffectiveToTimeKey>=@TimeKey
						  AND NID.ProvisionAlt_Key=DP.ProvisionAlt_key 
WHERE  NID.NCIF_AssetClassAlt_Key<>@STD_Alt_Key
 AND  NID.IsFunded='Y' 
 AND  (NID.TotalProvision IS NULL OR NID.TotalProvision=0) --ADDED BY ZAIN 20230720 ON UAT 20230922 ON PRODso that the values which was not updated above shouldbe updated


 
DROP TABLE IF EXISTS ##TEMP
 
SELECT CustomerACID,ProductCode,SrcSysAlt_Key,Provsecured,ProvUnSecured,SecuredAmt,UNSecuredAmt,'Y' PROVISION_COMP,
(CASE WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=3  THEN DPP.upto_3_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>3 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=6) THEN DPP.From_4_months_upto_6_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>6 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=9)   THEN DPP.From_7_months_upto_9_months
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>9 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=12) THEN DPP.From_10_months_upto_12_months
										WHEN NID.NCIF_AssetClassAlt_Key=@DB1_Alt_Key THEN DPP.DOUBTFUL_1
										WHEN NID.NCIF_AssetClassAlt_Key=@DB2_Alt_Key THEN DPP.DOUBTFUL_2
										WHEN NID.NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN DPP.DOUBTFUL_3
										WHEN NID.NCIF_AssetClassAlt_Key=@LOSS_Alt_Key THEN DPP.LOSS
										END  ) SEC_PER,
(CASE WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=3 THEN DPP.upto_3_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>3 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=6) THEN DPP.From_4_months_upto_6_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>6 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=9)  THEN DPP.From_7_months_upto_9_months
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>9 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=12) THEN DPP.From_10_months_upto_12_months
										WHEN NID.NCIF_AssetClassAlt_Key=@DB1_Alt_Key THEN DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@DB2_Alt_Key THEN DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@LOSS_Alt_Key THEN DPP.ProvisionUnSecured
				END) UNSEC_PER 
INTO ##TEMP FROM #NI_Details NID  
INNER JOIN DIMPROVISIONPOLICY DPP ON NID.ProductCode=DPP.Scheme_Code 
and DPP.EffectiveFromTimeKey<=@TimeKey and DPP.EffectiveToTimeKey>=@TimeKey
WHERE DPP.Scheme_Code IS NOT NULL AND IsFunded='Y' AND ISNULL(IsTWO,'N')<>'Y'  
UNION
SELECT CustomerACID,ProductCode,SrcSysAlt_Key,Provsecured,ProvUnSecured,SecuredAmt,UNSecuredAmt,'Y' PROVISION_COMP,
(CASE WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=3  THEN DPP.upto_3_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>3 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=6) THEN DPP.From_4_months_upto_6_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>6 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=9)   THEN DPP.From_7_months_upto_9_months
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>9 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=12) THEN DPP.From_10_months_upto_12_months
										WHEN NID.NCIF_AssetClassAlt_Key=@DB1_Alt_Key THEN DPP.DOUBTFUL_1
										WHEN NID.NCIF_AssetClassAlt_Key=@DB2_Alt_Key THEN DPP.DOUBTFUL_2
										WHEN NID.NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN DPP.DOUBTFUL_3
										WHEN NID.NCIF_AssetClassAlt_Key=@LOSS_Alt_Key THEN DPP.LOSS
										END  ) SEC_PER,
(CASE WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=3 THEN DPP.upto_3_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>3 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=6) THEN DPP.From_4_months_upto_6_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>6 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=9)  THEN DPP.From_7_months_upto_9_months
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>9 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=12) THEN DPP.From_10_months_upto_12_months
										WHEN NID.NCIF_AssetClassAlt_Key=@DB1_Alt_Key THEN DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@DB2_Alt_Key THEN DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@LOSS_Alt_Key THEN DPP.ProvisionUnSecured
				END) UNSEC_PER 
FROM #NI_Details NID  
INNER JOIN DIMPROVISIONPOLICY DPP ON NID.SrcSysAlt_Key=DPP.Source_Alt_Key 
and DPP.EffectiveFromTimeKey<=@TimeKey and DPP.EffectiveToTimeKey>=@TimeKey
WHERE DPP.Scheme_Code IS NULL AND IsFunded='Y' AND ISNULL(IsTWO,'N')<>'Y'  
 
INSERT INTO ##TEMP
SELECT NID.CustomerACID,NID.ProductCode,NID.SrcSysAlt_Key,NID.Provsecured,NID.ProvUnSecured,NID.SecuredAmt,NID.UnSecuredAmt,'N' PROVISION_COMP,
DP.ProvisionSecured,DP.ProvisionUnSecured
FROM #NI_Details NID INNER JOIN DimProvision DP ON NID.ProvisionAlt_Key=DP.ProvisionAlt_Key 
AND DP.EffectiveFromTimeKey<=@TIMEKEY AND DP.EffectiveToTimeKey>=@TIMEKEY
LEFT JOIN ##TEMP T ON NID.CustomerACID=T.CustomerACID
WHERE T.CustomerACID IS NULL AND IsFunded='Y' AND ISNULL(IsTWO,'N')<>'Y' 
 
  
				UPDATE T SET PROVISION_COMP='Y'
				FROM ##TEMP T INNER JOIN HISTORY_PROVISIONPOLICY HDP ON T.ProductCode=HDP.Scheme_Code
				WHERE PROVISION_COMP='N' AND HDP.Scheme_Code IS NOT NULL

				UPDATE T SET PROVISION_COMP='Y'
				FROM ##TEMP T INNER JOIN HISTORY_PROVISIONPOLICY HDP ON T.SrcSysAlt_Key=HDP.Source_Alt_Key
				WHERE PROVISION_COMP='N' AND HDP.Scheme_Code IS NULL
	 
 
 UPDATE NID SET NID.Provsecured=(CASE WHEN ISNULL(SEC_PROVPER_OLD,0) >ISNULL(SEC_PER,0)  THEN NID.SecuredAmt*ISNULL(NID.SEC_PROVPER_OLD,0) 
										ELSE NID.Provsecured END ),
				NID.ProvUNsecured= (CASE WHEN ISNULL(UNSEC_PROVPER_OLD,0) >ISNULL(UNSEC_PER,0)  THEN NID.UnSecuredAmt*ISNULL(NID.UNSEC_PROVPER_OLD,0) 
											ELSE NID.ProvUnsecured END )
				FROM #NI_Details NID INNER JOIN ##TEMP T ON NID.CustomerACID=T.CustomerACID 
				WHERE T.PROVISION_COMP='Y'
 
 UPDATE NID SET NID.SEC_PROVPER_OLD=(CASE WHEN ISNULL(SEC_PROVPER_OLD,0) < ISNULL(SEC_PER,0)  THEN SEC_PER   
												ELSE ISNULL(NID.SEC_PROVPER_OLD,0) END ),
				NID.UNSEC_PROVPER_OLD = (CASE WHEN ISNULL(UNSEC_PROVPER_OLD,0) < ISNULL(UNSEC_PER,0)  THEN UNSEC_PER   
												ELSE ISNULL(NID.UNSEC_PROVPER_OLD,0) END)
				FROM #NI_Details NID INNER JOIN ##TEMP T ON NID.CustomerACID=T.CustomerACID 
/***********************/

--UPDATE #NI_Details SET TotalProvision=ISNULL(Provsecured,0)+ISNULL(ProvUnsecured,0) 
--WHERE EffectiveFromTimeKey<=@TIMEKEY AND EffectiveFromTimeKey>=@TIMEKEY

UPDATE NID SET TotalProvision=ISNULL(Provsecured,0)+ISNULL(ProvUnsecured,0) 
From #NI_Details NID  


UPDATE NID
SET TotalProvision= CASE WHEN (ISNULL(NID.PrincipleOutstanding,0)* ISNULL(AP.AccProvPer,0))/100>(ISNULL(NID.TotalProvision,0)+
																(CASE WHEN ISNULL(NID.AddlProvisionPer,0)>0
																	THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.PrincipleOutstanding,0))/100
																	-- THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.TotalProvision,0))/100  
																WHEN ISNULL(NID.AddlProvision,0)>0
																THEN ISNULL(NID.AddlProvision,0)
																ELSE 0
																END))
                              THEN (ISNULL(NID.PrincipleOutstanding,0)* ISNULL(AP.AccProvPer,0))/100 
					     ELSE (ISNULL(NID.TotalProvision,0)+(CASE WHEN ISNULL(NID.AddlProvisionPer,0)>0
																	   THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.PrincipleOutstanding,0))/100
																	-- THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.TotalProvision,0))/100  
																  WHEN ISNULL(NID.AddlProvision,0)>0
																	   THEN ISNULL(NID.AddlProvision,0)
																  ELSE 0
                                                               END))

				    END,
   AddlProvision=ISNULL(NID.AddlProvision,0) +
                 (CASE WHEN (ISNULL(NID.PrincipleOutstanding,0)* ISNULL(AP.AccProvPer,0))/100>(ISNULL(NID.TotalProvision,0)+(CASE WHEN ISNULL(NID.AddlProvisionPer,0)>0
																								                                       THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.PrincipleOutstanding,0))/100
																																	  -- THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.TotalProvision,0))/100 
																									                              WHEN ISNULL(NID.AddlProvision,0)>0
																									                                   THEN ISNULL(NID.AddlProvision,0)
																									                               ELSE 0
                                                                                                                             END))
                              THEN ((ISNULL(NID.PrincipleOutstanding,0)* ISNULL(AP.AccProvPer,0))/100)-(ISNULL(NID.TotalProvision,0)+(CASE WHEN ISNULL(NID.AddlProvisionPer,0)>0
																								                                      THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.PrincipleOutstanding,0))/100
																																   -- THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.TotalProvision,0))/100 
																									                              WHEN ISNULL(NID.AddlProvision,0)>0
																									                                   THEN ISNULL(NID.AddlProvision,0)
																									                               ELSE 0
                                                                                                                             END)) 
					     ELSE (CASE WHEN ISNULL(NID.AddlProvisionPer,0)>0
										 THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.PrincipleOutstanding,0))/100
										  -- THEN (ISNULL(NID.AddlProvisionPer,0)*ISNULL(NID.TotalProvision,0))/100 
									ELSE 0
                               END)
				  END)
FROM #NI_Details NID
INNER JOIN CurDat.AcceleratedProv_30APR2025DATA AP ON   AP.EffectiveFromTimeKey<=@TimeKey
                             AND AP.EffectiveToTimeKey>=@TimeKey
							 ----AND NID.NCIF_Id=AP.NCIF_Id
							 ---AND NID.CustomerId=AP.CustomerId
							 AND NID.CustomerACID=AP.CustomerACID
							 AND NID.SrcSysAlt_Key=AP.SrcSysAlt_Key 
WHERE  NID.IsFunded='Y'
AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key
 
UPDATE NID SET
STD_ASSET_CAT_Alt_key=900
FROM #NI_Details NID  
WHERE NID.STD_ASSET_CAT_Alt_key is NULL  
AND NID.NCIF_AssetClassAlt_Key=@STD_Alt_Key 
AND ISNULL(Balance,0)>0 -- ADDED ON 20230612 TO AVOID CALCULATION OF 0 AND NEGATIVE BALANCE PROVISION
 AND  NID.IsFunded='Y'
 
UPDATE NID SET
TotalProvision=(ISNULL(Balance,0)*ISNULL(DP.STD_ASSET_CAT_Prov,0))
FROM #NI_Details NID
INNER JOIN DIM_STD_ASSET_CAT DP ON  DP.EffectiveFromTimeKey<=@TimeKey
                          AND DP.EffectiveToTimeKey>=@TimeKey
						  AND NID.STD_ASSET_CAT_Alt_key =DP.STD_ASSET_CATAlt_key 
 
WHERE NID.NCIF_AssetClassAlt_Key=@STD_Alt_Key 
AND ISNULL(Balance,0)>0 -- ADDED ON 20230612 TO AVOID CALCULATION OF 0 AND NEGATIVE BALANCE PROVISION
 AND  NID.IsFunded='Y'

 UPDATE NID SET SEC_PROVPER_OLD=ISNULL(DP.STD_ASSET_CAT_Prov,0),UNSEC_PROVPER_OLD=ISNULL(DP.STD_ASSET_CAT_Prov,0)
 FROM #NI_Details NID
INNER JOIN DIM_STD_ASSET_CAT DP ON DP.EffectiveFromTimeKey<=@TimeKey
                          AND DP.EffectiveToTimeKey>=@TimeKey
						  AND NID.STD_ASSET_CAT_Alt_key =DP.STD_ASSET_CATAlt_key 
WHERE  NID.NCIF_AssetClassAlt_Key=@STD_Alt_Key 
AND ISNULL(Balance,0)>0 -- ADDED ON 20230612 TO AVOID CALCULATION OF 0 AND NEGATIVE BALANCE PROVISION
 AND  NID.IsFunded='Y'



--IF STD RESTRUCTURE THE PROVISION WOULD BE 0 AS IT WOULD BE CALCULATED THROUGH NEW MODULE
UPDATE NID SET
TotalProvision=0
FROM #NI_Details NID 
WHERE  NID.NCIF_AssetClassAlt_Key=@STD_Alt_Key 
AND ISNULL(Balance,0)>0 -- ADDED ON 20230612 TO AVOID CALCULATION OF 0 AND NEGATIVE BALANCE PROVISION
AND  NID.IsFunded='Y' 
AND IsRestructured='Y'

 
	UPDATE A set
		 a.ProvisionAlt_Key     =b.ProvisionAlt_Key
		,a.Provsecured			=b.Provsecured
		,a.ProvUnSecured		=b.ProvUnSecured
		,a.TotalProvision		=b.TotalProvision
		,a.AddlProvision		=b.AddlProvision
		,a.AddlProvisionPer		=b.AddlProvisionPer
		,a.STD_ASSET_CAT_Alt_key=b.STD_ASSET_CAT_Alt_key
		,a.SEC_PROVPER_OLD		=b.SEC_PROVPER_OLD
		,a.UNSEC_PROVPER_OLD	=b.UNSEC_PROVPER_OLD
		,a.FlgProcessing		=b.FlgProcessing			 	 
		,a.SecurityValue		=b.SecurityValue
		,a.SecuredAmt			=b.SecuredAmt	
		,a.UnSecuredAmt			=b.UnSecuredAmt	  
		,a.SecuredFlag			=B.SecuredFlag
		from NPA_IntegrationDetails_30APR2025DATA A Join #NI_Details b on 
		a.NCIF_ID=b.NCIF_ID and a.CustomerId=b.CustomerId and
		a.CustomerACID=b.CustomerACID and A.SrcSysAlt_Key=b.SrcSysAlt_Key and
		a.EffectiveFromTimeKey=b.EffectiveFromTimeKey and a.EffectiveToTimeKey=b.EffectivetoTimeKey
 	 
GO