SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--SELECT count(1) FROM CURDAT.ACCELERATEDPROV WHERE NCIF_ID IN (SELECT NCIF_ID FROM [dbo].[NPA_PROVISION_20231003_ncif_id]) AND EFFECTIVETOTIMEKEY>=26936
--SELECT * FROM [dbo].[NPA_PROVISION_20231003_ncif_id]
--SELECT count(1) FROM NPA_IntegrationDetails_20230930 --31096332



-- EXEC [dbo].[ProvisionComputation] 26084
CREATE PROCEDURE [dbo].[ProvisionComputation_MOC_OBSERVATION] (@TimeKey Smallint,@IS_MOC CHAR(1)='N')
WITH RECOMPILE
AS
DECLARE @Ext_DATE_1 DATE =(SELECT dateadd(dd,1,DATE) FROM SysDataMatrix WHERE TimeKey=@TimeKey)--APPLIED ON PROD 20231005 FOR BORDER DATE OBSERVATION
DECLARE @Ext_DATE DATE =(SELECT DATE FROM SysDataMatrix WHERE TimeKey=@TimeKey)
DECLARE @Prol Smallint=(SELECT SourceAlt_Key FROM DimSourceSystem WHERE SourceName='Prolendz' AND EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @Fin Smallint=(SELECT SourceAlt_Key FROM DimSourceSystem WHERE SourceName='Finacle' AND EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)

DECLARE @STD_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='STD')
DECLARE @SUB_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='SUB')
DECLARE @LOSS_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='LOS')
DECLARE @DB1_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='DB1')
DECLARE @DB2_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='DB2')
DECLARE @DB3_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='DB3')
DECLARE @WRITEOFF_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='WO')

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

BEGIN TRY

DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='ProvisionComputation' AND [EXT_DATE]=@Ext_DATE AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Ext_DATE,@TimeKey,'ProvisionComputation',GETDATE()
BEGIN TRAN

IF OBJECT_ID('TEMPDB..#MOC') IS NOT NULL
DROP TABLE #MOC

CREATE TABLE #MOC(NCIF_Id VARCHAR(100))



IF(@IS_MOC='Y')
BEGIN

INSERT INTO #MOC(NCIF_Id)
SELECT DISTINCT NCIF_Id 
FROM NPA_IntegrationDetails
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND ISNULL(FlgProcessing,'N')='Y'

-----------------Initialize provision columns for MOC Ncifs  18-07-2021

--Select 
IF(@IS_MOC='Y')
BEGIN
Update A Set A.Provsecured =0
			,A.ProvUnsecured = 0
			,A.AddlProvision = (Case When B.CustomerACID Is NOT NUll then 0 else A.AddlProvision end)
			,A.ProvisionAlt_Key=NULL
			,A.TotalProvision = Null                   ---20231007
from NPA_IntegrationDetails A
Inner Join #MOC M ON A.NCIF_Id=M.NCIF_Id
---Left Join CURDAT.ACCELERATEDPROV B ON A.NCIF_Id=B.NCIF_Id And A.CustomerId=B.CustomerId And A.CustomerACID=B.CustomerACID
Left Join CURDAT.ACCELERATEDPROV B ON A.CustomerACID=B.CustomerACID--Chnage on 2/2/22
And B.EffectiveFromTimeKey<=@TimeKey And B.EffectiveToTimeKey>=@TimeKey
Where A.EffectiveFromTimeKey<=@TimeKey And A.EffectiveToTimeKey>=@TimeKey
END

IF(@IS_MOC<>'Y')
BEGIN
Update A Set A.Provsecured =0
			,A.ProvUnsecured = 0
			,A.AddlProvision = (Case When B.CustomerACID Is NOT NUll then 0 else A.AddlProvision end)
			,A.ProvisionAlt_Key=NULL
			,A.TotalProvision = Null                   ---20231007
from NPA_IntegrationDetails A
--Inner Join #MOC M ON A.NCIF_Id=M.NCIF_Id
---Left Join CURDAT.ACCELERATEDPROV B ON A.NCIF_Id=B.NCIF_Id And A.CustomerId=B.CustomerId And A.CustomerACID=B.CustomerACID
Left Join CURDAT.ACCELERATEDPROV B ON A.CustomerACID=B.CustomerACID--Chnage on 2/2/22
And B.EffectiveFromTimeKey<=@TimeKey And B.EffectiveToTimeKey>=@TimeKey
Where A.EffectiveFromTimeKey<=@TimeKey And A.EffectiveToTimeKey>=@TimeKey
END

