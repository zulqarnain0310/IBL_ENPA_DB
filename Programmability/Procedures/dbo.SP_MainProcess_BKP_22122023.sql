SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--EXEC [dbo].[SP_MainProcess] 26107
create PROCEDURE [dbo].[SP_MainProcess_BKP_22122023](@TimeKey Int, @IS_MOC CHAR(1)='N')
AS
BEGIN

BEGIN TRY

/* amar - 23060223 - below code added temporary for restructure account updation correction*/
----SELECT * FROM SysDaymatrix WHERE Date='2023-06-22'
IF @TimeKey=26836 ---'2023-06-22'
begin
	UPDATE A
		SET  A.AC_AssetClassAlt_Key= B.AC_AssetClassAlt_Key
			,A.AC_NPA_Date		   = B.AC_NPA_Date
			,A.FlgErosion		   = B.FlgErosion
			,A.ErosionDT		   = B.ErosionDT
			,A.DbtDT			   = B.DbtDT
			,A.LossDT			   = B.LossDT
	FROM NPA_IntegrationDetails  A
		INNER JOIN RestructureDataForCorrection B
			ON A.AccountEntityID =B.AccountEntityID
		where a.EffectiveFromTimeKey=26836 and A.EffectiveToTimeKey=26836
END
		
/*IF(@IS_MOC='Y')
BEGIN
TRUNCATE TABLE MOC

INSERT INTO MOC
SELECT DISTINCT NCIF_ID 
FROM NPA_IntegrationDetails 
WHERE EffectiveFromTimeKey<=@TimeKey 
  AND EffectiveToTimeKey>=@TimeKey 
  AND MOC_Status='Y'
END
EXEC [dbo].[SecurityAppropriation] @TimeKey

EXEC [dbo].[AssetClassDegradation] @TimeKey,@IS_MOC

EXEC [dbo].[AssetClassUpgradation] @TIMEKEY,@IS_MOC 

--EXEC [dbo].[SecurityErosion]@TimeKey ,@IS_MOC

EXEC [dbo].[ProvisionComputation] @TimeKey,@IS_MOC

EXEC [dbo].[BuyOutProvisionComputation] @TimeKey*/

EXEC [dbo].[SecurityAppropriation] @TimeKey

EXEC [dbo].[AssetClassDegradation] @TimeKey

EXEC  [dbo].[SecurityErosion]  @TIMEKEY

EXEC [dbo].[AssetClassUpgradation] @TIMEKEY

EXEC [dbo].[UPGRADION_ACCELATOR_PROVISION] @timekey

EXEC [dbo].[ProvisionComputation] @TimeKey,@IS_MOC

EXEC [dbo].[BuyOutProvisionComputation] @TimeKey

update SysDataMatrix 
set PreProcessingFreeze	='Y'
,PreProcessingFreezeDate=MonthLastDate
,MOC_Initialised = 'Y'
,MOC_InitialisedDt = GETDATE()
where TimeKey = @TimeKey

SELECT 1


END TRY
BEGIN CATCH

IF ERROR_MESSAGE() IS NOT NULL
SELECT -1

END CATCH
END



GO