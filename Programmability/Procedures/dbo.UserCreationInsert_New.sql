SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[UserCreationInsert_New]
	(
		 @UserLoginID	varchar(20), 
		 @EmployeeID varchar(20),			
		 @UserType varchar(20),				
		 @UserName	varchar(50),
		 @LoginPassword	varchar(max),
		 @UserLocation	varchar	(10),
		 @UserLocationCode	varchar	(10),
		 @UserRoleAlt_Key	smallint,
		 @DeptGroupCode varchar(10),

		 @EmployeeType	smallint,
		 @GradeScale smallint,
		 --@DateCreatedmodified smalldatetime,
		 --@CreatedModifiedBy	varchar	(20),
		 @Activate char(1),
		 @IsChecker char(1),
		 @IsChecker2 varchar(1),
		 @DesignationAlt_Key int,
		 @IsCma char(1),
		 @MobileNo varchar(50),
		 @Email_ID VARCHAR(50),
		 @SecuritQsnAlt_Key SMALLINT,
		 @SecurityAns VARCHAR(100),
		 @ProffEntityId int
		,@EffectiveFromTimeKey INT 
		,@EffectiveToTimeKey INT  
		,@DateCreatedModifiedApproved SMALLDATETIME        
		,@CreateModifyApprovedBy VARCHAR(20)            
		,@OperationFlag  INT
		,@AuthMode char(2) = null
		,@MenuID varchar(300) -- INT=NULL 
		,@Remark varchar(200)=NULL
		,@TimeKey SMALLINT
		,@D2Ktimestamp INT=0 OUTPUT  
		,@Result INT=0 OUTPUT
		    
	)
AS
BEGIN



SET NOCOUNT ON;	  
SET DATEFORMAT DMY

print 'menuid'
print @menuid

set @UserType='Employee'  

IF (@EffectiveFromTimeKey = 0 AND @EffectiveToTimeKey = 0)
	BEGIN
		PRINT '00'
		SELECT @EffectiveFromTimeKey = TIMEKEY from SysDayMatrix WHERE CONVERT(VARCHAR(10),DATE,110) = CONVERT(VARCHAR(10),GETDATE(),110)					
		SELECT @EffectiveToTimeKey =  MAX(TIMEKEY) from SysDayMatrix 					
	END

IF (@TIMEKEY = 0)
	BEGIN
		SELECT @TIMEKEY = TIMEKEY from SysDayMatrix WHERE CONVERT(VARCHAR(10),DATE,110) = CONVERT(VARCHAR(10),GETDATE(),110)
	END 

DECLARE @AuthorisationStatus CHAR(2)=NULL			
			 ,@CreatedBy VARCHAR(20) =NULL
			 ,@DateCreated SMALLDATETIME=NULL
			 ,@Modifiedby VARCHAR(20) =NULL
			 ,@DateModified SMALLDATETIME=NULL
			 ,@ApprovedBy  VARCHAR(20)=NULL
			 ,@DateApproved  SMALLDATETIME=NULL
			 ,@ExEntityKey AS INT=0
			 ,@ErrorHandle int=0
			 ,@IsAvailable CHAR(1)='N'
			 ,@IsSCD2 CHAR(1)='N'
			 --,@Entity_Key AS INT
			 --,@PasswordChanged char(1)
			 --,@CurrentLoginDate Date
			 
		 IF @OperationFlag =1	-- when adding, check whether it already exist or not
			BEGIN					
				IF EXISTS (SELECT  1 FROM dbo.DimUserInfo_Mod WHERE  EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey AND UserLoginID = @UserLoginID
								AND AuthorisationStatus in('NP','MP','DP','RM') 
						UNION
							SELECT  1 FROM dbo.DimUserInfo WHERE  EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey AND UserLoginID = @UserLoginID
								AND ISNULL(AuthorisationStatus,'A') = 'A')				
				BEGIN
						PRINT '@-6'
						SET @D2Ktimestamp = 2
						SET @Result = -6
print 'resul 333'
						RETURN -6
				END
			END


	--BEGIN TRY
	--BEGIN TRANSACTION
			IF @OperationFlag=1 AND @AuthMode ='Y'
			BEGIN
