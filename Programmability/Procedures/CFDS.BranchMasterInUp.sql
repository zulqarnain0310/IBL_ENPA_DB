SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [CFDS].[BranchMasterInUp]

						@BranchCode					Varchar(10)		= ''
						,@BranchName				VARCHAR(100)	= ''
						,@BranchOpenDt				VARCHAR(10)		= ''
						,@BranchRegionAlt_Key		SMALLINT		= 0
						,@BranchRegion				VARCHAR(100)	= ''
						,@BranchZoneAlt_Key			SMALLINT		= 0
						,@BranchZone				VARCHAR(100)	= ''
						,@RBIPart1					VARCHAR(10)		= ''		
						,@RBIPart2					VARCHAR(10)		= ''
						,@BranchAreaCatAlt_Key		SMALLINT		= 0
						,@BranchAreaCat				VARCHAR(50)		= ''
						,@Add1						VARCHAR(30)		= ''
						,@Add2						VARCHAR(30)		= ''
						,@Add3						VARCHAR(30)		= ''
						,@CityAlt_Key				SMALLINT		= 0
						,@Place						VARCHAR(20)		= ''
						,@Pincode					VARCHAR(10)		= ''
						,@DistrictAlt_Key			SMALLINT		= 0
						,@District					VARCHAR(50)		= ''
						,@StateAlt_Key				SMALLINT		= 0
						,@State						VARCHAR(50)		= ''
						---------D2k System Common Columns		--
						,@Remark					VARCHAR(500)	= ''
						,@MenuID					SMALLINT		= 0
						,@OperationFlag				TINYINT			= 0
						,@AuthMode					CHAR(1)			= 'N'
						,@IsMOC						CHAR(1)			= 'N'
						,@EffectiveFromTimeKey		INT				= 0
						,@EffectiveToTimeKey		INT				= 0
						,@TimeKey					INT				= 0
						,@CrModApBy					VARCHAR(20)		= ''
						,@Branch_ChangeFields		VARCHAR(250)	= ''						
						--,@ScreenEntityId			INT				= null						
						,@Result					INT				= 0 OUTPUT
						,@D2Ktimestamp				INT				= 0 OUTPUT	
						
						,@AreaAlt_Key				INT				= 0
						,@BranchDistrictName		VARCHAR(50)		= ''
						,@BranchStateName			VARCHAR(50)		= ''						

