SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author Triloki Kumar>
-- Create date: <Create 05/12/2017>
-- Description:	<Description Dim Product Insert Update>
-- =============================================
CREATE PROCEDURE [dbo].[DimProductInUp]
	 @ProductAlt_Key			SMALLINT
	 ,@ProductCode				VARCHAR(10)
	 ,@ProductName				VARCHAR(100)
	 ,@AgriFlag					CHAR(1)
	 ,@ChangeFields				VARCHAR(250)
	 ,@OperationFlag			INT
	 ,@AuthMode					CHAR(1)	= 'N'	
	 ,@EffectiveFromTimeKey		INT		= 0
	 ,@EffectiveToTimeKey		INT		= 0
	 ,@TimeKey					INT		= 0
	 ,@CrModApBy				VARCHAR(20)	=''
	 ,@D2Ktimestamp				INT	=0 OUTPUT	
	 ,@Result					INT	=0 OUTPUT
AS

	--DECLARE 
	-- @ProductAlt_Key			SMALLINT=770
	-- ,@ProductCode				VARCHAR(10)='632'
	-- ,@ProductName				VARCHAR(100)='INDUSIND SIGNATURE'
	-- ,@AgriFlag					CHAR(1)='Y'
	-- ,@ChangeFields				VARCHAR(250)=''
	-- ,@OperationFlag			INT=2
	-- ,@AuthMode					CHAR(1)	= 'N'	
	-- ,@EffectiveFromTimeKey		INT		= 24811
	-- ,@EffectiveToTimeKey		INT		= 49999
	-- ,@TimeKey					INT		= 24811
	-- ,@CrModApBy				VARCHAR(20)	='D2K'
	-- ,@D2Ktimestamp				INT	=0 	
	-- ,@Result					INT	=0 