----------

END


UPDATE A SET   
ProvisionAlt_Key=(CASE WHEN IsFITL='Y' THEN @FITL
                       --WHEN SrcSysAlt_Key=@Fin AND ProductCode='CAA' THEN @FINCAA
					   WHEN SrcSysAlt_Key=@Fin AND FacilityType='CAA' THEN @FINCAA -----Changed 15-06-2021 by sunil
			           WHEN  SrcSysAlt_Key=@Fin AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key AND ProductCode in ('OD890','OD896') THEN @FIN890 END)
	FROM NPA_IntegrationDetails A --ADDED ON PROD 20230922
	LEFT JOIN #MOC B ON A.NCIF_Id=B.NCIF_ID --ADDED ON PROD 20230922
	WHERE EffectiveFromTimeKey<=@TimeKey --ADDED ON PROD 20230922
	AND EffectiveToTimeKey>=@TimeKey --ADDED ON PROD 20230922
	AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key --ADDED ON PROD 20230922
	AND A.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  A.NCIF_ID END --ADDED ON PROD 20230922
PRINT 'EXCEPTIONAL PROVISIONAL CASES COMPLETED' --ADDED ON PROD 20230922

/*ADDED ON BY ZAIN 20230705 ADDED ON PROD 20230922 PROVISION CALCULATION*/
/* SCHEME_CODE IS NOT NULL */
UPDATE  NID SET NID.ProvisionAlt_Key = DPP.ProvisionAlt_key
FROM NPA_IntegrationDetails NID  
INNER JOIN DIMPROVISIONPOLICY DPP ON DPP.Scheme_Code=NID.ProductCode
										AND DPP.Source_Alt_Key=NID.SrcSysAlt_Key
		--AND (DPP.SEGMENT IS NOT NULL) AND DPP.SCHEME_CODE IS NOT NULL ) CHANGED AS PER BANK REQUESTED 20230810 BY ZAIN
		AND NID.EffectiveFromTimeKey<=@TIMEKEY
                          AND NID.EffectiveToTimeKey>=@TIMEKEY
						  AND DPP.EffectiveFromTimeKey<=@TIMEKEY
                          AND DPP.EffectiveToTimeKey>=@TIMEKEY
		LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID
		WHERE NID.EffectiveFromTimeKey<=@TIMEKEY
		AND NID.EffectiveToTimeKey>=@TIMEKEY
		AND NID.NCIF_AssetClassAlt_Key<>@STD_ALT_KEY
		AND NID.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  NID.NCIF_ID END
		AND NID.ProvisionAlt_Key IS NULL
PRINT ' SCHEME_CODE IS NOT NULL '		


/*CHANGED AS PER BANK REQUESTED 20230810 BY ZAIN
/*SCHEME_CODE IS  NULL */
UPDATE  NID SET NID.ProvisionAlt_Key = DPP.ProvisionAlt_key
		FROM NPA_IntegrationDetails NID  INNER JOIN  
					DIMSCHEMESEGMENT DSS ON NID.ProductCode=DSS.Scheme_Code		
										AND DSS.Source_Alt_Key=NID.SrcSysAlt_Key
		INNER JOIN DIMPROVISIONPOLICY DPP ON DPP.Segment=DSS.Segment
			AND (DPP.SCHEME_CODE IS NULL )--AND DPP.SEGMENT IS NOT  NULL )CHANGED AS PER BANK REQUESTED 20230810 BY ZAIN
			AND NID.EffectiveFromTimeKey<=@TIMEKEY
			                  AND NID.EffectiveToTimeKey>=@TIMEKEY
							  AND DPP.EffectiveFromTimeKey<=@TIMEKEY
			                  AND DPP.EffectiveToTimeKey>=@TIMEKEY
		LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID
		WHERE NID.EffectiveFromTimeKey<=@TIMEKEY
			AND NID.EffectiveToTimeKey>=@TIMEKEY
			AND NID.NCIF_AssetClassAlt_Key<>@STD_ALT_KEY
			AND NID.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  NID.NCIF_ID END
			AND NID.ProvisionAlt_Key IS NULL