AS
BEGIN
SET NOCOUNT ON;
		PRINT 1
		DECLARE 
						@AuthorisationStatus		CHAR(2)			= NULL 
						,@CreatedBy					VARCHAR(20)		= NULL
						,@DateCreated				SMALLDATETIME	= NULL
						,@ModifiedBy				VARCHAR(20)		= NULL
						,@DateModified				SMALLDATETIME	= NULL
						,@ApprovedBy				VARCHAR(20)		= NULL
						,@DateApproved				SMALLDATETIME	= NULL
						,@ErrorHandle				int				= 0
						,@ExBranchKey				int				= 0 
						--FOR MOC
						--,@MocFromTimeKey			INT				= 0
						--,@MocToTimeKey				INT				= 0
						--,@MocDate					DATETIME		= NULL
						--,@MocStatus					CHAR(1)
		PRINT 'A'
		SET @BranchOpenDt = CONVERT(DATE,@BranchOpenDt,103)


		--DECLARE @AppAvail CHAR
		--			SET @AppAvail = (Select ParameterValue FROM SysSolutionParameter WHERE Parameter_Key=1)
		--		IF(@AppAvail='N')                         
		--			BEGIN
		--				SET @Result=-11
		--				RETURN @Result
		--			END
		
		IF ( @BranchOpenDt='1900-01-01' OR @BranchOpenDt='')
					BEGIN
						SET @BranchOpenDt = NULL
					END

		--IF @IsMOC='Y'
		--		BEGIN
		--			--- for MOC Effective from TimeKey and Effective to time Key is Prev_Qtr_key e.g for 2922  2830
		--			SET @EffectiveFromTimeKey =@TimeKey 
		--			SET @EffectiveToTimeKey =@TimeKey 
		--			SET @MocDate =GETDATE()
		--		END

		IF @OperationFlag=1  --- add
		BEGIN
			PRINT 1
				-----CHECK DUPLICATE BRANCH
			IF EXISTS(	
						Select 1 from DimBranch where BranchCode=@BranchCode AND ISNULL(AuthorisationStatus,'A')='A'
						UNION
						SELECT 1 from DimBranch_Mod	WHERE (EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey)
													AND BranchCode=@BranchCode AND  AuthorisationStatus in('NP','MP','DP','A','RM')		                
					 )	
			BEGIN
				PRINT 2
				SET @Result=-4
				RETURN @Result -- BRANCHCODE ALEADY EXISTS
			END
		END

		BEGIN TRY
		BEGIN TRANSACTION	
		-----
	
		PRINT 3	
			--np- new,  mp - modified, dp - delete, fm - further modifief, A- AUTHORISED , 'RM' - REMARK 
		IF @OperationFlag =1 AND @AuthMode ='Y' -- ADD
			BEGIN
				     PRINT 'Add' --+
					 SET @CreatedBy = @CrModApBy 
					 SET @DateCreated = GETDATE()
					 SET @AuthorisationStatus='NP'
					 GOTO BranchMaster_Insert
					BranchMaster_Insert_Add:
			END
		ELSE IF (@OperationFlag = 2 OR @OperationFlag = 3) AND @AuthMode = 'Y' --EDIT AND DELETE
			BEGIN
				Print 4
				SET @CreatedBy= @CrModApBy
				SET @DateCreated = GETDATE()
				Set @Modifiedby=@CrModApBy   
				Set @DateModified =GETDATE()
				
					PRINT 5

					IF @OperationFlag = 2
						BEGIN
							PRINT 'Edit'
							SET @AuthorisationStatus ='MP'
							
						END

					ELSE
						BEGIN
							PRINT 'DELETE'
							SET @AuthorisationStatus ='DP'
							
						END

						---FIND CREATED BY FROM MAIN TABLE
					SELECT  @CreatedBy		= CreatedBy
							,@DateCreated	= DateCreated 
					FROM DimBranch  
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND BranchCode = @BranchCode	
	
				---FIND CREATED BY FROM MAIN TABLE IN CASE OF DATA IS NOT AVAILABLE IN MAIN TABLE
				IF ISNULL(@CreatedBy,'')=''
				BEGIN
					PRINT 'NOT AVAILABLE IN MAIN'
					SELECT  @CreatedBy		= CreatedBy
							,@DateCreated	= DateCreated 
					FROM DimBranch_Mod 
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND BranchCode = @BranchCode 						
							AND AuthorisationStatus IN('NP','MP','A','RM')
															
				END
				ELSE ---IF DATA IS AVAILABLE IN MAIN TABLE
					BEGIN
					       Print 'AVAILABLE IN MAIN'
						----UPDATE FLAG IN MAIN TABLES AS MP
						UPDATE DimBranch
							SET AuthorisationStatus=@AuthorisationStatus
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
								AND BranchCode = @BranchCode
					END
				
				--UPDATE NP,MP  STATUS 
					IF @OperationFlag=2
					BEGIN	

						UPDATE DimBranch_Mod
							SET AuthorisationStatus='FM'
							,ModifyBy=@Modifiedby
							,DateModified=@DateModified
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
								AND BranchCode = @BranchCode
								AND AuthorisationStatus IN('NP','MP','RM')
					END

					GOTO BranchMaster_Insert
					BranchMaster_Insert_Edit_Delete:
			END
		
		ELSE IF @OperationFlag =3 AND @AuthMode ='N'
		BEGIN
		-- DELETE WITHOUT MAKER CHECKER
											
						SET @Modifiedby   = @CrModApBy 
						SET @DateModified = GETDATE() 

						UPDATE DimBranch SET
									ModifyBy =@Modifiedby 
									,DateModified =@DateModified 
									,EffectiveToTimeKey =@EffectiveFromTimeKey-1
								WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey AND EffectiveToTimeKey>=@TimeKey) AND BranchCode = @BranchCode
				

		END
	
	ELSE IF @OperationFlag=17 AND @AuthMode ='Y' 
		BEGIN
				SET @ApprovedBy	   = @CrModApBy 
				SET @DateApproved  = GETDATE()

				UPDATE DimBranch_Mod SET 
					AuthorisationStatus='R'
					,ApprovedBy	 =@ApprovedBy
					,DateApproved=@DateApproved
					,EffectiveToTimeKey =@EffectiveFromTimeKey-1
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
						AND BranchCode=@BranchCode
						AND AuthorisationStatus in('NP','MP','DP','RM')	

				IF EXISTS(SELECT 1 FROM DimBranch WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@Timekey) AND BranchCode=@BranchCode)
				BEGIN
					UPDATE DimBranch
						SET AuthorisationStatus='A'
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND BranchCode=@BranchCode
							AND AuthorisationStatus IN('MP','DP','RM') 	
				END
		END
	ELSE IF @OperationFlag=18
	BEGIN
		PRINT 18
		SET @ApprovedBy=@CrModApBy
		SET @DateApproved=GETDATE()
		UPDATE DimBranch_Mod
		SET AuthorisationStatus='RM'
		WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
		AND AuthorisationStatus IN('NP','MP','DP','RM')
		AND BranchCode=@BranchCode
	END 
	
	ELSE IF @OperationFlag=16 OR @AuthMode='N'
		BEGIN
			
			Print 'Authorise'
	-------set parameter for  maker checker disabled
			IF @AuthMode='N'
			BEGIN
				IF @OperationFlag=1
					BEGIN
						SET @CreatedBy =@CrModApBy
						SET @DateCreated =GETDATE()
					END
				ELSE
					BEGIN
						SET @ModifiedBy  =@CrModApBy
						SET @DateModified =GETDATE()
						SELECT	@CreatedBy=CreatedBy,@DateCreated=DATECreated
						FROM DimBranch
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey )
							AND BranchCode=@BranchCode
					
						SET @ApprovedBy = @CrModApBy			
						SET @DateApproved=GETDATE()
					END
			END	
			
			---set parameters and UPDATE mod table in case maker checker enabled
			IF @AuthMode='Y'
				BEGIN
				    Print 'B'
					DECLARE @DelStatus CHAR(2)
					DECLARE @CurrRecordFromTimeKey smallint=0

					Print 'C'
					SELECT @ExBranchKey= MAX(Branch_Key) FROM DimBranch_Mod
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 
							AND BranchCode=@BranchCode
							AND AuthorisationStatus IN('NP','MP','DP','RM')	

					SELECT	@DelStatus=AuthorisationStatus,@CreatedBy=CreatedBy,@DateCreated=DATECreated
						,@ModifiedBy= ModifyBY, @DateModified=DateModified
					 FROM DimBranch_Mod
						WHERE Branch_Key=@ExBranchKey
					
					SET @ApprovedBy = @CrModApBy			
					SET @DateApproved=GETDATE()
				
					
					DECLARE @CurEntityKey INT=0

					SELECT @ExBranchKey= MIN(Branch_Key) FROM DimBranch_Mod
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 
							AND BranchCode=@BranchCode
							AND AuthorisationStatus IN('NP','MP','DP','RM')

					SELECT	@CurrRecordFromTimeKey=EffectiveFromTimeKey 
						 FROM DimBranch_Mod
							WHERE Branch_Key=@ExBranchKey

					UPDATE DimBranch_Mod
						SET  EffectiveToTimeKey =@CurrRecordFromTimeKey-1
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)
						AND BranchCode=@BranchCode
						AND AuthorisationStatus='A'	

				-------DELETE RECORD AUTHORISE
					IF @DelStatus='DP' 
					BEGIN	
						UPDATE DimBranch_Mod
						SET AuthorisationStatus ='A'
							,ApprovedBy=@ApprovedBy
							,DateApproved=@DateApproved
							,EffectiveToTimeKey =@EffectiveFromTimeKey -1
						WHERE BranchCode=@BranchCode
							AND AuthorisationStatus in('NP','MP','DP','RM')
						
						IF EXISTS(SELECT 1 FROM DimBranch WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
										AND BranchCode=@BranchCode)
						BEGIN
								UPDATE DimBranch
									SET AuthorisationStatus ='A'
										,ModifyBy=@ModifiedBy
										,DateModified=@DateModified
										,ApprovedBy=@ApprovedBy
										,DateApproved=@DateApproved
										,EffectiveToTimeKey =@EffectiveFromTimeKey-1
									WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)
											AND BranchCode=@BranchCode
						END
					END -- END OF DELETE BLOCK

					ELSE  -- OTHER THAN DELETE STATUS
					BEGIN
							UPDATE DimBranch_Mod
								SET AuthorisationStatus ='A'
									,ApprovedBy=@ApprovedBy
									,DateApproved=@DateApproved
								WHERE BranchCode=@BranchCode				
									AND AuthorisationStatus in('NP','MP','RM')
					END		
				END
		


		---select @DelStatus
		IF @DelStatus <>'DP' OR @AuthMode ='N'
				BEGIN
					print 'data inert in main table '
						DECLARE @IsAvailable CHAR(1)='N'
						,@IsSCD2 CHAR(1)='N'

						IF EXISTS(SELECT 1 FROM DimBranch WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
									 AND BranchCode=@BranchCode)
							BEGIN
								SET @IsAvailable='Y'
								SET @AuthorisationStatus='A'

								IF EXISTS(SELECT 1 FROM DimBranch WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
												AND EffectiveFromTimeKey=@TimeKey AND BranchCode=@BranchCode)
								
									BEGIN
											PRINT 'BBBB'
										UPDATE DimBranch SET
												
												BranchCode					= @BranchCode
												,BranchName					= @BranchName
												,BranchOpenDt				= @BranchOpenDt
												,BranchRegionAlt_Key		= @BranchRegionAlt_Key
												,BranchRegion				= @BranchRegion
												,BranchZoneAlt_Key			= @BranchZoneAlt_Key
												,BranchZone					= @BranchZone
												,RBI_Part_1					= @RBIPart1
												,RBI_Part_2					= @RBIPart2
												,BranchAreaCategoryAlt_Key	= @AreaAlt_Key
												--,BranchAreaCategoryAlt_Key	= @BranchAreaCatAlt_Key
												,BranchAreaCategory			= @BranchAreaCat
												,Add_1						= @Add1
												,Add_2						= @Add2
												,Add_3						= @Add3
												,CityAlt_Key				= @CityAlt_Key
												,Place						= @Place
												,PinCode					= @Pincode
												,BranchDistrictAlt_Key		= @DistrictAlt_Key
												,BranchDistrictName			= @BranchDistrictName
												--,BranchDistrictName			= @District
												,BranchStateAlt_Key			= @StateAlt_Key
												,BranchStateName			= @BranchStateName
												--,BranchStateName			= @State
												,ModifyBy					= @ModifiedBy
												,DateModified				= @DateModified
												,ApprovedBy					= CASE WHEN @AuthMode ='Y' THEN @ApprovedBy ELSE NULL END
												,DateApproved				= CASE WHEN @AuthMode ='Y' THEN @DateApproved ELSE NULL END
												,AuthorisationStatus		= CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END
											 WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
												AND EffectiveFromTimeKey=@EffectiveFromTimeKey AND BranchCode=@BranchCode
									END	

									ELSE
										BEGIN
											SET @IsSCD2='Y'
										END
								END

								IF @IsAvailable='N' OR @IsSCD2='Y'
									BEGIN

									print 'main table '
										INSERT INTO DimBranch
										(
											BranchCode
											,BranchName
											,BranchOpenDt
											,BranchRegionAlt_Key
											,BranchRegion
											,BranchZoneAlt_Key
											,BranchZone
											,RBI_Part_1
											,RBI_Part_2
											,BranchAreaCategoryAlt_Key
											,BranchAreaCategory
											,Add_1
											,Add_2
											,Add_3
											,CityAlt_Key
											,Place
											,PinCode
											,BranchDistrictAlt_Key
											,BranchDistrictName
											,BranchStateAlt_Key
											,BranchStateName
											,AuthorisationStatus
											,EffectiveFromTimeKey
											,EffectiveToTimeKey
											,CreatedBy 
											,DateCreated
											,ModifyBy
											,DateModified
											,ApprovedBy
											,DateApproved
										)

										SELECT
											@BranchCode
											,@BranchName
											,@BranchOpenDt
											,@BranchRegionAlt_Key
											,@BranchRegion
											,@BranchZoneAlt_Key
											,@BranchZone
											,@RBIPart1
											,@RBIPart2
											,@AreaAlt_Key
											--,@BranchAreaCatAlt_Key
											,@BranchAreaCat
											,@Add1
											,@Add2
											,@Add3
											,@CityAlt_Key
											,@Place
											,@Pincode
											,@DistrictAlt_Key
											,@BranchDistrictName
											--,@District
											,@StateAlt_Key
											,@BranchStateName
											--,@State
											,CASE WHEN @AUTHMODE= 'Y' THEN   @AuthorisationStatus ELSE NULL END
											,@EffectiveFromTimeKey
											,@EffectiveToTimeKey
											,@CreatedBy
											,@DateCreated
											,CASE WHEN @AuthMode='Y' OR @IsAvailable='Y' THEN @ModifiedBy  ELSE NULL END
											,CASE WHEN @AuthMode='Y' OR @IsAvailable='Y' THEN @DateModified  ELSE NULL END
											,CASE WHEN @AUTHMODE= 'Y' THEN    @ApprovedBy ELSE NULL END
											,CASE WHEN @AUTHMODE= 'Y' THEN    @DateApproved  ELSE NULL END
									END


									IF @IsSCD2='Y' 
									BEGIN
										UPDATE DimBranch SET
											EffectiveToTimeKey=@EffectiveFromTimeKey-1
											,AuthorisationStatus =CASE WHEN @AUTHMODE='Y' THEN  'A' ELSE NULL END
											 WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey AND EffectiveToTimeKey>=@TimeKey) AND BranchCode=@BranchCode
											AND EffectiveFromTimekey<@EffectiveFromTimeKey
									END
							END

		IF @AUTHMODE='N'
			BEGIN
					SET @AuthorisationStatus='A'
					GOTO BranchMaster_Insert
					HistoryRecordInUp:
			END						
	END

	----***********maintain log table

	--IF @OperationFlag IN(1,2,3,16,17,18) AND @AuthMode ='Y'
	--		BEGIN
	--	PRINT 5
	--			IF @OperationFlag=2 
	--				BEGIN 

	--					SET @CreatedBy=@ModifiedBy
	--				--end

	--			END
	--				IF @OperationFlag IN(16,17) 
	--					BEGIN 
	--						SET @DateCreated= GETDATE()
					
	--							EXEC LogDetailsInsertUpdate_Attendence -- MAINTAIN LOG TABLE
	--								@BranchCode ,
	--								@MenuID,
	--								@AccountEntityId,-- ReferenceID ,
	--								@CreatedBy,
	--								@ApprovedBy,-- @ApproveBy 
	--								@DateCreated,
	--								@Remark,
	--								@ScreenEntityId, -- for FXT060 screen
	--								@OperationFlag,
	--								@AuthMode
	--					END
	--				ELSE
	--					BEGIN
	--						EXEC LogDetailsInsertUpdate_Attendence -- MAINTAIN LOG TABLE
	--							@BranchCode ,
	--							@MenuID,
	--							@AccountEntityId ,-- ReferenceID ,
	--							@CreatedBy,
	--							NULL,-- @ApproveBy 
	--							@DateCreated,
	--							@Remark,
	--							@ScreenEntityId, -- for FXT060 screen
	--							@OperationFlag,
	--							@AuthMode
	--					END
	--		END	

		--****************************

