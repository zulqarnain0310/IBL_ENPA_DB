SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[UserLoginInvokedUpdate]
	(
	 @UserLoginID varchar(20),
	 @LoginPassword varchar(50),
	 @TimeKey INT 
	 ,@Result int =0 Output
	)
AS
--DECLARE
--	@UserLoginID varchar(20)='IBLFM8840',
--	@LoginPassword varchar(50)='Password123',
--	@TimeKey INT=26228, 
--	@Result int =0 Output

  BEGIN
	
    IF NOT EXISTS(SELECT * from DimUserInfo where  (DimUserInfo.EffectiveFromTimeKey    < = @TimeKey   
	                 AND DimUserInfo.EffectiveToTimeKey  > = @TimeKey) AND UserLoginID =  @UserLoginID  AND UserLogged=1  )
			BEGIN
			BEGIN TRAN
			ROLLBACK TRANSACTION
			set @Result = -1
			RETURN -1
	        END
      ELSE
		   BEGIN
		                UPDATE  DimUserInfo         
						SET
      					UserLogged=0
	 					WHERE UserLoginID=@UserLoginID AND
	 					(EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
						
						DECLARE @LocationCode varchar(50)
                        DECLARE @Location varchar(10)
                        DECLARE @Count int
                        Select @LocationCode= UserLocationCode,@Location=UserLocation  From DimUserInfo WHERE UserLoginID=@UserLoginID AND
	 					(EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
						
						if(@Location='HO')
		                BEGIN
		                  Select  @Count=UserLoginCount from DimMaxLoginAllow where UserLocation=@Location
		                END
		                if(@Location='RO')
		                BEGIN
		                   Select  @Count=UserLoginCount from DimMaxLoginAllow where UserLocation=@Location and UserLocationCode=@LocationCode 
		                END
		                if(@Location='BO')
		                BEGIN
		                Select  @Count=UserLoginCount from DimMaxLoginAllow where UserLocation=@Location and UserLocationCode=@LocationCode 
		                END
		                IF (@Count=0)
		                BEGIN
		                SET  @Count = @Count+1
		                END
		                ELSE
		                BEGIN
		                 SET  @Count = @Count-1
		                END
		                
		               -- EXEC sp_UpdateUserAccessCount @LocationCode,@Count,@Location
						set @Result = 1
	 					RETURN 1
			END
			
    END






GO