print '@CreateModifyApprovedBy'
print @CreateModifyApprovedBy
					SET @CreatedBy =@CreateModifyApprovedBy 
					SET @DateCreated = GETDATE()
					SET @AuthorisationStatus='NP'
					GOTO AdvValuerAddressDetails_Insert
					AdvValuerAddressDetails_Insert_Add:
			END

			ELSE IF (@OperationFlag=2 OR @OperationFlag=3) AND @AuthMode ='Y'
			BEGIN 	
print 11					
					SET @Modifiedby   = @CreateModifyApprovedBy 
					SET @DateModified = GETDATE() 
				
					IF @AuthMode='Y'
						BEGIN		
print 22										
								IF @OperationFlag=2
									BEGIN
print 33
										SET @AuthorisationStatus='MP'								
									END
								ELSE			
									BEGIN								    
										SET @AuthorisationStatus='DP'
									END

								---FIND CREATEDBY from MAIN 
print ' @CreatedBy frm main' 
								SELECT  @CreatedBy		= CreatedBy
										,@DateCreated	= DateCreated 
									FROM  dbo.DimUserInfo
									WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)	
												AND UserLoginId = @UserLoginId
print 44
								---FIND CREADED BY FROM MOD TABLE IN CASE OF DATA IS NOT AVAILABLE IN MAIN TABLE
								IF ISNULL(@CreatedBy,'')=''
									BEGIN
print '@CreatedBy from Mod' 
										SELECT  @CreatedBy		= CreatedBy
												,@DateCreated	= DateCreated 
										FROM dbo.DimUserInfo_Mod 
										WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
												AND UserLoginId = @UserLoginId																															
												AND AuthorisationStatus IN('NP','MP','A')															
									END
								ELSE ---IF DATA IS AVAILABLE IN MAIN TABLE
									BEGIN
print 66
										----UPDATE FLAG IN MAIN TABLES AS MP										
										UPDATE dbo.DimUserInfo 
											SET AuthorisationStatus=@AuthorisationStatus
										WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
												AND UserLoginId = @UserLoginId							
										  	
									END
					
								--UPDATE NP,MP  STATUS 
								IF @OperationFlag=2
								BEGIN	
print 'update mod by FM'
									UPDATE dbo.DimUserInfo_Mod
										SET AuthorisationStatus='FM'
										,ModifyBy=@Modifiedby
										,DateModified=@DateModified
									WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
												AND UserLoginId = @UserLoginId																  																								
												AND AuthorisationStatus IN('NP','MP','RM')


								END

								GOTO AdvValuerAddressDetails_Insert
								AdvValuerAddressDetails_Insert_Edit_Delete:
						END
	
		END

			ELSE IF @OperationFlag =3 AND @AuthMode ='N'	-- DELETE WITHOUT MAKER CHECKER	
					BEGIN
				PRINT 'SWAPNIL'
					SET @Modifiedby   = @CreateModifyApprovedBy 
					SET @DateModified = GETDATE() 

					UPDATE dbo.DimUserInfo  SET
								ModifyBy = @Modifiedby 
								,DateModified = @DateModified 
								--- Modified By SATWAJI as on 08/11/2021 As Per 
								---- Bank's Requirement Change for Activate Flag SET to 'N' after User Deleteion
								,Activate='N'
								,EffectiveToTimeKey = @EffectiveFromTimeKey-1
							WHERE (EffectiveFromTimeKey <= @EffectiveFromTimeKey 
								    AND EffectiveToTimeKey >= @TimeKey)
								    AND UserLoginID = @UserLoginID				
			END

			ELSE IF @OperationFlag=17 AND @AuthMode ='Y' 
					BEGIN
							SET @ApprovedBy	   = @CreateModifyApprovedBy 
							SET @DateApproved  = GETDATE()

							UPDATE dbo.DimUserInfo_Mod
								SET AuthorisationStatus='R'
								,ApprovedBy	 =@ApprovedBy
								,DateApproved=@DateApproved
								,EffectiveToTimeKey =@EffectiveFromTimeKey-1
							WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
										AND UserLoginID = @UserLoginID
										AND AuthorisationStatus in('NP','MP','DP','RM')							

							IF EXISTS(SELECT 1 FROM dbo.DimUserInfo  WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@Timekey)  AND UserLoginID = @UserLoginID	)
							BEGIN
									UPDATE DimUserInfo 
										SET AuthorisationStatus='A'
									WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
												AND UserLoginID = @UserLoginID																	    						
											AND AuthorisationStatus IN('MP','DP','RM') 							
							END				
					END

			ELSE IF @OperationFlag=18 AND @AuthMode ='Y' 
					BEGIN
					SET @ApprovedBy	   = @CreateModifyApprovedBy 
					SET @DateApproved  = GETDATE()

					UPDATE DimUserInfo_Mod
						SET AuthorisationStatus = 'RM'	
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
						AND AuthorisationStatus in ('NP','MP','DP','RM') 
						AND UserLoginID = @UserLoginID											
			END

			ELSE IF @OperationFlag=16 OR @AuthMode='N'
					BEGIN