PRINT 6
SET @ErrorHandle=1

BranchMaster_Insert:
IF @ErrorHandle=0
	begin
	print 'inert in mod table '
		INSERT INTO DimBranch_Mod
		(
				BranchCode
				,BranchName
				,BranchOpenDt
				,BranchRegionAlt_Key
				,BranchRegion
				,BranchZoneAlt_Key
				,BranchZone
				,RBI_Part_1
				,RBI_Part_2
				,BranchAreaCategoryAlt_Key
				,BranchAreaCategory
				,Add_1
				,Add_2
				,Add_3
				,CityAlt_Key
				,Place
				,PinCode
				,BranchDistrictAlt_Key
				,BranchDistrictName
				,BranchStateAlt_Key
				,BranchStateName
				,AuthorisationStatus
				,EffectiveFromTimeKey
				,EffectiveToTimeKey
				,CreatedBy 
				,DateCreated
				,ModifyBy
				,DateModified
				,ApprovedBy
				,DateApproved
				,ChangeFields
		)
		VALUES
		(
				@BranchCode
				,@BranchName
				,@BranchOpenDt
				,@BranchRegionAlt_Key
				,@BranchRegion
				,@BranchZoneAlt_Key
				,@BranchZone
				,@RBIPart1
				,@RBIPart2
				,@AreaAlt_Key
				--,@BranchAreaCatAlt_Key
				,@BranchAreaCat
				,@Add1
				,@Add2
				,@Add3
				,@CityAlt_Key
				,@Place
				,@Pincode
				,@DistrictAlt_Key
				,@BranchDistrictName
				--,@District
				,@StateAlt_Key
				,@BranchStateName
				--,@State
				,@AuthorisationStatus
				,@EffectiveFromTimeKey
				,@EffectiveToTimeKey
				,@CreatedBy
				,@DateCreated
				,CASE WHEN @AuthMode='Y' OR @IsAvailable='Y' THEN @ModifiedBy ELSE NULL END
				,CASE WHEN @AuthMode='Y' OR @IsAvailable='Y' THEN @DateModified ELSE NULL END
				,CASE WHEN @AuthMode='Y' THEN @ApprovedBy    ELSE NULL END
				,CASE WHEN @AuthMode='Y' THEN @DateApproved  ELSE NULL END
				,@Branch_ChangeFields
			
		)
		----//ADDED BY SHAKTI
		UPDATE DimBranch_Mod  SET BranchAreaCategoryAlt_Key =AreaAlt_Key FROM DIMAREA D
		INNER JOIN DimBranch_Mod
		ON D.AREANAME=DimBranch_Mod.BranchAreaCategory
 
		IF @OperationFlag =1 AND @AUTHMODE='Y'
					BEGIN
						PRINT 3
						GOTO BranchMaster_Insert_Add
					END
				ELSE IF (@OperationFlag =2 OR @OperationFlag =3)AND @AUTHMODE='Y'
					BEGIN
						GOTO BranchMaster_Insert_Edit_Delete
					END
	end
	-------------------
PRINT 7
		COMMIT TRANSACTION

																

		SELECT @D2Ktimestamp=CAST(D2Ktimestamp AS INT) FROM DimBranch WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey AND EffectiveToTimeKey>=@TimeKey) 
																	AND BranchCode=@BranchCode

		IF @OperationFlag =3
			BEGIN
				SET @Result=0
			END
		ELSE
			BEGIN
				SET @Result=1
			END
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	SELECT ERROR_MESSAGE()
	RETURN -1

END CATCH
---------

END
GO