BEGIN	
	SET NOCOUNT ON;

	DECLARE 
						@AuthorisationStatus		CHAR(2)			= NULL 
						,@CreatedBy					VARCHAR(20)		= NULL
						,@DateCreated				SMALLDATETIME	= NULL
						,@ModifiedBy				VARCHAR(20)		= NULL
						,@DateModified				SMALLDATETIME	= NULL
						,@ApprovedBy				VARCHAR(20)		= NULL
						,@DateApproved				SMALLDATETIME	= NULL
						,@ExCustomer_Key			INT				= 0
					    ,@ErrorHandle				int				= 0
						,@ExEntityKey				int				= 0  
						,@Product_Key				INT

	
	BEGIN TRY
	BEGIN TRANSACTION	
	-----
	
			SELECT @Product_Key=MAX(Product_Key) FROM DIMPRODUCT WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)

	PRINT 3	

			 IF @OperationFlag = 2 AND @AuthMode = 'Y' --EDIT AND DELETE
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

					

						---FIND CREATED BY FROM MAIN TABLE
					SELECT  @CreatedBy		= CreatedBy
							,@DateCreated	= DateCreated 
					FROM DIMPRODUCT
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND ProductCode =@ProductCode

				---FIND CREATED BY FROM MAIN TABLE IN CASE OF DATA IS NOT AVAILABLE IN MAIN TABLE
				IF ISNULL(@CreatedBy,'')=''
				BEGIN
					PRINT 'NOT AVAILABLE IN MAIN'
					SELECT  @CreatedBy		= CreatedBy
							,@DateCreated	= DateCreated 
					FROM DIMPRODUCT_MOD 
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND ProductCode =@ProductCode					
							AND AuthorisationStatus IN('NP','MP','A','RM')
															
				END
				ELSE ---IF DATA IS AVAILABLE IN MAIN TABLE
					BEGIN
					       Print 'AVAILABLE IN MAIN'
						----UPDATE FLAG IN MAIN TABLES AS MP
						UPDATE DIMPRODUCT
							SET AuthorisationStatus=@AuthorisationStatus
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
								AND ProductCode =@ProductCode

					END

					--UPDATE NP,MP  STATUS 
					IF @OperationFlag=2
					BEGIN	
					PRINT 'FM'
						UPDATE DIMPRODUCT_MOD
							SET AuthorisationStatus='FM'
							,ModifiedBy=@Modifiedby
							,DateModifie=@DateModified
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
								AND ProductCode =@ProductCode			
								AND AuthorisationStatus IN('NP','MP','RM')
					END

					GOTO DIMPRODUCT_Insert
							DIMPRODUCT_Insert_Edit_Delete:
				END

		--ELSE IF @OperationFlag =3 AND @AuthMode ='N'
		--BEGIN
		---- DELETE WITHOUT MAKER CHECKER
											
		--				SET @Modifiedby   = @CrModApBy 
		--				SET @DateModified = GETDATE() 

		--				UPDATE DIMPRODUCT SET
		--							ModifiedBy =@Modifiedby 
		--							,DateModifie =@DateModified 
		--							,EffectiveToTimeKey =@EffectiveFromTimeKey-1
		--						WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey AND EffectiveToTimeKey>=@TimeKey) AND  ProductCode =@ProductCode			
				

		--end
	
	
	ELSE IF @OperationFlag=17 AND @AuthMode ='Y' 
		BEGIN
				SET @ApprovedBy	   = @CrModApBy 
				SET @DateApproved  = GETDATE()

				UPDATE DIMPRODUCT_MOD
					SET AuthorisationStatus='R'
					,ApprovedBy	 =@ApprovedBy
					,DateApproved=@DateApproved
					,EffectiveToTimeKey =@EffectiveFromTimeKey-1
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
						AND ProductCode =@ProductCode			
						AND AuthorisationStatus in('NP','MP','DP','RM')	

				IF EXISTS(SELECT 1 FROM DIMPRODUCT WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@Timekey) AND ProductCode =@ProductCode)
				BEGIN
					UPDATE DIMPRODUCT
						SET AuthorisationStatus='A'
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND ProductCode =@ProductCode			
							AND AuthorisationStatus IN('MP','DP','RM') 	
				END
		END	

	ELSE IF @OperationFlag=18
	BEGIN
		PRINT 18
		SET @ApprovedBy=@CrModApBy
		SET @DateApproved=GETDATE()
		UPDATE DIMPRODUCT_MOD
		SET AuthorisationStatus='RM'
		WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
		AND AuthorisationStatus IN('NP','MP','DP','RM')
		AND ProductCode =@ProductCode			

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
					 FROM DIMPRODUCT
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey )
							AND ProductCode =@ProductCode			
					
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
					SELECT @ExEntityKey= MAX(Product_Key) FROM DIMPRODUCT_MOD 
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 
							AND ProductCode =@ProductCode			
							AND AuthorisationStatus IN('NP','MP','DP','RM')	

					SELECT	@DelStatus=AuthorisationStatus,@CreatedBy=CreatedBy,@DateCreated=DATECreated
						,@ModifiedBy=ModifiedBy, @DateModified=DateModifie
					 FROM DIMPRODUCT_MOD
						WHERE Product_Key=@ExEntityKey
					
					SET @ApprovedBy = @CrModApBy			
					SET @DateApproved=GETDATE()
				
					
					DECLARE @CurEntityKey INT=0

					SELECT @ExEntityKey= MIN(Product_Key) FROM DIMPRODUCT_MOD 
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 
							AND ProductCode =@ProductCode	
							AND AuthorisationStatus IN('NP','MP','DP','RM')	
				
					SELECT	@CurrRecordFromTimeKey=EffectiveFromTimeKey 
						 FROM DIMPRODUCT_MOD
							WHERE Product_Key=@ExEntityKey

					UPDATE DIMPRODUCT_MOD
						SET  EffectiveToTimeKey =@CurrRecordFromTimeKey-1
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)
						AND ProductCode =@ProductCode	
						AND AuthorisationStatus='A'	


					-------DELETE RECORD AUTHORISE
					IF @DelStatus='DP' 
					BEGIN	
						UPDATE DIMPRODUCT_MOD
						SET AuthorisationStatus ='A'
							,ApprovedBy=@ApprovedBy
							,DateApproved=@DateApproved
							,EffectiveToTimeKey =@EffectiveFromTimeKey -1
						WHERE ProductCode =@ProductCode
							AND AuthorisationStatus in('NP','MP','DP','RM')
						
						IF EXISTS(SELECT 1 FROM DIMPRODUCT WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
										AND ProductCode =@ProductCode)
						BEGIN
								UPDATE DIMPRODUCT
									SET AuthorisationStatus ='A'
										,ModifiedBy=@ModifiedBy
										,DateModifie=@DateModified
										,ApprovedBy=@ApprovedBy
										,DateApproved=@DateApproved
										,EffectiveToTimeKey =@EffectiveFromTimeKey-1
									WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)
											AND ProductCode =@ProductCode
						END
					END -- END OF DELETE BLOCK

					ELSE  -- OTHER THAN DELETE STATUS
					BEGIN
							UPDATE DIMPRODUCT_MOD
								SET AuthorisationStatus ='A'
									,ApprovedBy=@ApprovedBy
									,DateApproved=@DateApproved
								WHERE ProductCode =@ProductCode				
									AND AuthorisationStatus in('NP','MP','RM')
					END	
				
				END



			IF @DelStatus <>'DP' OR @AuthMode ='N'
				BEGIN
						DECLARE @IsAvailable CHAR(1)='N'
						,@IsSCD2 CHAR(1)='N'

						IF EXISTS(SELECT 1 FROM DIMPRODUCT WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
									AND ProductCode =@ProductCode)
							BEGIN
								SET @IsAvailable='Y'
								SET @AuthorisationStatus='A'


								IF EXISTS(SELECT 1 FROM DIMPRODUCT WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
												AND EffectiveFromTimeKey=@EffectiveFromTimeKey AND ProductCode =@ProductCode)
									BEGIN
											PRINT 'BBBB'
										UPDATE DIMPRODUCT SET																								
												ProductName				=@ProductName
												,ModifiedBy					= @ModifiedBy
												,DateModifie				= @DateModified
												,ApprovedBy					= CASE WHEN @AuthMode ='Y' THEN @ApprovedBy ELSE NULL END
												,DateApproved				= CASE WHEN @AuthMode ='Y' THEN @DateApproved ELSE NULL END
												,AuthorisationStatus		= CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END
											 WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
												AND EffectiveFromTimeKey=@EffectiveFromTimeKey AND ProductCode =@ProductCode
									END	

									ELSE
										BEGIN
											SET @IsSCD2='Y'
										END
								END

								IF @IsAvailable='N' OR @IsSCD2='Y'
									BEGIN
										INSERT INTO DIMPRODUCT
												(
													Product_Key
													,ProductAlt_Key
													,ProductCode
													,ProductName
													,ProductShortName
													,ProductShortNameEnum
													,ProductGroup
													,ProductSubGroup
													,ProductSegment
													,ProductValidCode
													,SrcSysProductCode
													,SrcSysProductName
													,DestSysProductCode
													,AuthorisationStatus
													,EffectiveFromTimeKey
													,EffectiveToTimeKey
													,CreatedBy
													,DateCreated
													,ModifiedBy
													,DateModifie
													,ApprovedBy
													,DateApproved													
													,AgriFlag	
												)

										SELECT
													@Product_Key + 1
													,@ProductAlt_Key
													,@ProductCode
													,@ProductName
													,NULL AS ProductShortName
													,NULL AS ProductShortNameEnum
													,NULL AS ProductGroup
													,NULL AS ProductSubGroup
													,NULL AS ProductSegment
													,NULL AS ProductValidCode
													,NULL AS SrcSysProductCode
													,NULL AS SrcSysProductName
													,NULL AS DestSysProductCode
													,CASE WHEN @AUTHMODE= 'Y' THEN   @AuthorisationStatus ELSE NULL END
													,@EffectiveFromTimeKey
													,@EffectiveToTimeKey
													,@CreatedBy 
													,@DateCreated
													,@ModifiedBy 
													,@DateModified 
													,CASE WHEN @AUTHMODE= 'Y' THEN    @ApprovedBy ELSE NULL END
													,CASE WHEN @AUTHMODE= 'Y' THEN    @DateApproved  ELSE NULL END
													,@AgriFlag
										
									END


									IF @IsSCD2='Y' 
								BEGIN
								UPDATE DIMPRODUCT SET
										EffectiveToTimeKey=@EffectiveFromTimeKey-1
										,AuthorisationStatus =CASE WHEN @AUTHMODE='Y' THEN  'A' ELSE NULL END
									WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey AND EffectiveToTimeKey>=@TimeKey) AND ProductCode=@ProductCode
											AND EffectiveFromTimekey<@EffectiveFromTimeKey
								END
							END

			IF @AuthMode='N'
				BEGIN
						SET @AuthorisationStatus='A'
						GOTO DIMPRODUCT_Insert
						HistoryRecordsInUp:
				END

								
		END 

	
