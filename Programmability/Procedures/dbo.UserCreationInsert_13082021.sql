SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[UserCreationInsert_13082021]
	(
		@UserLoginID	varchar(20),  -- BASE COLUMN
		@EmployeeID varchar(20),			
		@IsEmployee char(1),				
		@UserName	varchar(50),
		@LoginPassword	varchar(max),
		@UserLocation	varchar	(10),
		@UserLocationCode	varchar	(10),
		@UserRoleAlt_Key	smallint,
		@DeptGroupCode varchar(10),
		@DateCreatedmodified smalldatetime, -- COMMON
		@CreatedModifiedBy	varchar	(20),
		@Activate char(1),
		@IsChecker char(1),

		@DesignationAlt_Key int,
		@IsCma char(1),
		@MobileNo varchar(50),
		@Email_ID VARCHAR(50),

		@SecuritQsnAlt_Key SMALLINT,
		@SecurityAns VARCHAR(100),
		@MenuId VARCHAR(1000),		-- COMMON	

		@EffectiveFromTimeKey INT,   -- COMMON                     
		@EffectiveToTimeKey INT  ,   -- COMMON           
		@Flag  INT,					-- COMMON
		@TimeKey SMALLINT,			-- COMMON
		@Result INT=0 OUTPUT		-- COMMON
	)
AS
DECLARE @Entity_Key AS INT,
        @PasswordChanged char(1),
		@CurrentLoginDate Date--- added by shailesh naik on 10/06/2014


	if(@Flag IN(1))
		BEGIN

	--	print 'flag1'
			IF EXISTS (SELECT UserLoginID from  DimUserInfo WHERE UserLoginID= @UserLoginID 
						AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
					)
				BEGIN

					--print '-6'
					Set @Result = -6
					print @Result
					SELECT @Result
					RETURN 
				END
		END

BEGIN TRANSACTION
BEGIN TRY

		  

