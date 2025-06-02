SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

--EXEC [dbo].[SP_MainProcess] 26107
CREATE PROCEDURE [dbo].[SP_MainProcess_12082021](@TimeKey Int, @IS_MOC CHAR(1)='N')
AS
BEGIN


EXEC [dbo].[SecurityAppropriation] @TimeKey

EXEC [dbo].[AssetClassDegradation] @TimeKey

EXEC [dbo].[AssetClassUpgradation] @TIMEKEY

--EXEC [dbo].[SecurityErosion]@TimeKey ,@IS_MOC

EXEC [dbo].[ProvisionComputation] @TimeKey,@IS_MOC

EXEC [dbo].[BuyOutProvisionComputation] @TimeKey

END
GO