/*FOR SCHEME_CODE IS NOT NULL AND SEGMENT IS NULL ADDED 20230801 FOR PROLENDZ WITH SCHEME_CODE*/
UPDATE  NID SET NID.ProvisionAlt_Key = DPP.ProvisionAlt_key
	FROM NPA_IntegrationDetails NID  INNER JOIN  
					DIMSCHEMESEGMENT DSS ON NID.ProductCode=DSS.Scheme_Code		
										AND DSS.Source_Alt_Key=NID.SrcSysAlt_Key
		INNER JOIN DIMPROVISIONPOLICY DPP ON DPP.Scheme_Code=DSS.Scheme_Code
			AND (DPP.SCHEME_CODE IS NOT NULL AND DPP.SEGMENT IS NULL )
			AND NID.EffectiveFromTimeKey<=@TimeKey
			                  AND NID.EffectiveToTimeKey>=@TimeKey
							  AND DPP.EffectiveFromTimeKey<=@TimeKey
			                  AND DPP.EffectiveToTimeKey>=@TimeKey
		LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID
		WHERE NID.EffectiveFromTimeKey<=@TimeKey
			AND NID.EffectiveToTimeKey>=@TimeKey
			AND NID.NCIF_AssetClassAlt_Key<>@STD_Alt_Key
			AND NID.NCIF_ID = NID.NCIF_ID 
			AND NID.ProvisionAlt_Key IS NULL

PRINT '1'
*/
/* SCHEME_CODE IS  NULL *//*ADDED ON BY ZAIN 20230705 ADDED ON PROD 20230922 PROVISION CALCULATION*/
		UPDATE  NID SET NID.ProvisionAlt_Key = DPP.ProvisionAlt_key
		FROM NPA_IntegrationDetails NID  
		INNER JOIN DIMPROVISIONPOLICY DPP ON DPP.Source_Alt_Key=NID.SrcSysAlt_Key
			AND (ISNULL(DPP.SCHEME_CODE,'')='')--ISNULL(DPP.SEGMENT,'')='' AND --CHANGED AS PER BANK REQUESTED 20230810 BY ZAIN
			AND NID.EffectiveFromTimeKey<=@TimeKey
			                  AND NID.EffectiveToTimeKey>=@TimeKey
							  AND DPP.EffectiveFromTimeKey<=@TimeKey
			                  AND DPP.EffectiveToTimeKey>=@TimeKey
		LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID
		WHERE NID.EffectiveFromTimeKey<=@TimeKey
							AND NID.EffectiveToTimeKey>=@TimeKey
							AND NID.NCIF_AssetClassAlt_Key<>@STD_Alt_Key
							AND NID.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  NID.NCIF_ID END
							AND NID.ProvisionAlt_Key IS NULL