print 'a1'
							--Comment
									--DECLARE @OrgSOLID VARCHAR(10)
									--SELECT @OrgSOLID=BranchCode FROM dbo.DimBranch
									--			WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey )
									--				  AND TempBranchCode =@TempBranchCode	


			-------set parameter for  maker checker disabled

							IF @AuthMode='N'
								BEGIN
										IF @OperationFlag = 1
											BEGIN
													SET @CreatedBy =@CreateModifyApprovedBy
													SET @DateCreated =GETDATE()
											END

										ELSE
											BEGIN
													SET @Modifiedby  = @CreateModifyApprovedBy
													SET @DateModified = GETDATE()

													SELECT	@CreatedBy=CreatedBy,@DateCreated=DATECreated
													FROM dbo.DimUserInfo
													WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey )
															AND UserLoginID = @UserLoginID	

													SET @ApprovedBy = @CreateModifyApprovedBy			
													SET @DateApproved=GETDATE()
											END
								END
			
			---set parameters and update mod table in case maker checker enabled
			IF @AuthMode='Y'
							BEGIN
print 'a2'
								DECLARE @DelStatus CHAR(2)
								DECLARE @CurrRecordFromTimeKey smallint=0
								DECLARE @CurrRecordFromTimeKey_ServiceOfNotice smallint=0
								DECLARE @CurrRecordFromTimeKey_Consortium smallint=0


								SELECT @ExEntityKey= MAX(EntityKey) FROM dbo.DimUserInfo_Mod 
									WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 
									AND UserLoginID = @UserLoginID																											
									AND AuthorisationStatus IN('NP','MP','DP','RM')	

								SELECT	@DelStatus=AuthorisationStatus,@CreatedBy=CreatedBy,@DateCreated=DATECreated
									,@Modifiedby=ModifyBy, @DateModified=DateModified
								 FROM dbo.DimUserInfo_Mod
									WHERE EntityKey=@ExEntityKey
print @ExEntityKey
print @DateModified
								SET @ApprovedBy = @CreateModifyApprovedBy			
								SET @DateApproved=GETDATE()
								
								DECLARE @CurEntityKey INT=0
								SELECT @ExEntityKey= MIN(EntityKey) FROM dbo.DimUserInfo_Mod 
									WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 
										 AND UserLoginID = @UserLoginID									 
										 AND AuthorisationStatus IN('NP','MP','DP','RM')	

											
								SELECT	@CurrRecordFromTimeKey=EffectiveFromTimeKey 
									 FROM DimUserInfo_Mod
										WHERE EntityKey=@ExEntityKey						
print 'a3'			
												
									 --FOR CHILD SCREEN
								UPDATE dbo.DimUserInfo_Mod
									SET  EffectiveToTimeKey =@CurrRecordFromTimeKey-1
									WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)
										AND UserLoginID = @UserLoginID																									
										AND AuthorisationStatus='A'
		
		
					
								IF @DelStatus='DP'	--- DELETE RECORD AUTHORISE
								BEGIN	
			--print
									UPDATE dbo.DimUserInfo_Mod
									SET AuthorisationStatus ='A'
										,ApprovedBy=@ApprovedBy
										,DateApproved=@DateApproved
										,EffectiveToTimeKey =@EffectiveFromTimeKey -1
									WHERE    UserLoginID = @UserLoginID																				
										AND AuthorisationStatus in('NP','MP','DP','RM')	
						
									IF EXISTS(SELECT 1 FROM dbo.DimUserInfo WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)  and UserLoginID = @UserLoginID	)											
										BEGIN
											
												UPDATE dbo.DimUserInfo 
													SET AuthorisationStatus ='A'
														,ModifyBy=@Modifiedby
														,DateModified=@DateModified
														,ApprovedBy=@ApprovedBy
														,DateApproved=@DateApproved
														,EffectiveToTimeKey =@EffectiveFromTimeKey-1
													WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)
																AND UserLoginID = @UserLoginID	
										END													
								END -- END DELETE BLOCK
			
								ELSE  -- OTHER THAN DELETE STATUS
									BEGIN
