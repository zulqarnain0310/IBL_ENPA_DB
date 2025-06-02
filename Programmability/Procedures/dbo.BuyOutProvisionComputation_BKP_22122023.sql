SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


-- EXEC [dbo].[ProvisionComputation] 26084
create PROCEDURE [dbo].[BuyOutProvisionComputation_BKP_22122023] (@TimeKey Smallint)
AS
DECLARE @Ext_DATE DATE =(SELECT DATE FROM SysDataMatrix WHERE TimeKey=@TimeKey)

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
DECLARE @DB2GEN smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB2GEN' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @DB3 smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='DB3' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
DECLARE @LOSS smallint=(SELECT ProvisionAlt_Key FROM DimProvision WHERE ProvisionShortName='LOSS' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)


BEGIN TRY
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='BuyOutProvisionComputation' AND [EXT_DATE]=@Ext_DATE AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Ext_DATE,@TimeKey,'BuyOutProvisionComputation',GETDATE()
BEGIN TRAN

UPDATE CURDAT.BuyoutFinalDetails SET
SecuredAmt= (CASE WHEN ISNULL(SecurityValue,0)>ISNULL(PrincipalOutstanding,0)
                          THEN ISNULL(PrincipalOutstanding,0)
                     ELSE ISNULL(SecurityValue,0) 
	             END),
UnSecuredAmt=(CASE WHEN ISNULL(SecurityValue,0)>ISNULL(PrincipalOutstanding,0)
                        THEN 0
                   ELSE ISNULL(PrincipalOutstanding,0)-ISNULL(SecurityValue,0) 
	          END)
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey

UPDATE A SET   
ProvisionAlt_Key=(CASE --WHEN FinalAssetClassAlt_Key=@SUB_Alt_Key THEN @SUBGEN 
						WHEN FinalAssetClassAlt_Key=@SUB_Alt_Key
			                THEN (CASE WHEN ISNULL(SecuredFlag,'N')='N' THEN @SUBABINT ELSE @SUBGEN END)
                       WHEN FinalAssetClassAlt_Key=@DB1_Alt_Key THEN @DB1GEN 
                       WHEN FinalAssetClassAlt_Key=@DB2_Alt_Key THEN @DB2GEN 
                       WHEN FinalAssetClassAlt_Key=@DB3_Alt_Key THEN @DB3
                       WHEN FinalAssetClassAlt_Key=@LOSS_Alt_Key THEN @LOSS
                  ELSE @STDGEN    
                  END)
FROM CURDAT.BuyoutFinalDetails A
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND FinalAssetClassAlt_Key<>@STD_Alt_Key

UPDATE NID SET
Provsecured=ISNULL(SecuredAmt,0)*ISNULL(DP.ProvisionSecured,0),
ProvUnsecured=ISNULL(UnSecuredAmt,0)*ISNULL(DP.ProvisionUnSecured,0),
TotalProvision= CASE WHEN (ISNULL(NID.PrincipalOutstanding,0)* ISNULL(NID.AccProvPer,0))/100>((ISNULL(SecuredAmt,0)*ISNULL(DP.ProvisionSecured,0))+(ISNULL(UnSecuredAmt,0)*ISNULL(DP.ProvisionUnSecured,0)))
                              THEN (ISNULL(NID.PrincipalOutstanding,0)* ISNULL(NID.AccProvPer,0))/100 
					     ELSE ((ISNULL(SecuredAmt,0)*ISNULL(DP.ProvisionSecured,0))+(ISNULL(UnSecuredAmt,0)*ISNULL(DP.ProvisionUnSecured,0)))

				    END,
AddProvision=(CASE WHEN (ISNULL(NID.PrincipalOutstanding,0)* ISNULL(NID.AccProvPer,0))/100>((ISNULL(SecuredAmt,0)*ISNULL(DP.ProvisionSecured,0))+(ISNULL(UnSecuredAmt,0)*ISNULL(DP.ProvisionUnSecured,0)))
                              THEN ((ISNULL(NID.PrincipalOutstanding,0)* ISNULL(NID.AccProvPer,0))/100)-((ISNULL(SecuredAmt,0)*ISNULL(DP.ProvisionSecured,0))+(ISNULL(UnSecuredAmt,0)*ISNULL(DP.ProvisionUnSecured,0))) 
					     ELSE ISNULL(NID.AddProvision,0)
				  END)
FROM CURDAT.BuyoutFinalDetails NID
INNER JOIN DimProvision DP ON NID.EffectiveFromTimeKey<=@TimeKey
                          AND NID.EffectiveToTimeKey>=@TimeKey
						  AND DP.EffectiveFromTimeKey<=@TimeKey
                          AND DP.EffectiveToTimeKey>=@TimeKey
						  AND NID.ProvisionAlt_Key=DP.ProvisionAlt_key
WHERE NID.FinalAssetClassAlt_Key<>@STD_Alt_Key

COMMIT TRAN
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='BuyOutProvisionComputation' AND [EXT_DATE]=@Ext_DATE AND ISNULL([Audit_Flg],0)=0
END TRY
BEGIN CATCH
 DECLARE
   @ErMessage NVARCHAR(2048),
   @ErSeverity INT,
   @ErState INT
 
 SELECT  @ErMessage = ERROR_MESSAGE(),
   @ErSeverity = ERROR_SEVERITY(),
   @ErState = ERROR_STATE()
 
 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )
ROLLBACK TRAN
END CATCH



GO