/*ADDED ON BY ZAIN 20230831 ADDED ON PROD 20230922 PROVISION CALCULATION */
UPDATE A SET   
ProvisionAlt_Key=(CASE /*WHEN IsFITL='Y' THEN @FITL
                       --WHEN SrcSysAlt_Key=@Fin AND ProductCode='CAA' THEN @FINCAA
					   WHEN SrcSysAlt_Key=@Fin AND FacilityType='CAA' THEN @FINCAA -----Changed 15-06-2021 by sunil
			           WHEN  SrcSysAlt_Key=@Fin AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key AND ProductCode in ('OD890','OD896') THEN @FIN890 END)*/ --WORKING SHIFTED TO LINE NUMBER 91
							WHEN NCIF_AssetClassAlt_Key=@SUB_Alt_Key
			                --THEN (CASE WHEN SrcSysAlt_Key=@Prol and ProductCode IN('C_R','D_R','E_R','G_R','H_R','L_R','S_R','T_R') THEN @SUBPROL_35 COMMENTED ON 20230728  BY ZAIN
							THEN (CASE WHEN SrcSysAlt_Key=@Prol and ProductCode IN('D_R','E_R','L_R') THEN @SUBGEN--@SUBPROL_35 CHANGED ON 20230831 BY ZAIN
							           WHEN ISNULL(SecuredFlag,'N')='N' THEN @SUBABINT ELSE @SUBGEN END) 
                       WHEN NCIF_AssetClassAlt_Key=@DB1_Alt_Key
					   /*PROVISION FOR THIS PRODUCT CODEIS MOVE TO DIMPROVISIONPOLICY FROMDIMPROVISION COMMENTED ON UAT 20230728 ON PROD 20230922 BY ZAIN*/
		                    THEN (CASE --WHEN SrcSysAlt_Key=@Prol and ProductCode IN('H','S','H_R','S_R') And NCIF_NPA_Date>'2020-12-31'  THEN @DB1PROL_40  
										--WHEN SrcSysAlt_Key=@Prol and ProductCode IN('G','T_R','G_R','T') And NCIF_NPA_Date>'2020-12-31'  THEN @DB1PROL_45 
										--WHEN SrcSysAlt_Key=@Prol and ProductCode IN('H','S','H_R','S_R') And NCIF_NPA_Date <= '2020-12-31'  THEN @DB1PROL 
										--WHEN SrcSysAlt_Key=@Prol and ProductCode IN('G','T_R','G_R','T') And NCIF_NPA_Date <= '2020-12-31'  THEN @DB1PROL 
							   --         WHEN SrcSysAlt_Key=@Prol and ProductCode IN('C','C_R') And NCIF_NPA_Date > '2020-12-31' THEN @DB1PROL_35
									 --   WHEN SrcSysAlt_Key=@Prol and ProductCode IN('C','C_R') And NCIF_NPA_Date <= '2020-12-31' THEN @DB1PROL
									  WHEN SrcSysAlt_Key=@Prol and ProductCode IN('D_R','E_R','L_R') THEN @DB1GEN--DB1PROL CHANGED ON 20230831 BY ZAIN 
									   ELSE @DB1GEN END)
/*ON PROD 20230922 */									   
--                       WHEN NCIF_AssetClassAlt_Key=@DB2_Alt_Key
		          --          --THEN (CASE WHEN SrcSysAlt_Key=@Prol and ProductCode IN('H','S','H_R','S_R') And NCIF_NPA_Date>'2020-12-31'  THEN @DB2PROL_70   COMMENTED ON 20230728  BY ZAIN
							     ----      WHEN SrcSysAlt_Key=@Prol and ProductCode IN('H','S','H_R','S_R') And NCIF_NPA_Date <='2020-12-31'  THEN @DB2PROL 	 COMMENTED ON 20230728  BY ZAIN
									   ----WHEN SrcSysAlt_Key=@Prol and ProductCode IN('G','T_R','G_R','T') And NCIF_NPA_Date>'2020-12-31'  THEN @DB2PROL_60	 COMMENTED ON 20230728  BY ZAIN
									   ---- WHEN SrcSysAlt_Key=@Prol and ProductCode IN('G','T_R','G_R','T') And NCIF_NPA_Date <='2020-12-31'  THEN @DB2PROL	 COMMENTED ON 20230728  BY ZAIN
									   ----WHEN SrcSysAlt_Key=@Prol and ProductCode IN('C_R','C') And NCIF_NPA_Date>'2020-12-31'  THEN @DB2PROL_50			 COMMENTED ON 20230728  BY ZAIN
									   ----WHEN SrcSysAlt_Key=@Prol and ProductCode IN('C_R','C') And NCIF_NPA_Date<='2020-12-31'  THEN @DB2PROL				 COMMENTED ON 20230728  BY ZAIN
						WHEN NCIF_AssetClassAlt_Key=@DB2_Alt_Key--ADDEDON 20230801
									THEN @DB2GEN --ADDEDON 20230801
						WHEN NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN @DB3
                       WHEN NCIF_AssetClassAlt_Key=@LOSS_Alt_Key
		                    THEN @LOSS
                 ELSE @STDGEN    
                 END)
FROM NPA_IntegrationDetails A
LEFT JOIN #MOC B ON A.NCIF_Id=B.NCIF_ID
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key
AND A.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  A.NCIF_ID END
AND isnull(A.ProvisionAlt_Key,'') =''--CHANGED ON UAT 20230831 ON PROD 20230922 AND ProvisionAlt_Key IS NULL






--CHANGED 20230825 ON UAT 20230922 ON PROD BY ZAIN
--20230830 CHANGE ON UAT 20230922 ON PROD FROM GETDATE IN DATE DIFF EXPRESSION TO @EXT_DATE VARIABLE IN THIS WHOLE BLOCK

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
				END),

TotalProvision=(CASE WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=3  THEN ISNULL(SecuredAmt,0)*DPP.upto_3_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>3 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=6) THEN ISNULL(SecuredAmt,0)*DPP.From_4_months_upto_6_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>6 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=9)   THEN ISNULL(SecuredAmt,0)*DPP.From_7_months_upto_9_months
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>9 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=12) THEN ISNULL(SecuredAmt,0)*DPP.From_10_months_upto_12_months
										WHEN NID.NCIF_AssetClassAlt_Key=@DB1_Alt_Key THEN ISNULL(SecuredAmt,0)*DPP.DOUBTFUL_1
										WHEN NID.NCIF_AssetClassAlt_Key=@DB2_Alt_Key THEN ISNULL(SecuredAmt,0)*DPP.DOUBTFUL_2
										WHEN NID.NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN ISNULL(SecuredAmt,0)*DPP.DOUBTFUL_3
										WHEN NID.NCIF_AssetClassAlt_Key=@LOSS_Alt_Key THEN ISNULL(SecuredAmt,0)*DPP.LOSS
										END )
										+
										((CASE WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=3  THEN ISNULL(UnSecuredAmt,0)*DPP.upto_3_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>3 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=6) THEN ISNULL(UnSecuredAmt,0)*DPP.From_4_months_upto_6_months 
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>6 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=9)   THEN ISNULL(UnSecuredAmt,0)*DPP.From_7_months_upto_9_months
										WHEN NID.NCIF_AssetClassAlt_Key=@SUB_Alt_Key AND ((SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))>9 AND (SELECT dbo.FullMonthsSeparation(@Ext_DATE_1, NID.NCIF_NPA_Date))<=12) THEN ISNULL(UnSecuredAmt,0)*DPP.From_10_months_upto_12_months
										WHEN NID.NCIF_AssetClassAlt_Key=@DB1_Alt_Key THEN ISNULL(UnSecuredAmt,0)*DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@DB2_Alt_Key THEN ISNULL(UnSecuredAmt,0)*DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@DB3_Alt_Key THEN ISNULL(UnSecuredAmt,0)*DPP.ProvisionUnSecured
										WHEN NID.NCIF_AssetClassAlt_Key=@LOSS_Alt_Key THEN ISNULL(UnSecuredAmt,0)*DPP.ProvisionUnSecured
				END))
		FROM NPA_IntegrationDetails NID 
		LEFT JOIN DIMPROVISIONPOLICY DPP ON DPP.ProvisionAlt_Key=NID.ProvisionAlt_Key

		AND NID.EffectiveFromTimeKey<=@TimeKey
                          AND NID.EffectiveToTimeKey>=@TimeKey
						  AND DPP.EffectiveFromTimeKey<=@TimeKey
                          AND DPP.EffectiveToTimeKey>=@TimeKey
						  AND NID.ProvisionAlt_Key=DPP.ProvisionAlt_key
		LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID
		WHERE NID.EffectiveFromTimeKey<=@TimeKey
		AND NID.EffectiveToTimeKey>=@TimeKey
		AND NID.NCIF_AssetClassAlt_Key<>@STD_Alt_Key
		AND NID.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  NID.NCIF_ID END
		AND  (NID.TotalProvision IS NULL OR NID.TotalProvision=0)