print 'a4'
											UPDATE dbo.DimUserInfo_Mod 
												SET AuthorisationStatus ='A'
													,ApprovedBy=@ApprovedBy
													,DateApproved=@DateApproved
												WHERE  UserLoginID = @UserLoginID								         													        											
													AND AuthorisationStatus in('NP','MP','RM')
									END		
							END
				
print '@DelStatus'			
print @DelStatus
			IF @DelStatus <>'DP' OR @AuthMode ='N'
				BEGIN
print 'a5' 

						IF EXISTS(SELECT 1 FROM dbo.DimUserInfo  WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)  AND UserLoginID = @UserLoginID )
							BEGIN
print 'a6' 
									SET @IsAvailable='Y'
									SET @AuthorisationStatus='A'

									IF EXISTS(SELECT 1 FROM dbo.DimUserInfo  WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey ) 
													AND EffectiveFromTimeKey=@EffectiveFromTimeKey  AND UserLoginID = @UserLoginID)
										BEGIN
print 'a7' 
										  UPDATE dbo.DimUserInfo
												   SET 												  
												   
													UserLoginID =@UserLoginID,
													UserName =@UserName,
													UserLocation =@UserLocation,
													UserLocationCode =@UserLocationCode,
													UserRoleAlt_Key =@UserRoleAlt_Key	,
      												LoginPassword =@LoginPassword,
      												IsChecker =	@IsChecker,
													IsChecker2 =	@IsChecker2,
      												Activate =	@Activate,
													DeptGroupCode =	@DeptGroupCode,
													Email_ID =	@Email_ID,	--ad4
													MobileNo =	@MobileNo,
													DesignationAlt_Key =	@DesignationAlt_Key,
													IsCma =	@isCma,
													MenuId = @MenuID,
												   	ProffEntityId=@ProffEntityId
													,EmployeeTypeAlt_Key=@EmployeeType
													,GradeScaleAlt_Key=@GradeScale
												   ,ModifyBy=@Modifiedby
												   ,DateModified=@DateModified
												   ,CurrentLoginDate = CASE WHEN @OperationFlag =2 and @Activate='Y' THEN GETDATE() ELSE CurrentLoginDate END
												   ---,DateCreated= CASE WHEN @OperationFlag =2 THEN @DateModified ELSE DateCreated END
												   ,ApprovedBy=CASE WHEN @AuthMode ='Y' THEN @ApprovedBy ELSE NULL END
												   ,DateApproved= CASE WHEN @AuthMode ='Y' THEN @DateApproved ELSE NULL END
												   ,AuthorisationStatus= CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END
												WHERE 
													UserLoginID = @UserLoginID AND 
													(EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) AND 
													EffectiveFromTimeKey=@EffectiveFromTimeKey 


													IF	@OperationFlag =2 and @Activate='Y'

													BEGIN
													UPDATE dbo.DimUserInfo
														SET 	
															PasswordChanged = 'Y',
															PasswordChangeDate = GETDATE()
														WHERE 
															UserLoginID = @UserLoginID AND 
															(EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) AND 
															EffectiveFromTimeKey=@EffectiveFromTimeKey 

														Insert into UserLoginHistory(UserID,LoginTime,LogoutTime,LoginSucceeded)
														SELECT @USERLOGINID,GETDATE(),GETDATE(),'Y'
														

													END


									END	
									ELSE
										BEGIN
											SET @IsSCD2='Y'
											print 'set @IsSCD2=Y'
										END
							END

						IF @IsAvailable='N' OR @IsSCD2='Y'		
							BEGIN
