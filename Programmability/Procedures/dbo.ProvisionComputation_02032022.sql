SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


-- EXEC [dbo].[ProvisionComputation] 26084
create PROCEDURE [dbo].[ProvisionComputation_02032022] (@TimeKey Smallint,@IS_MOC CHAR(1)='N')
WITH RECOMPILE
AS
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
Update A Set A.Provsecured =0
			,A.ProvUnsecured = 0
			,A.AddlProvision = (Case When B.CustomerACID Is NOT NUll then 0 else A.AddlProvision end)
			,A.ProvisionAlt_Key=NULL
from NPA_IntegrationDetails A
Inner Join #MOC M ON A.NCIF_Id=M.NCIF_Id
Left Join CURDAT.AcceleratedProv B ON A.NCIF_Id=B.NCIF_Id And A.CustomerId=B.CustomerId And A.CustomerACID=B.CustomerACID
And B.EffectiveFromTimeKey<=@TimeKey And B.EffectiveToTimeKey>=@TimeKey
Where A.EffectiveFromTimeKey<=@TimeKey And A.EffectiveToTimeKey>=@TimeKey

----------

END


UPDATE A SET   
ProvisionAlt_Key=(CASE WHEN IsFITL='Y' THEN @FITL
                       --WHEN SrcSysAlt_Key=@Fin AND ProductCode='CAA' THEN @FINCAA
					   WHEN SrcSysAlt_Key=@Fin AND FacilityType='CAA' THEN @FINCAA -----Changed 15-06-2021 by sunil
			           WHEN  SrcSysAlt_Key=@Fin AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key AND ProductCode in ('OD890','OD896') THEN @FIN890
			           WHEN NCIF_AssetClassAlt_Key=@SUB_Alt_Key
			                THEN (CASE WHEN SrcSysAlt_Key=@Prol and ProductCode IN('C_R','D_R','E_R','G_R','H_R','L_R','S_R','T_R') THEN @SUBPROL_35
							           WHEN ISNULL(SecuredFlag,'N')='N' THEN @SUBABINT ELSE @SUBGEN END) 
                       WHEN NCIF_AssetClassAlt_Key=@DB1_Alt_Key
		                    THEN (CASE WHEN SrcSysAlt_Key=@Prol and ProductCode IN('T','H','G','S','C','T_R','H_R','G_R','S_R','C_R') THEN @DB1PROL 
							           WHEN SrcSysAlt_Key=@Prol and ProductCode IN('D_R','E_R','L_R') THEN @DB1PROL_35
									   ELSE @DB1GEN END)
                       WHEN NCIF_AssetClassAlt_Key=@DB2_Alt_Key
		                    THEN (CASE WHEN SrcSysAlt_Key=@Prol and ProductCode IN('T','H','G','S','C','T_R','H_R','G_R','S_R','C_R') THEN @DB2PROL ELSE @DB2GEN END)
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
							 AND NID.NCIF_Id=AP.NCIF_Id
							 AND NID.CustomerId=AP.CustomerId
							 AND NID.CustomerACID=AP.CustomerACID
							 AND NID.SrcSysAlt_Key=AP.SrcSysAlt_Key
LEFT JOIN #MOC B ON NID.NCIF_Id=B.NCIF_ID 
WHERE NID.NCIF_ID =CASE WHEN @IS_MOC ='Y' THEN B.NCIF_ID ELSE  NID.NCIF_ID END
AND  NID.IsFunded='Y'
AND NCIF_AssetClassAlt_Key<>@STD_Alt_Key

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