--------------END-----------------------------------------------

UPDATE NID SET
Provsecured=ISNULL(SecuredAmt,0)*ISNULL(DP.ProvisionSecured,0),
ProvUnsecured=ISNULL(UnSecuredAmt,0)*ISNULL(DP.ProvisionUnSecured,0),
TotalProvision=(ISNULL(SecuredAmt,0)*ISNULL(DP.ProvisionSecured,0))+(ISNULL(UnSecuredAmt,0)*ISNULL(DP.ProvisionUnSecured,0))
FROM NPA_IntegrationDetails NID
INNER JOIN DimProvision DP ON NID.EffectiveFromTimeKey<=@TimeKey
                          AND NID.EffectiveToTimeKey>=@TimeKey
						  AND DP.EffectiveFromTimeKey<=@TimeKey
                          AND DP.EffectiveToTimeKey>=@TimeKey
						  AND NID.ProvisionAlt_Key=DP.ProvisionAlt_key
LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID
WHERE NID.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  NID.NCIF_ID END
AND NID.NCIF_AssetClassAlt_Key<>@STD_Alt_Key
 AND  NID.IsFunded='Y' 
 AND  (NID.TotalProvision IS NULL OR NID.TotalProvision=0) --ADDED BY ZAIN 20230720 ON UAT 20230922 ON PRODso that the values which was not updated above shouldbe updated



