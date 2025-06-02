SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

  
CREATE PROCEDURE [dbo].[UserGroupInsertUpdate] -- -- select * from DimUserDeptGroup_Mod
 --@EntityKey int,        
 @DeptGroupId int = 1,        
 @DeptGroupName varchar(12),        
 @DeptGroupDesc varchar(200),        
 @MenuId varchar(1000),            
 @IsUniversal char(1),
 --@CreatedBy varchar(20),        
 @timekey int,        

 @EffectiveFromTimeKey INT 
,@EffectiveToTimeKey INT  
,@DateCreatedModifiedApproved Varchar(10)        
,@CreateModifyApprovedBy VARCHAR(20)            
,@OperationFlag  INT
,@AuthMode char(2) = 'N'-- null		
,@Remark varchar(200)=NULL
,@D2Ktimestamp INT=0 OUTPUT  
,@Result INT=0 OUTPUT
AS     
BEGIN  


SET NOCOUNT ON;	  
SET DATEFORMAT DMY

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

			 	

		IF @OperationFlag =1	-- when adding, check whether it already exist or not
		BEGIN				
		
			IF @AuthMode = 'N'
				BEGIN
				PRINT 'ABC'
				print @TimeKey
					select @DeptGroupId =  max(DeptGroupId)+1 from DimUserDeptGroup
				END
			ELSE IF @AuthMode = 'Y'
				BEGIN
					select @DeptGroupId =  max(DeptGroupId)+1 from DimUserDeptGroup_Mod
				END

			IF @DeptGroupId is NULL
			Begin 
				SET @DeptGroupId = 1
			End
			print 'sb'
			IF EXISTS (SELECT  1 FROM dbo.DimUserDeptGroup_Mod WHERE  EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey AND DeptGroupCode = @DeptGroupName
							AND AuthorisationStatus in('NP','MP','DP','RM') 
					UNION
						SELECT  1 FROM dbo.DimUserDeptGroup WHERE  EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey AND DeptGroupCode = @DeptGroupName
							AND ISNULL(AuthorisationStatus,'A') = 'A')				
				BEGIN
						PRINT '@-6'
						SET @D2Ktimestamp = 2
						SET @Result = -6
						RETURN -6
				END
		END
		
		

		
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
					SET @Modifiedby   = @CreateModifyApprovedBy 
					SET @DateModified = GETDATE() 
				
					IF @AuthMode='Y'
						BEGIN											
								IF @OperationFlag=2
									BEGIN
										SET @AuthorisationStatus='MP'								
									END
								ELSE			
									BEGIN								    
										SET @AuthorisationStatus='DP'
									END

								---FIND CREATEDBY from MAIN 
								SELECT  @CreatedBy		= CreatedBy
										,@DateCreated	= DateCreated 
									FROM  dbo.DimUserDeptGroup
									WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)	
												AND DeptGroupId = @DeptGroupId
								---FIND CREATED BY FROM MOD TABLE IN CASE OF DATA IS NOT AVAILABLE IN MAIN TABLE
								IF ISNULL(@CreatedBy,'')=''
									BEGIN
										SELECT  @CreatedBy		= CreatedBy
												,@DateCreated	= DateCreated 
										FROM dbo.DimUserDeptGroup_Mod 
										WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
												AND DeptGroupId = @DeptGroupId																															
												AND AuthorisationStatus IN('NP','MP','A')															
									END
								ELSE ---IF DATA IS AVAILABLE IN MAIN TABLE
									BEGIN
										----UPDATE FLAG IN MAIN TABLES AS MP										
										UPDATE dbo.DimUserDeptGroup 
											SET AuthorisationStatus=@AuthorisationStatus
										WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
												AND DeptGroupId = @DeptGroupId										  	
									END
					
								--UPDATE NP,MP  STATUS 
								IF @OperationFlag=2
								BEGIN	
