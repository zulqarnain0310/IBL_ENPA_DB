SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROC [dbo].[UserChangePasswordUpdate]      
     (   @UserLoginID varchar(20),
         @LoginPassword varchar(max),
         @PasswordChangeDate smalldatetime,
         @EffectiveFromTimeKey INT,                         --33
		 @EffectiveToTimeKey INT,
		 @TimeKey smallint ,
		 @Result INT=0 OUTPUT    
	)
AS      
 SET NOCOUNT ON     
DECLARE @ChangePwdDate AS smalldatetime
DECLARE @ChangePwdMax AS INT=0
DECLARE @ChangePwd AS INT=0
DECLARE @PwdExist AS VARCHAR(3) ='N'
DECLARE @maxKey as SMALLINT=0
DECLARE @maxuserEntity as SMALLINT=0
Declare @CurrentLoginDate Date
Declare @PwdResetDate AS smalldatetime



Select @CurrentLoginDate= CurrentLoginDate from DimUserInfo where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey) AND UserLoginID=@UserLoginID

--PRINT 'AALAA'
		IF DATEDIFF(DAY,@CurrentLoginDate,GetDate()) <> 0
		BEGIN
			PRINT -12
		   --RETURN -12 --- User Login Date is prior. Data will not be Saved. Please Close the Application.
		END


DECLARE @PreventPwd AS INT=0
SET @PreventPwd= (SELECT ParameterValue  from DimUserParameters  where  (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey) AND ShortNameEnum='PWDREUSE')

SET @ChangePwdMax=(SELECT ParameterValue  from DimUserParameters  where  (EffectiveFromTimeKey < = @TimeKey  AND EffectiveToTimeKey  > = @TimeKey) AND ShortNameEnum='PWDCHNG')

SET @PwdResetDate=(SELECT ResetDate from DimUserInfo where(EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey) AND UserLoginID=@UserLoginID)

     IF  EXISTS(SELECT 1 from DimUserInfo where  (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey) and UserLoginID = @UserLoginID )
        BEGIN
		------------------------
		
		
		print 'exists'
		 SET @ChangePwdDate  =(SELECT  PasswordChangeDate  from DimUserInfo where UserLoginID =  @UserLoginID AND (EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey))
		 SET @ChangePwd= (SELECT datediff(d,@ChangePwdDate,GETDATE()) AS 'Days')
				SET	@maxKey =(SELECT MAX(SeqNo)  FROM UserPwdChangeHistory WHERE  UserLoginID=@UserLoginID AND Status='True')
		  if @maxKey IS NULL
				BEGIN
				SET @maxKey =0
				END
		    SET @maxuserEntity =(SELECT	@maxKey-MAX(seqno) AS userEntity FROM UserPwdChangeHistory WHERE  UserLoginID=@UserLoginID AND LoginPassword=@LoginPassword AND Status='True') 
	         
	         IF EXISTS(SELECT  1 from UserPwdChangeHistory where UserLoginID =  @UserLoginID and LoginPassword=@LoginPassword AND Status='True')
	           BEGIN
	              SET @PwdExist='Y'
	              print 'PwdExist'
	              print @PwdExist
	           END 
	   

		 ---------------------------
		   IF NOT EXISTS(SELECT  1 from UserPwdChangeHistory where UserLoginID =  @UserLoginID and LoginPassword=@LoginPassword AND Status='True')
				   BEGIN
				    print  'exist 1'
					INSERT INTO UserPwdChangeHistory         
						  (
							UserLoginID	,
							LoginPassword,
							SeqNo,
							PwdChangeTime,
							CreatedBy
						)        
					VALUES        
						  ( 
							@UserLoginID	,
							@LoginPassword,
							@maxKey+1,
							GETDATE(),
							@UserLoginID
							)
				 END
		     ELSE IF @maxuserEntity<@PreventPwd-1 AND @PwdExist='Y'
		         BEGIN
				 print @PwdExist
				 print @maxuserEntity
				 print @PreventPwd
		             ---Password has been reused < no of password restricted for reuse.
		              --print -6
					Set @Result = -8
					--print @Result
					SELECT @Result
				  Return
		            
		         END	
		     ELSE  IF @maxuserEntity >=@PreventPwd
				  BEGIN
		    		
					
					INSERT INTO UserPwdChangeHistory         
						  (
							UserLoginID	,
							LoginPassword,
							SeqNo,
							PwdChangeTime,
							CreatedBy
						)        
					VALUES        
						  ( 
							@UserLoginID	,
							@LoginPassword,
							@maxKey+1,
							GETDATE(),
							@UserLoginID
							)
							SET @PwdExist='Y'
				 END	
		    		ELSE 
		    		SET @PwdExist='Y'
		      
		    	
    --IF @maxuserEntity<@PreventPwd AND @PwdExist='Y'
		  -- BEGIN
		  -- RETURN -6
		  --END
    --  else 
      PRINT '@ChangePwd'
	  PRINT @ChangePwd

	  PRINT '@ChangePwdMax'	  
	  PRINT @ChangePwdMax

      --IF @ChangePwd>@ChangePwdMax --AND @PwdExist='N'  --old
	  IF @ChangePwd>@ChangePwdMax AND @ChangePwdDate>@PwdResetDate
		   BEGIN

			Set @Result = -5
			--print @Result
			SELECT @Result
			Return
		  END

		  --------END---------------
	ELSE
		    BEGIN
	

			--print 'This is Print'
			--print @UserLoginID
			--print @TimeKey
			select * from DimUserInfo
			WHERE UserLoginID=@UserLoginID AND
	 				(EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)

		  		  UPDATE  DimUserInfo  
				         
				  SET
      				LoginPassword=@LoginPassword,
      				PasswordChanged='Y' ,
      				PasswordChangeDate= GETDATE(),
					EffectiveFromTimeKey=@EffectiveFromTimeKey,                         --33
					EffectiveToTimeKey =@EffectiveToTimeKey   ,
					ChangePwdCnt=@ChangePwd          
	 				WHERE UserLoginID=@UserLoginID AND
	 				(EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
	 				 				
	 				Set @Result = 1
					--print @Result
					SELECT @Result
					RETURN	
			END
		END 
        ELSE
  					Set @Result = -2
					--print @Result
					SELECT @Result
					RETURN
  IF @@ERROR <> 0         
   BEGIN        
    ROLLBACK TRANSACTION     
		print 'a1'    
		Set @Result = -1
		--print @Result
		SELECT @Result
		RETURN  
	     
   END        
  COMMIT TRANSACTION        
 --  RETURN 1





GO