UPDATE NID
SET TotalProvision= CASE WHEN (ISNULL(NID.PrincipleOutstanding,0)* ISNULL(AP.AccProvPer,0))/100>(ISNULL(NID.TotalProvision,0)+(CASE WHEN ISNULL(NID.AddlProvisionPer,0)>0
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
FROM NPA_IntegrationDetails NID
INNER JOIN [CurDat].AcceleratedProv AP ON NID.EffectiveFromTimeKey<=@TimeKey
                             AND NID.EffectiveToTimeKey>=@TimeKey
							 AND AP.EffectiveFromTimeKey<=@TimeKey
                             AND AP.EffectiveToTimeKey>=@TimeKey
							 ----AND NID.NCIF_Id=AP.NCIF_Id
							 ---AND NID.CustomerId=AP.CustomerId
							 AND NID.CustomerACID=AP.CustomerACID
							 AND NID.SrcSysAlt_Key=AP.SrcSysAlt_Key
LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID 
WHERE NID.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  NID.NCIF_ID END
AND  NID.IsFunded='Y'
AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key


--STD PROVISION CALCULATION 1ST UPDATE ON UAT 20230612 DEPLOYED ON PROD 20230707

UPDATE NID SET
TotalProvision=(ISNULL(Balance,0)*ISNULL(DP.STD_ASSET_CAT_Prov,0))
FROM NPA_IntegrationDetails NID
INNER JOIN DIM_STD_ASSET_CAT DP ON NID.EffectiveFromTimeKey<=@TimeKey
                          AND NID.EffectiveToTimeKey>=@TimeKey
						  AND DP.EffectiveFromTimeKey<=@TimeKey
                          AND DP.EffectiveToTimeKey>=@TimeKey
						  AND NID.STD_ASSET_CAT_Alt_key=DP.STD_ASSET_CATAlt_key
LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID
WHERE NID.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  NID.NCIF_ID END
AND NID.NCIF_AssetClassAlt_Key=@STD_Alt_Key 
AND ISNULL(Balance,0)>0 -- ADDED ON 20230612 TO AVOID CALCULATION OF 0 AND NEGATIVE BALANCE PROVISION
 AND  NID.IsFunded='Y'



--IF STD RESTRUCTURE THE PROVISION WOULD BE 0 AS IT WOULD BE CALCULATED THROUGH NEW MODULE
UPDATE NID SET
TotalProvision=0
FROM NPA_IntegrationDetails NID
LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID
WHERE NID.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  NID.NCIF_ID END
AND NID.NCIF_AssetClassAlt_Key=@STD_Alt_Key 
AND ISNULL(Balance,0)>0 -- ADDED ON 20230612 TO AVOID CALCULATION OF 0 AND NEGATIVE BALANCE PROVISION
AND  NID.IsFunded='Y'
AND NID.EffectiveFromTimeKey<=@TimeKey
AND NID.EffectiveToTimeKey>=@TimeKey
AND IsRestructured='Y'



--UPDATE Audit Flag
IF(@IS_MOC='Y')
BEGIN

IF OBJECT_ID('TEMPDB..#MOC') IS NOT NULL
DROP TABLE #MOC

UPDATE NPA_IntegrationDetails SET FlgProcessing='N'
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND ISNULL(FlgProcessing,'N')='Y'

END



COMMIT TRAN
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='ProvisionComputation' AND [EXT_DATE]=@Ext_DATE AND ISNULL([Audit_Flg],0)=0
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
WHERE [SP_Name]='ProvisionComputation' AND [EXT_DATE]=@Ext_DATE AND ISNULL([Audit_Flg],0)=0
 
 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )
ROLLBACK TRAN
END CATCH



GO