print 'update mod by FM'
									UPDATE dbo.DimUserDeptGroup_Mod
										SET AuthorisationStatus='FM'
										,ModifiedBy=@Modifiedby
										,DateModified=@DateModified
									WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
												AND DeptGroupId = @DeptGroupId																  																								
												AND AuthorisationStatus IN('NP','MP','RM')


								END

								GOTO AdvValuerAddressDetails_Insert
								AdvValuerAddressDetails_Insert_Edit_Delete:
						END
		END



		ELSE IF @OperationFlag =3 AND @AuthMode ='N'	-- DELETE WITHOUT MAKER CHECKER	
					BEGIN				
						SET @Modifiedby   = @CreateModifyApprovedBy 
						SET @DateModified = GETDATE() 

						UPDATE dbo.DimUserDeptGroup  
									SET ModifiedBy = @Modifiedby 
									,DateModified = @DateModified 
									,EffectiveToTimeKey = @EffectiveFromTimeKey-1
								WHERE (EffectiveFromTimeKey = @EffectiveFromTimeKey 
										AND EffectiveToTimeKey >= @TimeKey)
										AND DeptGroupId = @DeptGroupId		
					END



		ELSE IF @OperationFlag=17 AND @AuthMode ='Y' 
					BEGIN
							SET @ApprovedBy	   = @CreateModifyApprovedBy 
							SET @DateApproved  = GETDATE()

							UPDATE dbo.DimUserDeptGroup_Mod
								SET AuthorisationStatus = 'R'
								,ApprovedBy	 =@ApprovedBy
								,DateApproved=@DateApproved
								,EffectiveToTimeKey =@EffectiveFromTimeKey-1
								WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
										AND DeptGroupId = @DeptGroupId	
										AND AuthorisationStatus in('NP','MP','DP','RM')							

							IF EXISTS(SELECT 1 FROM dbo.DimUserDeptGroup  WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@Timekey)  AND DeptGroupId = @DeptGroupId )
								BEGIN
										UPDATE DimUserDeptGroup 
											SET AuthorisationStatus='A'
										WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
													AND DeptGroupId = @DeptGroupId																    						
												AND AuthorisationStatus IN('MP','DP','RM') 							
								END				
					END


		ELSE IF @OperationFlag=18 AND @AuthMode ='Y' 
				BEGIN
						SET @ApprovedBy	   = @CreateModifyApprovedBy 
						SET @DateApproved  = GETDATE()

						UPDATE DimUserDeptGroup_Mod
							SET AuthorisationStatus = 'RM'	
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND AuthorisationStatus in ('NP','MP','DP','RM') 
							AND DeptGroupId = @DeptGroupId								
				END



		ELSE IF @OperationFlag=16 OR @AuthMode='N'
				BEGIN
                      print 'a1'							
						IF @AuthMode='N'	---- set parameter for  maker checker disabled
								BEGIN
										IF @OperationFlag=1
											BEGIN
													SET @CreatedBy =@CreateModifyApprovedBy
													SET @DateCreated =GETDATE()
											END
										ELSE
											BEGIN
													SET @Modifiedby  = @CreateModifyApprovedBy
													SET @DateModified = GETDATE()

													SELECT	@CreatedBy=CreatedBy,@DateCreated=DATECreated
													FROM dbo.DimUserDeptGroup
													WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey )
															AND DeptGroupId = @DeptGroupId	

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

								SELECT @ExEntityKey= MAX(EntityKey) FROM dbo.DimUserDeptGroup_Mod 
									WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 
									AND DeptGroupId = @DeptGroupId																											
									AND AuthorisationStatus IN('NP','MP','DP','RM')	

								SELECT	@DelStatus = AuthorisationStatus,	@CreatedBy = CreatedBy,		@DateCreated = DATECreated
									,@Modifiedby = ModifiedBy,	@DateModified=DateModified
								 FROM dbo.DimUserDeptGroup_Mod
									WHERE EntityKey=@ExEntityKey
                                print @ExEntityKey
                                print @DateModified
								SET @ApprovedBy = @CreateModifyApprovedBy			
								SET @DateApproved=GETDATE()
								
								DECLARE @CurEntityKey INT=0
								SELECT @ExEntityKey= MIN(EntityKey) FROM dbo.DimUserDeptGroup_Mod 
									WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 
										 AND DeptGroupId = @DeptGroupId									 
										 AND AuthorisationStatus IN('NP','MP','DP','RM')	
											
								SELECT	@CurrRecordFromTimeKey=EffectiveFromTimeKey 
									 FROM DimUserDeptGroup_Mod
										WHERE EntityKey=@ExEntityKey							
												
									 --FOR CHILD SCREEN
								UPDATE dbo.DimUserDeptGroup_Mod
									SET  EffectiveToTimeKey =@CurrRecordFromTimeKey-1
									WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)
										AND DeptGroupId = @DeptGroupId	
										AND AuthorisationStatus='A'
					
								IF @DelStatus='DP'	--- DELETE RECORD AUTHORISE
									BEGIN	
										UPDATE dbo.DimUserDeptGroup_Mod
											SET AuthorisationStatus ='A'
												,ApprovedBy=@ApprovedBy
												,DateApproved=@DateApproved
												,EffectiveToTimeKey =@EffectiveFromTimeKey -1
											WHERE    DeptGroupId = @DeptGroupId	
												AND AuthorisationStatus in('NP','MP','DP','RM')	
						
											IF EXISTS(SELECT 1 FROM dbo.DimUserDeptGroup WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)  and DeptGroupId = @DeptGroupId )											
											BEGIN
											
													UPDATE dbo.DimUserDeptGroup 
														SET AuthorisationStatus ='A'
															,ModifiedBy = @Modifiedby
															,DateModified = @DateModified
															,ApprovedBy = @ApprovedBy
															,DateApproved = @DateApproved
															,EffectiveToTimeKey = @EffectiveFromTimeKey - 1
														WHERE (EffectiveFromTimeKey <= @Timekey AND EffectiveToTimeKey >= @Timekey)
																	AND DeptGroupId = @DeptGroupId 
											END													
									END -- END @DelStatus='DP'
			
								ELSE  -- OTHER THAN DELETE STATUS
									BEGIN
											UPDATE dbo.DimUserDeptGroup_Mod 
												SET AuthorisationStatus ='A'
													,ApprovedBy=@ApprovedBy
													,DateApproved=@DateApproved
												WHERE  DeptGroupId = @DeptGroupId 
													AND AuthorisationStatus in('NP','MP','RM')
									END		
					END
				
                    print '@DelStatus'			
                    print @DelStatus
				IF @DelStatus <>'DP' OR @AuthMode ='N'
				BEGIN
				       PRINT @AuthMode

						IF EXISTS(SELECT 1 FROM dbo.DimUserDeptGroup  WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)  AND DeptGroupId = @DeptGroupId )
							BEGIN
