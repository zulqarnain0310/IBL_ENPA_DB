SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[SP_MOCProcessing_17082021]
		@TimeKey Int, 
		@IS_MOC CHAR(1)='N',
		@Result		INT=0 OUTPUT
AS
BEGIN
	BEGIN TRY
		EXEC [dbo].[ProvisionComputation] @TimeKey,@IS_MOC
		SET @Result=1
		RETURN @Result
		update SysDataMatrix 
              set MOC_ProcessStatus	='Y'
                 ,MOC_ProcessingDate=MonthLastDate
                          where TimeKey = @TimeKey
	END TRY

	BEGIN CATCH
		IF ERROR_MESSAGE() IS NOT NULL
		SELECT -1
		SET @Result=-1
		RETURN @Result
	END CATCH
END



GO