print '@Menu Idsss'
print @MenuId
									INSERT INTO DimUserInfo         
											(
												UserLoginID
												,EmployeeID 
												,UserType 
												,UserName
												,LoginPassword 
												,UserLocation 
												,DeptGroupCode 
												,Activate  
												,IsChecker 
												,IsChecker2
												,EffectiveFromTimeKey                          
												,EffectiveToTimeKey   
												
												--Add by Mohit
												,GradeScaleAlt_Key
												,EmployeeTypeAlt_Key  
												          
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
												,ApprovedBy		
												,DateApproved	
												,MIS_APP_USR_ID
												,MIS_APP_USR_PASS
												,UserLocationExcel
												,ProffEntityId												

											)        
										SELECT		
												@UserLoginID
												,@EmployeeID 
												,@UserType 
												,@UserName
												,@LoginPassword 
												,@UserLocation
												,@DeptGroupCode 
												,@Activate  
												,@IsChecker 
												,@IsChecker2
												,@EffectiveFromTimeKey                       
												,@EffectiveToTimeKey 
												,@GradeScale 
												,@EmployeeType           
												----,@Entity_Key 
												,'N'
												--------------
												,NULL
												,0
												,@UserLocationCode
												,@UserRoleAlt_Key
												,'N'
												,NULL
												,NULL
												,0
												,NULL
												,NULL
												,NULL
												,@Email_ID	--ad4
												,@MobileNo
												,@DesignationAlt_Key
												,@IsCma
												,@SecuritQsnAlt_Key
												,@SecurityAns
												,@MenuId
												,@CreatedBy
												--,CASE WHEN @IsAvailable='N' THEN CreatedBy ELSE @CreateModifyApprovedBy END	
												,@DateCreated
												--,CASE WHEN @IsAvailable='N' THEN DateCreated ELSE  @DateCreatedModifiedApproved END													
												,CASE WHEN @IsAvailable='Y' THEN  @Modifiedby ELSE NULL END
												,CASE WHEN @IsAvailable='Y' THEN  @DateModified ELSE NULL END
												,CASE WHEN @AUTHMODE= 'Y' THEN    @ApprovedBy ELSE NULL END
												,CASE WHEN @AUTHMODE= 'Y' THEN    @DateApproved  ELSE NULL END
												--,CASE WHEN @AuthMode='N' THEN NULL ELSE @CreateModifyApprovedBy END
												--,CASE WHEN @AuthMode='N' THEN NULL ELSE @DateCreatedModifiedApproved END
												,NULL
												,NULL
												,NULL
												,@ProffEntityId												
											
print '@CreateModifyApprovedBy'
print @CreateModifyApprovedBy

print 'a9'
							END

						IF @IsSCD2='Y' 
						BEGIN
print 777
							UPDATE dbo.DimUserInfo  SET
										EffectiveToTimeKey=@EffectiveFromTimeKey-1
										,AuthorisationStatus =CASE WHEN @AUTHMODE='Y' THEN  'A' ELSE NULL END
									WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey AND EffectiveToTimeKey>=@TimeKey)
									      AND UserLoginID = @UserLoginID
											AND EffectiveFromTimekey<@EffectiveFromTimeKey
						END

				
				END
		END 

			--***********maintain log table
	IF @OperationFlag IN(1,2,3,16,17,18) AND @AuthMode ='Y'
			BEGIN
					IF @OperationFlag=2 
						BEGIN 
							SET @CreatedBy=@Modifiedby
						END

					IF @OperationFlag IN(16,17) 
						BEGIN 
							SET @DateCreated= GETDATE()
						END

					EXEC LogDetailsInsertUpdate_Attendence -- MAINTAIN LOG TABLE
							0,
						@MenuID,
						@UserLoginID,-- ReferenceID ,
						@CreatedBy,
						@ApprovedBy,-- @ApproveBy 
						@DateCreated,
						@Remark,
						@MenuID, -- for FXT060 screen
						@OperationFlag,
						@AuthMode 	
			END
			
	SET @ErrorHandle=1

	AdvValuerAddressDetails_Insert:

	IF @ErrorHandle=0
		BEGIN