print 'a6' 
									SET @IsAvailable='Y'
									SET @AuthorisationStatus='A'

									IF EXISTS(SELECT 1 FROM dbo.DimUserDeptGroup  WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey ) 
													AND EffectiveFromTimeKey=@EffectiveFromTimeKey  AND DeptGroupId = @DeptGroupId )
										BEGIN
print 'a7' 
										  UPDATE dbo.DimUserDeptGroup
												   SET 	
													DeptGroupId = @DeptGroupId
													,DeptGroupCode =  @DeptGroupName
													,DeptGroupName = @DeptGroupDesc
													,Menus = @MenuId
													,IsUniversal = @IsUniversal
												   ,ModifiedBy = @Modifiedby
												   ,DateModified = @DateModified
												   ,ApprovedBy=CASE WHEN @AuthMode ='Y' THEN @ApprovedBy ELSE NULL END
												   ,DateApproved= CASE WHEN @AuthMode ='Y' THEN @DateApproved ELSE NULL END
												   ,AuthorisationStatus= CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END
												WHERE 
													DeptGroupId = @DeptGroupId AND 
													(EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) AND 
													EffectiveFromTimeKey=@EffectiveFromTimeKey 
									END	
									ELSE
										BEGIN
											SET @IsSCD2='Y'
											print 'set @IsSCD2=Y'
										END
							END

						IF @IsAvailable='N' OR @IsSCD2='Y'		
							BEGIN
                                   print '@IsAvailable'
                                   print @IsAvailable
									INSERT INTO DimUserDeptGroup         
											(
												DeptGroupId
												,DeptGroupCode        
												,DeptGroupName        
												,Menus
												,IsUniversal

												,EffectiveFromTimeKey                          
												,EffectiveToTimeKey               
												,CreatedBy
												,DateCreated
												,ModifiedBy
												,DateModified
												,ApprovedBy		
												,DateApproved													
											)        
										SELECT		
												@DeptGroupId
												,@DeptGroupName 
												,@DeptGroupDesc 
												,@MenuId
												,@IsUniversal

												,@EffectiveFromTimeKey                       
												,@EffectiveToTimeKey   												
												,@CreatedBy	--,CASE WHEN @IsAvailable='N' THEN CreatedBy ELSE @CreateModifyApprovedBy END	
												,@DateCreated	--,CASE WHEN @IsAvailable='N' THEN DateCreated ELSE  @DateCreatedModifiedApproved END													
												,CASE WHEN @IsAvailable='Y' THEN  @Modifiedby ELSE NULL END
												,CASE WHEN @IsAvailable='Y' THEN  @DateModified ELSE NULL END
												,CASE WHEN @AUTHMODE= 'Y' THEN    @ApprovedBy ELSE NULL END
												,CASE WHEN @AUTHMODE= 'Y' THEN    @DateApproved  ELSE NULL END	
												
										--------- update in sysCrismacMenu		
								--IF (@EffectiveFromTimeKey =(SELECT EffectiveFromTimeKey                                   
									--		    FROM DimUserDeptGroup                                
										--	    WHERE (EffectiveFromTimeKey <=@timekey and EffectiveToTimeKey>=@timekey) and DeptGroupCode=@DeptGroupName ) )       											      
										--BEGIN        

											   print 'same timekey'        
											   BEGIN TRANSACTION          
											        
											 --Update DimUserDeptGroup Set DeptGroupName=@DeptGroupDesc,DateModified=GETDATE(),ModifiedBy=@CreatedBy,Menus=@MenuId where (EffectiveFromTimeKey <=@timekey and EffectiveToTimeKey>=@timekey) and DeptGroupCode=@DeptGroupName        
											 --Update SysCRisMacMenu Set Department=@MenuDept where MenuTitleId in (@Menus)        										         
											          
											 Update SysCRisMacMenu Set DeptGroupCode=replace(DeptGroupCode,  @DeptGroupName+ ',','')        
											  Where DeptGroupCode like '%' + @DeptGroupName + '%'        
											      
											 Update SysCRisMacMenu Set DeptGroupCode=replace(DeptGroupCode, ',' + @DeptGroupName,'')        
											  Where DeptGroupCode like '%' + @DeptGroupName + '%'        
											      
											 Update SysCRisMacMenu Set DeptGroupCode=replace(DeptGroupCode,  @DeptGroupName+ ',','')        
											  Where DeptGroupCode like '%' + @DeptGroupName + '%'        
											      
											 Update SysCRisMacMenu Set DeptGroupCode=replace(DeptGroupCode, @DeptGroupName,'')        
											  Where DeptGroupCode like '%' + @DeptGroupName + '%'        
											             
											   update SysCRisMacMenu set DeptGroupCode= case ISNULL(DeptGroupCode,'') when '' then @DeptGroupName        
											                                       ELSE DeptGroupCode+','+  @DeptGroupName END        
											               where MenuId IN (Select Items from dbo.split(@MenuId,','))         
											      
											 IF @@ERROR <> 0                 
											 BEGIN                
												  ROLLBACK TRANSACTION    
												  SET @Result  = -1                  
												  RETURN -1                
											 END 
											                
											 COMMIT TRANSACTION    
											  --SET @Result  = 1  
											  --SET @D2Ktimestamp =                   
											  --RETURN 1         
										--END        
											      
								--ELSE         
											      
								--			  BEGIN        
								--			     print 'different time key'        
								--			  BEGIN TRANSACTION          
								--			  Update DimUserDeptGroup Set  EffectiveToTimeKey = @EffectiveFromTimeKey - 1,         
								--			    ModifiedBy=@CreatedBy,        
								--			    DateModified=GETDATE()        
								--			    WHERE EffectiveToTimeKey =@EffectiveToTimeKey and DeptGroupCode=@DeptGroupName        
											                
											           
								--			 Update SysCRisMacMenu Set DeptGroupCode=replace(DeptGroupCode,  @DeptGroupName+ ',','')        
								--			  Where DeptGroupCode like '%' + @DeptGroupName + '%'        
											         
								--			 Update SysCRisMacMenu Set DeptGroupCode=replace(DeptGroupCode, ',' + @DeptGroupName,'')        
								--			  Where DeptGroupCode like '%' + @DeptGroupName + '%'        
											         
								--			 Update SysCRisMacMenu Set DeptGroupCode=replace(DeptGroupCode,  @DeptGroupName+ ',','')        
								--			  Where DeptGroupCode like '%' + @DeptGroupName + '%'        
											         
								--			 Update SysCRisMacMenu Set DeptGroupCode=replace(DeptGroupCode, @DeptGroupName,'')        
								--			  Where DeptGroupCode like '%' + @DeptGroupName + '%'        
											         
											     
											      
											               
								--			   update SysCRisMacMenu set DeptGroupCode= case ISNULL(DeptGroupCode,'') when '' then  @DeptGroupName        
								--			                                       ELSE DeptGroupCode+','+  @DeptGroupName END        
								--			               where MenuId IN (Select Items from dbo.split(@MenuId,','))     
														       
								--			  IF @@ERROR <> 0                 
								--			 BEGIN                
								--			  ROLLBACK TRANSACTION   
								--				set @Result      =-1                
								--			  RETURN -1                
								--			 END                
								--			 COMMIT TRANSACTION        
								--			 set @Result      =1           
								--			  RETURN 1         
								--			end     		
											
										---------

										