IF @Flag<>3
	BEGIN

		DECLARE @IsAvailabve CHAR(1)='N'
			,@IsSCD2 CHAR(1)='N'


		IF EXISTS (SELECT UserLoginID from  DimUserInfo WHERE UserLoginID= @UserLoginID 
					AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
				)
		BEGIN

			SET @IsAvailabve='Y'
								
			IF EXISTS(SELECT UserLoginID from  DimUserInfo WHERE UserLoginID= @UserLoginID 
							AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
							AND EffectiveFromTimeKey=@EffectiveFromTimeKey
					)
					
				BEGIN

					UPDATE  DimUserInfo         
						SET	UserLoginID=@UserLoginID,
							UserName=@UserName,
							UserLocation=@UserLocation,
							UserLocationCode=@UserLocationCode,
							UserRoleAlt_Key=@UserRoleAlt_Key	,
      						LoginPassword=@LoginPassword,
      						IsChecker=@IsChecker,
      						Activate=@Activate,
							DeptGroupCode=@DeptGroupCode,

							Email_ID=@Email_ID,	--ad4
							MobileNo=@MobileNo,
							DesignationAlt_Key=@DesignationAlt_Key,
							IsCma = @isCma
						WHERE UserLoginID=@UserLoginID
							AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey
							AND EffectiveFromTimeKey=@EffectiveFromTimeKey
				END
			ELSE
				BEGIN
					SET @IsSCD2='Y'
				END
				
				
		END

		IF ( @IsSCD2='Y')
			BEGIN

				INSERT INTO DimUserInfo         
					(
						UserLoginID
						,EmployeeID 
						,IsEmployee 
						,UserName
						,LoginPassword 
						,UserLocation 
						,DeptGroupCode 
						,Activate  
						,IsChecker 
						,EffectiveFromTimeKey                          
						,EffectiveToTimeKey               
						----,EntityKey 
						,PasswordChanged
						--------
						,PasswordChangeDate
						,ChangePwdCnt
						,UserLocationCode
						,UserRoleAlt_Key
						,SuspendedUser
						,CurrentLoginDate
						,ResetDate
						,UserLogged
						,UserDeletionReasonAlt_Key
						,SystemLogOut
						,RBIFLAG

						,Email_ID	--ad4
						,MobileNo
						,DesignationAlt_Key
						,IsCma

						,SecuritQsnAlt_Key
						,SecurityAns
						,MenuId
						,CreatedBy
						,DateCreated
						,ModifyBy
						,DateModified
						,MIS_APP_USR_ID
						,MIS_APP_USR_PASS
						,UserLocationExcel

					)        
				SELECT		
						@UserLoginID
						,@EmployeeID 
						,@IsEmployee 
						,@UserName
						,@LoginPassword 
						,@UserLocation
						,@DeptGroupCode 
						,@Activate  
						,@IsChecker 
						,@EffectiveFromTimeKey                       
						,@EffectiveToTimeKey                
						----,@Entity_Key 
						,PasswordChanged 
						--------------
						,PasswordChangeDate
						,ChangePwdCnt
						,@UserLocationCode
						,@UserRoleAlt_Key
						,SuspendedUser
						,CurrentLoginDate
						,ResetDate
						,UserLogged
						,UserDeletionReasonAlt_Key
						,SystemLogOut
						,RBIFLAG

						,@Email_ID	--ad4
						,@MobileNo
						,@DesignationAlt_Key
						,@IsCma

						,@SecuritQsnAlt_Key
						,@SecurityAns
						,@MenuId
						,CASE WHEN @IsAvailabve='N' THEN @CreatedModifiedBy ELSE CreatedBy END
						,CASE WHEN @IsAvailabve='N' THEN @DateCreatedmodified ELSE DateCreated END
						,CASE WHEN @IsAvailabve='N' THEN NULL ELSE @CreatedModifiedBy END
						,CASE WHEN @IsAvailabve='N' THEN NULL ELSE @DateCreatedmodified END
						,MIS_APP_USR_ID
						,MIS_APP_USR_PASS
						,UserLocationExcel

					FROM DimUserInfo 
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND UserLoginID=@UserLoginID

					UPDATE DimUserInfo
						SET EffectiveToTimeKey=@EffectiveFromTimeKey -1
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
						AND EffectiveFromTimeKey<@EffectiveFromTimeKey 
						AND UserLoginID=@UserLoginID
			END	
		IF @IsAvailabve='N'
			BEGIN
					print 'else insert'

					INSERT INTO DimUserInfo         
							(
								UserLoginID
								,EmployeeID 
								,IsEmployee 
								,UserName
								,LoginPassword 
								,UserLocation 
								,DeptGroupCode 
								,Activate  
								,IsChecker 
								,EffectiveFromTimeKey                          
								,EffectiveToTimeKey               
								----,EntityKey 
								,PasswordChanged
								,PasswordChangeDate
								,ChangePwdCnt
								,UserLocationCode
								,UserRoleAlt_Key
								,SuspendedUser
								,CurrentLoginDate
								,ResetDate
								,UserLogged
								,UserDeletionReasonAlt_Key
								,SystemLogOut
								,RBIFLAG

								,Email_ID	--ad4
								,MobileNo
								,DesignationAlt_Key
								,isCma

								,SecuritQsnAlt_Key
								,SecurityAns
								,MenuId
								,CreatedBy
								,DateCreated
								,ModifyBy
								,DateModified
								,MIS_APP_USR_ID
								,MIS_APP_USR_PASS
								,UserLocationExcel

							)        
						VALUES(		
								@UserLoginID
								,@EmployeeID 
								,@IsEmployee 
								,@UserName
								,@LoginPassword 
								,@UserLocation
								,@DeptGroupCode 
								,@Activate  
								,@IsChecker 
								,@EffectiveFromTimeKey                       
								,@EffectiveToTimeKey                
								------,@Entity_Key 
								,'N' 
								,NULL
								,0
								,@UserLocationCode
								,@UserRoleAlt_Key
								,'N'
								,NULL--CurrentLoginDate
								,NULL--ResetDate
								,0
								,NULL
								,NULL
								,NULL
								,NULLIF(@Email_ID,'')	--ad4
								,@MobileNo
								,@DesignationAlt_Key
								,@isCma
								,@SecuritQsnAlt_Key
								,@SecurityAns
								,@MenuId
								,CASE WHEN @IsAvailabve='N' THEN @CreatedModifiedBy ELSE NULL END
								,CASE WHEN @IsAvailabve='N' THEN @DateCreatedmodified ELSE NULL END
								,CASE WHEN @IsAvailabve='N' THEN NULL ELSE @CreatedModifiedBy END
								,CASE WHEN @IsAvailabve='N' THEN NULL ELSE @DateCreatedmodified END
								,NULL
								,NULL
								,NULL
								)

			END
	END
ELSE IF @FLAG=3
	BEGIN
			UPDATE DimUserInfo
				SET EffectiveToTimeKey=@EffectiveFromTimeKey -1
				,DateApproved=GETDATE()
				,ModifyBy=@CreatedModifiedBy
			WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
				AND UserLoginID=@UserLoginID
	END


		 --------------End      -----------

	COMMIT TRANSACTION        

	IF @FLAG=3
		BEGIN
			SELECT @Result = 0
			RETURN 0
		END
	ELSE
		BEGIN
			SELECT @Result = 1
			RETURN 1   
		END
END TRY
BEGIN CATCH
		   
	IF @@ERROR <> 0         
		BEGIN        
			ROLLBACK TRANSACTION
			Print 'Error'
			SELECT ERROR_MESSAGE()
			SELECT @Result = -1
			RETURN -1        
		END        
	
END CATCH
 



GO