print 88			
print '@CreateModifyApprovedBy'
print @CreateModifyApprovedBy
print '@IsAvailable'
print @IsAvailable
print '@Modifiedby'
print @Modifiedby

			INSERT INTO dbo.DimUserInfo_mod
													(
														UserLoginID
														,EmployeeID 
														,UserType 
														,UserName
														,LoginPassword 
														,UserLocation 
														,DeptGroupCode 
														,Activate  
														,IsChecker 
														,IsChecker2
														,EffectiveFromTimeKey                          
														,EffectiveToTimeKey  
														
														--Add by Mohit
														,GradeScaleAlt_Key
														,EmployeeTypeAlt_Key
														             
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
														,AuthorisationStatus	
														,ProffEntityId													
													)

											SELECT													      
													@UserLoginID
													,@EmployeeID 
													,@UserType 
													,@UserName
													,@LoginPassword 
													,@UserLocation
													,@DeptGroupCode 
													,@Activate  
													,@IsChecker 
													,@IsChecker2
													,@EffectiveFromTimeKey                       
													,@EffectiveToTimeKey  
													
													,@GradeScale            
													,@EmployeeType  
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
													,@CreateModifyApprovedBy
													,@DateCreatedModifiedApproved
													,@Modifiedby	--CASE WHEN @IsAvailable='N' THEN @CreateModifyApprovedBy ELSE NULL END
													,@DateModified	--CASE WHEN @IsAvailable='N' THEN @DateCreatedModifiedApproved ELSE NULL END													
													,@ApprovedBy	--CASE WHEN @IsAvailable='N' THEN NULL ELSE @CreateModifyApprovedBy END
													,@DateApproved	--CASE WHEN @IsAvailable='N' THEN NULL ELSE @DateCreatedModifiedApproved END
													,NULL
													,@AuthorisationStatus	
													,@ProffEntityId												

			--print 'Inserted'									
				IF @OperationFlag =1
					BEGIN					
						PRINT 3
						GOTO AdvValuerAddressDetails_Insert_Add
					END
				ELSE IF @OperationFlag =2 OR @OperationFlag =3
					BEGIN
print 99
						GOTO AdvValuerAddressDetails_Insert_Edit_Delete
					END
		END


	--COMMIT TRANSACTION

		SELECT @D2Ktimestamp=CAST(D2Ktimestamp AS INT)
				from (
						SELECT  D2Ktimestamp FROM DimUserInfo  WHERE  EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey AND UserLoginId =@UserLoginId AND ISNULL(AuthorisationStatus,'A')='A' 
						UNION 
						SELECT  D2Ktimestamp FROM DimUserInfo_Mod WHERE   EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey  AND UserLoginId =@UserLoginId  AND AuthorisationStatus IN ('NP','MP','DP','RM')
		
					 )timestamp1
print 'd2k 111'
					
					SET @D2Ktimestamp =ISNULL(@D2Ktimestamp,1)
					set @Result =ISNULL(@Result,1)
					print @D2Ktimestamp					
						
	 If @OperationFlag=1
		 BEGIN
			 	SELECT @D2Ktimestamp=CAST(D2Ktimestamp AS INT)
				from (
						SELECT  D2Ktimestamp FROM DimUserInfo  WHERE  EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey 
								AND UserLoginId =@UserLoginId AND ISNULL(AuthorisationStatus,'A')='A' 
						UNION 
						SELECT  D2Ktimestamp FROM DimUserInfo_Mod WHERE   EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey  
								AND UserLoginId =@UserLoginId  AND AuthorisationStatus IN ('NP','MP','DP','RM')
					 )timestamp1

				SET @Result =@UserRoleAlt_Key				
print 'resul 444'
				RETURN @Result					
				RETURN @D2Ktimestamp
		 END
	ELSE
				IF @OperationFlag =3
					BEGIN
						SET @Result =0
						if(@AuthMode='N')
						(
							select @D2Ktimestamp=(SELECT  D2Ktimestamp FROM DimUserInfo  WHERE  EffectiveFromTimeKey<=@TimeKey 
									AND UserLoginId =@UserLoginId AND ISNULL(AuthorisationStatus,'A')='A' )
						)
print 'resul 555'
						return @D2Ktimestamp
						RETURN @Result
					END
				ELSE 						
					BEGIN
print 'result 111'
							SET @Result =1--@UserLoginId		
print 	'@Result'
print 	@Result								
							RETURN @Result						
							RETURN @D2Ktimestamp		
		
		END
					END

--RETURN 1
	--END TRY

--	BEGIN CATCH
--		select ERROR_MESSAGE(),ERROR_LINE()
--		ROLLBACK TRAN
--		SET @Result =-1				
--print 'resul 222'
--		RETURN @Result
--	END CATCH

----END














GO