print '@CreateModifyApprovedBy'
print @CreateModifyApprovedBy

							END

						IF @IsSCD2='Y' 
						BEGIN
                               print 777
							UPDATE dbo.DimUserDeptGroup  SET
										EffectiveToTimeKey=@EffectiveFromTimeKey-1
										,AuthorisationStatus =CASE WHEN @AUTHMODE='Y' THEN  'A' ELSE NULL END
									WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey AND EffectiveToTimeKey>=@TimeKey)
									      AND DeptGroupId = @DeptGroupId
											AND EffectiveFromTimekey<@EffectiveFromTimeKey
						END
				END
		END 


		--***********maintain log table
			--IF @OperationFlag IN(1,2,3,16,17,18) AND @AuthMode ='Y'
			--	BEGIN
			--			IF @OperationFlag=2 
			--				BEGIN 
			--					SET @CreatedBy=@Modifiedby
			--				END

			--			IF @OperationFlag IN(16,17) 
			--				BEGIN 
			--					SET @DateCreated= GETDATE()
			--				END

			--			EXEC LogDetailsInsertUpdate_Attendence -- MAINTAIN LOG TABLE
			--					0,
			--				@MenuID,
			--				@UserLoginID,-- ReferenceID ,
			--				@CreatedBy,
			--				@ApprovedBy,-- @ApproveBy 
			--				@DateCreated,
			--				@Remark,
			--				@MenuID, -- for FXT060 screen
			--				@OperationFlag,
			--				@AuthMode 	
			--	END
			


				SET @ErrorHandle=1

		AdvValuerAddressDetails_Insert:

	IF @ErrorHandle=0
		BEGIN
		print 'insert into mod'
			INSERT INTO dbo.DimUserDeptGroup_mod
													(
														DeptGroupId
														,DeptGroupCode        
														,DeptGroupName        
														,Menus
														,IsUniversal
														,EffectiveFromTimeKey                          
														,EffectiveToTimeKey               														
														,CreatedBy
														,DateCreated
														,ModifiedBy
														,DateModified		
														,ApprovedBy
														,DateApproved												
														,AuthorisationStatus														
													)

											SELECT													      
													@DeptGroupId
													,@DeptGroupName 
													,@DeptGroupDesc 
													,@MenuId
													,@IsUniversal
													,@EffectiveFromTimeKey                       
													,@EffectiveToTimeKey                
													,@CreateModifyApprovedBy
													,@DateCreatedModifiedApproved
													,@Modifiedby	--CASE WHEN @IsAvailable='N' THEN @CreateModifyApprovedBy ELSE NULL END
													,@DateModified	--CASE WHEN @IsAvailable='N' THEN @DateCreatedModifiedApproved ELSE NULL END													
													,@ApprovedBy	--CASE WHEN @IsAvailable='N' THEN NULL ELSE @CreateModifyApprovedBy END
													,@DateApproved	--CASE WHEN @IsAvailable='N' THEN NULL ELSE @DateCreatedModifiedApproved END													
													,@AuthorisationStatus
													

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


				SELECT @D2Ktimestamp=CAST(D2Ktimestamp AS INT)
				from (
						SELECT  D2Ktimestamp FROM DimUserDeptGroup  WHERE  EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey AND DeptGroupId = @DeptGroupId  AND ISNULL(AuthorisationStatus,'A')='A' 
						UNION 
						SELECT  D2Ktimestamp FROM DimUserDeptGroup_mod WHERE   EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey  AND DeptGroupId = @DeptGroupId   AND AuthorisationStatus IN ('NP','MP','DP','RM')
		
					 )timestamp1


				SET @D2Ktimestamp =ISNULL(@D2Ktimestamp,1)
					set @Result =ISNULL(@Result,1)
					print @D2Ktimestamp	



				If @OperationFlag=1
					BEGIN
			 			SELECT @D2Ktimestamp=CAST(D2Ktimestamp AS INT)
						from (
								SELECT  D2Ktimestamp FROM DimUserDeptGroup  WHERE  EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey 
										AND DeptGroupCode = @DeptGroupName AND ISNULL(AuthorisationStatus,'A')='A' 
								UNION 
								SELECT  D2Ktimestamp FROM DimUserDeptGroup_Mod WHERE   EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey  
										AND DeptGroupCode = @DeptGroupName AND AuthorisationStatus IN ('NP','MP','DP','RM')
							 )timestamp1
print 'timestamp'
print @D2Ktimestamp
						SET @Result = @DeptGroupId				
						RETURN @Result					
						RETURN @D2Ktimestamp
					END
				ELSE
					IF @OperationFlag =3
						BEGIN
print 'aaaaaaaa'						
							SET @Result =0
							IF(@AuthMode='N')
							(
								select @D2Ktimestamp=(SELECT  D2Ktimestamp FROM DimUserDeptGroup  WHERE  EffectiveFromTimeKey<=@TimeKey 
										AND DeptGroupCode = @DeptGroupName  AND ISNULL(AuthorisationStatus,'A')='A' )
							)
							RETURN @D2Ktimestamp
							RETURN @Result
						END
					ELSE 						
						BEGIN
								SET @Result = @DeptGroupId
	print 	'@Result'
	print 	@Result								
								RETURN @Result						
								RETURN @D2Ktimestamp		
		
						END
END





GO