PRINT 6
SET @ErrorHandle=1

DIMPRODUCT_Insert:
IF @ErrorHandle=0
	BEGIN
			SELECT @Product_Key=ISNULL(MAX(Product_Key),0) FROM DIMPRODUCT_MOD WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
			INSERT INTO DIMPRODUCT_MOD  
											( 
												Product_Key
												,ProductAlt_Key
												,ProductCode
												,ProductName
												,ProductShortName
												,ProductShortNameEnum
												,ProductGroup
												,ProductSubGroup
												,ProductSegment
												,ProductValidCode
												,SrcSysProductCode
												,SrcSysProductName
												,DestSysProductCode
												,AuthorisationStatus	
												,EffectiveFromTimeKey
												,EffectiveToTimeKey
												,CreatedBy
												,DateCreated
												,ModifiedBy
												,DateModifie
												,ApprovedBy
												,DateApproved
												,ChangeFields
												
											)
								SELECT
											
													@Product_Key + 1
													,@ProductAlt_Key
													,@ProductCode
													,@ProductName
													,NULL AS ProductShortName
													,NULL AS ProductShortNameEnum
													,NULL AS ProductGroup
													,NULL AS ProductSubGroup
													,NULL AS ProductSegment
													,NULL AS ProductValidCode
													,NULL AS SrcSysProductCode
													,NULL AS SrcSysProductName
													,NULL AS DestSysProductCode
													,@AuthorisationStatus
													,@EffectiveFromTimeKey
													,@EffectiveToTimeKey 
													,@CreatedBy
													,@DateCreated
													,@ModifiedBy
													,@DateModified
													,@ApprovedBy 
													,@DateApproved 
													,@ChangeFields
												
										
	



		        
				 IF (@OperationFlag =2)AND @AUTHMODE='Y'
					BEGIN
						GOTO DIMPRODUCT_Insert_Edit_Delete
					END

				

				
	END




	-------------------
PRINT 7
		COMMIT TRANSACTION

		SELECT @D2Ktimestamp=CAST(D2Ktimestamp AS INT) FROM DIMPRODUCT WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey AND EffectiveToTimeKey>=@TimeKey) 
																	AND ProductCode=@ProductCode

		IF @OperationFlag =3
			BEGIN
				RETURN 0
			END
		ELSE
			BEGIN
			PRINT 8
				RETURN @ProductCode
			END
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	SELECT ERROR_MESSAGE()
	RETURN -1

END CATCH
  
END
GO