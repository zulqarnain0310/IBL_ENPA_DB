SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author Triloki Kumar>
-- Create date: <Create 05/12/2017>
-- Description:	<Description Dim Product Insert Update>
-- =============================================
CREATE PROCEDURE [dbo].[DimProductInUp_NEW_13082021]

	 @xmlDocument				XML	
	 ,@Userid					varchar(30)
	 ,@OperationFlag			INT
	 ,@AuthMode					CHAR(1)	= 'N'	
	 ,@EffectiveFromTimeKey		INT		= 0
	 ,@EffectiveToTimeKey		INT		= 0
	 ,@TimeKey					INT		= 0
	 ,@CrModApBy				VARCHAR(20)	=''	 
	 ,@Result					INT	=0 OUTPUT
	 ,@D2Ktimestamp				INT	=0 OUTPUT	
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
						,@Product_Key				INT				=0




		IF OBJECT_ID('TEMPDB..#DimProduct')IS NOT NULL
			DROP TABLE #DimProduct
				SELECT 
				c.value('./ProductAlt_Key[1]','SmallInt')ProductAlt_Key
				,c.value('./ProductCode[1]','varchar(10)')ProductCode
				,c.value('./ProductName[1]','varchar(100)')ProductName
				,c.value('./AgriFlag[1]','char(1)')AgriFlag				
				,c.value('./ChangeFields[1]','varchar(250)')ChangeFields	
				,CASE WHEN c.value('./ApprovedAll[1]','varchar(5)') ='true' THEN 'Y' ELSE 'N' END AS ApproveAll
				,CASE WHEN c.value('./RejectAll[1]','varchar(5)')='true' THEN 'Y'ELSE 'N' END AS RejectAll			
				INTO #DimProduct
			  FROM @xmlDocument.nodes('/DataSet/GridData') AS t(c)  --/DataSet/GridData
	

			--select * from #DimProduct
	BEGIN TRY
	BEGIN TRANSACTION	
	-----
	 DECLARE
	  @ApprovedAll  CHAR(1)='N'
	 ,@RejectAll   CHAR(1)='N'
			SELECT @Product_Key=MAX(Product_Key) FROM DIMPRODUCT WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)

	IF EXISTS(SELECT 1 FROM #DimProduct WHERE ApproveAll='Y' AND RejectAll='N')
	BEGIN
				SET @ApprovedAll='Y'

	END

IF EXISTS(SELECT 1 FROM #DimProduct WHERE RejectAll='Y' AND ApproveAll='N')
	BEGIN
				SET @RejectAll='Y'
	END

--IF EXISTS(SELECT 1 FROM #DimProduct WHERE ApproveAll='Y' AND RejectAll='N')
--	BEGIN
--				SET  @RejectAll='Y'
--				SET  @ApprovedAll='Y'
--	END
 PRINT @RejectAll
PRINT   @ApprovedAll
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
					SELECT  @CreatedBy		= A.CreatedBy
							,@DateCreated	= A.DateCreated 
					FROM DIMPRODUCT A	
						INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							
				---FIND CREATED BY FROM MAIN TABLE IN CASE OF DATA IS NOT AVAILABLE IN MAIN TABLE
				IF ISNULL(@CreatedBy,'')=''
				BEGIN
					PRINT 'NOT AVAILABLE IN MAIN'
					SELECT  @CreatedBy		= A.CreatedBy
							,@DateCreated	= A.DateCreated 
					FROM DIMPRODUCT_MOD A
						INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)								
							AND AuthorisationStatus IN('NP','MP','A','RM')
															
				END
				ELSE ---IF DATA IS AVAILABLE IN MAIN TABLE
					BEGIN
					       Print 'AVAILABLE IN MAIN'
						----UPDATE FLAG IN MAIN TABLES AS MP
						UPDATE A 
							SET A.AuthorisationStatus=@AuthorisationStatus
						FROM DIMPRODUCT A
							INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
								

					END

					--UPDATE NP,MP  STATUS 
					IF @OperationFlag=2
					BEGIN	
					PRINT 'FM'
						UPDATE A
							SET A.AuthorisationStatus='FM'
							,A.ModifiedBy=@Modifiedby
							,A.DateModifie=@DateModified
						FROM DIMPRODUCT_MOD A
							INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)											
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

				UPDATE A
					SET A.AuthorisationStatus='R'
					,A.ApprovedBy	 =@ApprovedBy
					,A.DateApproved=@DateApproved
					,A.EffectiveToTimeKey =@EffectiveFromTimeKey-1
				FROM DIMPRODUCT_MOD A
					INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)							
						AND AuthorisationStatus in('NP','MP','DP','RM')	

				IF EXISTS(SELECT 1 FROM DIMPRODUCT A
								INNER JOIN #DimProduct B
									ON A.ProductCode=B.ProductCode
									AND A.ProductAlt_Key=B.ProductAlt_Key
								 WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@Timekey) 
							)
				BEGIN
					UPDATE A
						SET A.AuthorisationStatus='A'
					FROM DIMPRODUCT A
						INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)									
							AND AuthorisationStatus IN('MP','DP','RM') 	
				END
		END	

	ELSE IF @OperationFlag=18
	BEGIN
		PRINT 18
		SET @ApprovedBy=@CrModApBy
		SET @DateApproved=GETDATE()
		UPDATE A
		SET A.AuthorisationStatus='RM'
		FROM DIMPRODUCT_MOD A
			INNER JOIN #DimProduct B
				ON A.ProductCode=B.ProductCode
				AND A.ProductAlt_Key=B.ProductAlt_Key
		WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
		AND AuthorisationStatus IN('NP','MP','DP','RM')
					

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


					SELECT	@CreatedBy=A.CreatedBy
							,@DateCreated=A.DATECreated
					 FROM DIMPRODUCT A
						INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey )
								
					
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
					SELECT @ExEntityKey= MAX(A.Product_Key) FROM DIMPRODUCT_MOD A
							INNER JOIN #DimProduct B
								ON A.ProductCode=B.ProductCode
								AND A.ProductAlt_Key=B.ProductAlt_Key
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 								
							AND AuthorisationStatus IN('NP','MP','DP','RM')	

					SELECT	@DelStatus=AuthorisationStatus,@CreatedBy=CreatedBy,@DateCreated=DATECreated
						,@ModifiedBy=ModifiedBy, @DateModified=DateModifie
					 FROM DIMPRODUCT_MOD A						
						WHERE Product_Key=@ExEntityKey
					
					SET @ApprovedBy = @CrModApBy			
					SET @DateApproved=GETDATE()
				
					
					DECLARE @CurEntityKey INT=0

					SELECT @ExEntityKey= MIN(A.Product_Key) FROM DIMPRODUCT_MOD A
						INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey) 							
							AND AuthorisationStatus IN('NP','MP','DP','RM')	
				
					SELECT	@CurrRecordFromTimeKey=EffectiveFromTimeKey 
						 FROM DIMPRODUCT_MOD
							WHERE Product_Key=@ExEntityKey
						PRINT @CurrRecordFromTimeKey

					UPDATE A
						SET  A.EffectiveToTimeKey =@CurrRecordFromTimeKey-1
						FROM DIMPRODUCT_MOD A
							INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
						WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)						
						AND AuthorisationStatus='A'	


					-------DELETE RECORD AUTHORISE
					IF @DelStatus='DP' 
					BEGIN	
						UPDATE A
						SET A.AuthorisationStatus ='A'
							,A.ApprovedBy=@ApprovedBy
							,A.DateApproved=@DateApproved
							,A.EffectiveToTimeKey =@EffectiveFromTimeKey -1
						FROM DIMPRODUCT_MOD A
							INNER JOIN #DimProduct B
							ON A.ProductCode=B.ProductCode
							AND A.ProductAlt_Key=B.ProductAlt_Key
						WHERE  AuthorisationStatus in('NP','MP','DP','RM')
						
						IF EXISTS(SELECT 1 FROM DIMPRODUCT A
									INNER JOIN #DimProduct B
										ON A.ProductCode=B.ProductCode
										AND A.ProductAlt_Key=B.ProductAlt_Key											
										WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
									)
						BEGIN
								UPDATE A
									SET A.AuthorisationStatus ='A'
										,A.ModifiedBy=@ModifiedBy
										,A.DateModifie=@DateModified
										,A.ApprovedBy=@ApprovedBy
										,A.DateApproved=@DateApproved
										,A.EffectiveToTimeKey =@EffectiveFromTimeKey-1
									FROM DIMPRODUCT A
										INNER JOIN #DimProduct B
											ON A.ProductCode=B.ProductCode
											AND A.ProductAlt_Key=B.ProductAlt_Key
									WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >=@Timekey)
											
						END
					END -- END OF DELETE BLOCK

					ELSE  -- OTHER THAN DELETE STATUS
					BEGIN
							UPDATE A
								SET A.AuthorisationStatus ='A'
									,A.ApprovedBy=@ApprovedBy
									,A.DateApproved=@DateApproved
								FROM DIMPRODUCT_MOD A
									INNER JOIN #DimProduct B
										ON A.ProductCode=B.ProductCode
										AND A.ProductAlt_Key=B.ProductAlt_Key
										AND B.ApproveAll='Y' 
								WHERE AuthorisationStatus in('NP','MP','RM')
					END	
				
				END



			IF @DelStatus <>'DP' OR @AuthMode ='N'
				BEGIN
						DECLARE @IsAvailable CHAR(1)='N'
						,@IsSCD2 CHAR(1)='N'

					IF @ApprovedAll='Y'
					BEGIN
						IF EXISTS(SELECT 1 FROM DIMPRODUCT A
											INNER JOIN #DimProduct B
												ON A.ProductCode=B.ProductCode
												AND A.ProductAlt_Key=B.ProductAlt_Key
										 WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
								)
							BEGIN
								SET @IsAvailable='Y'
								SET @AuthorisationStatus='A'


								IF EXISTS(SELECT 1 FROM DIMPRODUCT A
													INNER JOIN #DimProduct B
														ON A.ProductCode=B.ProductCode
														AND A.ProductAlt_Key=B.ProductAlt_Key
													WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
													AND EffectiveFromTimeKey=@EffectiveFromTimeKey
											)
									BEGIN
											PRINT 'BBBB'
										UPDATE A SET																								
												A.ProductName					=B.ProductName
												,A.AgriFlag						=B.AgriFlag
												,A.ModifiedBy					= @ModifiedBy
												,A.DateModifie				= @DateModified
												,A.ApprovedBy					= CASE WHEN @AuthMode ='Y' THEN @ApprovedBy ELSE NULL END
												,A.DateApproved				= CASE WHEN @AuthMode ='Y' THEN @DateApproved ELSE NULL END
												,A.AuthorisationStatus		= CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END
											FROM DIMPRODUCT A
												INNER JOIN #DimProduct B
													ON A.ProductCode=B.ProductCode
													AND A.ProductAlt_Key=B.ProductAlt_Key
													AND B.ApproveAll='Y'
											 WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey) 
												AND A.EffectiveFromTimeKey=@EffectiveFromTimeKey 
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
													@Product_Key + ROW_NUMBER()OVER(ORDER BY (SELECT 1))
													,ProductAlt_Key
													,ProductCode
													,ProductName
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
													,AgriFlag
												FROM  #DimProduct 
												WHERE ApproveAll='Y'
													 	
									END				 


									IF @IsSCD2='Y' 
								BEGIN
								UPDATE A SET
										A.EffectiveToTimeKey=@EffectiveFromTimeKey-1
										,A.AuthorisationStatus =CASE WHEN @AUTHMODE='Y' THEN  'A' ELSE NULL END
									FROM DIMPRODUCT A
										INNER JOIN #DimProduct B
											ON A.ProductCode=B.ProductCode
											AND A.ProductAlt_Key=B.ProductAlt_Key
											AND B.ApproveAll='Y'
									WHERE (A.EffectiveFromTimeKey=EffectiveFromTimeKey AND A.EffectiveToTimeKey>=@TimeKey) 
											AND A.EffectiveFromTimekey<@EffectiveFromTimeKey
								END
							END
	
					IF @RejectAll='Y'
						BEGIN
							PRINT 'reject'
							PRINT @RejectAll

							UPDATE A
								SET A.AuthorisationStatus ='R'
									,A.ApprovedBy=@ApprovedBy
									,A.DateApproved=@DateApproved
								FROM DIMPRODUCT_MOD A
									INNER JOIN #DimProduct B
										ON A.ProductCode=B.ProductCode
										AND A.ProductAlt_Key=B.ProductAlt_Key
										AND B.RejectAll='Y'
								WHERE A.AuthorisationStatus in('MP','RM')


							UPDATE A
								SET A.AuthorisationStatus ='A'									
								FROM DIMPRODUCT A
									INNER JOIN #DimProduct B
										ON A.ProductCode=B.ProductCode
										AND A.ProductAlt_Key=B.ProductAlt_Key
										AND B.RejectAll='Y'
								WHERE A.AuthorisationStatus in('MP','RM')

						END
			IF @AuthMode='N'
				BEGIN
						SET @AuthorisationStatus='A'
						GOTO DIMPRODUCT_Insert
						HistoryRecordsInUp:
				END
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
												,AgriFlag
												,ChangeFields
												
											)
								SELECT
											
													@Product_Key + 1
													,ProductAlt_Key
													,ProductCode
													,ProductName
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
													,AgriFlag
													,ChangeFields
												FROM #DimProduct

												
										
	



		        
				 IF (@OperationFlag =2)AND @AUTHMODE='Y'
					BEGIN
						GOTO DIMPRODUCT_Insert_Edit_Delete
					END

				

				
	END




	-------------------
PRINT 7
		COMMIT TRANSACTION

		SELECT @D2Ktimestamp=CAST(D2Ktimestamp AS INT) FROM DIMPRODUCT A
												INNER JOIN #DimProduct B
													ON A.ProductCode=B.ProductCode
													AND A.ProductAlt_Key=B.ProductAlt_Key
											 WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey AND EffectiveToTimeKey>=@TimeKey) 
																	

		IF @OperationFlag =3
			BEGIN
				SET @Result=0
				RETURN @Result	
			END
		ELSE
			BEGIN
			PRINT 8
				SET @Result=1
					RETURN @Result
			END
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	SELECT ERROR_MESSAGE()
	RETURN -1

END CATCH
  
END
GO