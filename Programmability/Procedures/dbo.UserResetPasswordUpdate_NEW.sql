SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE PROC [dbo].[UserResetPasswordUpdate_NEW]      
     (   @UserLoginID varchar(20),
         @LoginPassword varchar(max),
         @ALTERdBy varchar(50),
       	 @EffectiveFromTimeKey INT,                        
		 @EffectiveToTimeKey INT  ,
		 @TimeKey INT  ,
		 @Result INT OUTPUT  
	)
AS      
 SET NOCOUNT ON   
		Declare @CurrentLoginDate Date

		Select @CurrentLoginDate= CurrentLoginDate from DimUserInfo where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey) AND UserLoginID=@ALTERdBy

		--IF DATEDIFF(DAY,@CurrentLoginDate,GetDate()) <> 0
		--BEGIN
		--   return -12 --- User Login Date is prior. Data will not be Saved. Please Close the Application.
		--END   

      BEGIN TRANSACTION        
      UPDATE  DimUserInfo         
      SET
      	LoginPassword=@LoginPassword,
    	ModifyBy=@ALTERdBy,
		EffectiveFromTimeKey=@EffectiveFromTimeKey,                      
		EffectiveToTimeKey =@EffectiveToTimeKey   ,
		DateModified=GETDATE(),
		ResetDate=GETDATE(),
		ChangePwdCnt=0,          
		SuspendedUser='N',
		PasswordChanged='Y',
		Activate='Y' 
	
	

	 	WHERE  
	 	(EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey) and UserLoginID=@UserLoginID
		
  IF @@ERROR <> 0         
   BEGIN        
    ROLLBACK TRANSACTION  
	SET @Result=-1      
    RETURN -1        
   END        
  COMMIT TRANSACTION        
  SET @Result=1
   RETURN 1   

       
      
  
                  
-----


/****** Object:  StoredProcedure [dbo].[ChangeUserPassword]    Script Date: 08/18/2009 18:08:15 ******/
SET ANSI_NULLS ON





GO