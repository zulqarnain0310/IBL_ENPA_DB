SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


create PROCEDURE [dbo].[SP_MainProcessing_BKP_22122023]
		@TimeKey Int, 
		@UserLoginId VARCHAR(20),
		@Result		INT=0 OUTPUT
AS
BEGIN
	BEGIN TRY
		EXEC [dbo].[SP_MainProcess] @TimeKey
		update SysDataMatrix 
              set PreProcessingFreeze		= 'Y'
				 ,PreProcessingFreezeBy		= @UserLoginId
                 ,PreProcessingFreezeDate	= MonthLastDate
				 ,MOC_Initialised			= 'Y'
				 ,MOC_InitialisedBY			= @UserLoginId
				 ,MOC_InitialisedDt			= GETDATE()
                          where TimeKey = @TimeKey
		SET @Result=1
		RETURN @Result
		
	END TRY

	BEGIN CATCH
		IF ERROR_MESSAGE() IS NOT NULL
		SELECT -1
		SET @Result=-1
		RETURN @Result
	END CATCH
END



GO