SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[MOC_ExcelUploadInUp]
 @XmlDocument  XML
,@OperationFlag	SMALLINT
,@AuthMode      CHAR(2)
,@TimeKey int
,@EffectiveFromTimeKey	INT
,@EffectiveToTimeKey	INT
,@CrModApBy            VARCHAR(20)='D2K'
,@D2Ktimestamp	        TIMESTAMP     =0 OUTPUT 
,@Result                INT   =0 OUTPUT,
 @ErrorMsg				Varchar(max)='' OUTPUT
AS
DECLARE
 @AuthorisationStatus CHAR(2)=NULL	
,@CreatedBy VARCHAR(20) =NULL
,@DateCreated SMALLDATETIME=NULL
,@ModifiedBy VARCHAR(20) =NULL
,@DateModified SMALLDATETIME=NULL
,@ApprovedBy  VARCHAR(20)=NULL
,@DateApproved  SMALLDATETIME=NULL
,@ExEntityKey AS INT=0
,@ErrorHandle INT=0

SET @EffectiveToTimeKey=@EffectiveFromTimeKey

IF OBJECT_ID('TEMPDB..#NCIF_NPAUpload')IS NOT NULL
DROP TABLE #NCIF_NPAUpload 

SELECT
  c.value('./ENTCIF[1]','VARCHAR(30)')ENTCIF
 ,c.value('./SourceSystem[1]','tinyint')SrcSysAlt_Key
 ,c.value('./CustomerID[1]','varchar(80)')CustomerID
 ,c.value('./PAN[1]','varchar(10)')PAN
 ,c.value('./AssetClassAlt_Key[1]','tinyint')AssetClass
 ,c.value('./AssetClass[1]','varchar(10)')AssetClassName
 ,c.value('./NPADate[1]','varchar(10)')NPA_Date
 ,c.value('./Reason[1]','smallint')Reason
 ,c.value('./ReasonRemark[1]','VARCHAR(200)')ReasonRemark
 ,c.value('./RejectionRemark[1]','varchar(150)')RejectionRemark
 ,c.value('./Remark[1]','varchar(200)')MOC_Remark
 ,c.value('./CreatedBy[1]','varchar(20)')CreatedBy
 ,c.value('./DateCreated[1]','smalldatetime')DateCreated
 ,c.value('./ModifiedBy[1]','varchar(20)')ModifiedBy
 ,c.value('./DateModified[1]','smalldatetime')DateModified
 INTO #NCIF_NPAUpload
 FROM @XmlDocument.nodes('DataSet/GridData') AS t(c)

 	SET @ErrorMsg=NULL
 UPDATE A
 SET A.AssetClass=B.AssetClassAlt_Key
 ,A.ReasonRemark=C.MocReasonName
 FROM #NCIF_NPAUpload A
 LEFT JOIN DimAssetClass B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
								AND A.AssetClassName=B.AssetClassShortName
 LEFT JOIN DimMocReason  C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
								AND C.MocReasonAlt_Key=A.Reason

select * from #NCIF_NPAUpload


BEGIN TRY

	BEGIN TRANSACTION

 IF @OperationFlag=1 AND @AuthMode='Y'
	BEGIN
		 SET @CreatedBy=@CrModApBy
		 SET @DateCreated=GETDATE()
		 SET @AuthorisationStatus='NP'
		 
		 GOTO NCIF_AssetClassDetail_Insert
		 NCIF_AssetClassDetail_Insert_Add:

	END

ELSE IF @OperationFlag IN (2,3) AND @AuthMode='Y'
	BEGIN

			
				SET @ModifiedBy=@CrModApBy
				SET @DateModified=GETDATE()

				IF @OperationFlag=2
					BEGIN
							SET @AuthorisationStatus='MP'

					END

				ELSE 
					 BEGIN
							SET @AuthorisationStatus='DP'
					 END	

				---FIND CREATED BY MAIN TABLE
				SELECT @CreatedBy=A.CreatedBy ,@DateCreated=A.DateCreated FROM NPA_IntegrationDetails A
				INNER JOIN #NCIF_NPAUpload B  ON A.NCIF_Id=B.ENTCIF
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
			    GROUP BY A.CreatedBy,A.DateCreated			
					
				 ---FIND CREATED BY FROM MOD TABLE IN CASE OF DATA IS NOT AVAILABLE IN MAIN TABLE
			   IF ISNULL(@CreatedBy,'')=''
					BEGIN
							
							SELECT @CreatedBy=A.CreatedBy ,@DateCreated=A.DateCreated FROM MOC_NPA_IntegrationDetails_MOD A
							INNER JOIN #NCIF_NPAUpload  B  ON A.NCIF_Id=B.ENTCIF
							WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND A.AuthorisationStatus IN ('NP','MP','DP','RM')
							GROUP BY A.CreatedBy,A.DateCreated
					END	
					
				--IF DATA IS AVAILABLE IN MAIN TABLE
				
				ELSE
					 BEGIN
								UPDATE A
								SET A.AuthorisationStatus=@AuthorisationStatus
								FROM NPA_IntegrationDetails A
								INNER JOIN #NCIF_NPAUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																   AND A.NCIF_Id=B.ENTCIF
					 END
					 
			   --UPDTAE FM FLAG
			   UPDATE A
			   SET A.AuthorisationStatus='FM'
			   FROM  MOC_NPA_IntegrationDetails_MOD A
			   INNER JOIN #NCIF_NPAUpload B ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)									
											 AND A.NCIF_Id=B.ENTCIF
			   WHERE A.AuthorisationStatus IN ('MP')									
		
			  GOTO NCIF_AssetClassDetail_Insert
			  NCIF_AssetClassDetail_Insert_Edit:	

		END		

ELSE IF @OperationFlag=3 AND @AuthMode='N'
	BEGIN
			SET @ModifiedBy=@CrModApBy
			SET @DateModified=GETDATE()

			UPDATE A
			SET A.AuthorisationStatus='DP'
				,A.ModifiedBy=@ModifiedBy
				,A.DateModified=@DateModified
			   ,A.EffectiveToTimeKey=@EffectiveFromTimeKey-1
				,A.MOC_Status='Y'
				,A.MOC_Date=@ModifiedBy
			FROM NPA_IntegrationDetails A
			INNER JOIN #NCIF_NPAUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
											   AND A.NCIF_Id=B.ENTCIF
	END

ELSE IF @OperationFlag=17 AND @AuthMode='Y'
	 BEGIN
			SET @ApprovedBy=@CrModApBy
			SET @DateApproved=GETDATE()

			UPDATE A
			SET A.AuthorisationStatus='R'
				,A.ApprovedBy=@ApprovedBy
				,A.DateApproved=@DateApproved
			FROM MOC_NPA_IntegrationDetails_MOD A
			INNER JOIN #NCIF_NPAUpload B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_Id=B.ENTCIF
			WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')

			UPDATE A
			SET A.AuthorisationStatus='A'
			FROM NPA_IntegrationDetails A
			INNER JOIN #NCIF_NPAUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_Id=B.ENTCIF
			WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')										
													

	 END 

ELSE IF @OperationFlag=16 OR @AuthMode='Y'
	BEGIN
			PRINT 'Authorise Mode'
			IF @AuthMode='N'
				BEGIN	
						IF @OperationFlag=1
							BEGIN
									SET @CreatedBy=@CrModApBy
									SET @DateCreated=GETDATE()
							END

						ELSE
							BEGIN
									SET @ModifiedBy=@CrModApBy
									SET @DateModified=GETDATE()

									UPDATE B
									SET B.CreatedBy=A.CreatedBy
									   ,B.DateCreated=A.DateCreated
								    FROM NPA_IntegrationDetails A
									INNER JOIN #NCIF_NPAUpload  B  ON A.NCIF_Id=B.ENTCIF
									WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
								
									SET @ApprovedBy=@CrModApBy
									SET @DateApproved=GETDATE()
							END			

				END

			IF @AuthMode='Y'
				BEGIN
						SET @ApprovedBy=@CrModApBy
						SET @DateApproved=GETDATE()

						IF OBJECT_ID('TEMPDB..#EntityKeyData')IS NOT NULL
						DROP TABLE #EntityKeyData	
						
						SELECT MAX(EntityKey)MaxEntityKey,MIN(EntityKey)MinEntityKey,A.NCIF_Id INTO #EntityKeyData FROM MOC_NPA_IntegrationDetails_MOD A
						INNER JOIN #NCIF_NPAUpload B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
														  AND A.NCIF_Id=B.ENTCIF
					    WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')
						GROUP BY A.NCIF_Id

						ALTER TABLE #EntityKeyData
						ADD DelStatus VARCHAR(2),CurrRecordFromTimeKey INT

						UPDATE A SET A.DelStatus=B.AuthorisationStatus,
						A.CurrRecordFromTimeKey=C.EffectiveFromTimeKey 
						FROM #EntityKeyData A
						LEFT JOIN MOC_NPA_IntegrationDetails_MOD B ON A.MaxEntityKey=B.EntityKey  
						LEFT JOIN MOC_NPA_IntegrationDetails_MOD C ON A.MinEntityKey=C.EntityKey 
						
						UPDATE A
						SET A.EffectiveToTimeKey=B.CurrRecordFromTimeKey-1
						FROM  MOC_NPA_IntegrationDetails_MOD A
						INNER JOIN #EntityKeyData     B      ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																AND A.NCIF_Id=B.NCIF_Id
																AND ISNULL(A.AuthorisationStatus,'A')='A'
						
						/* Delete Authorise records*/
						UPDATE A
                        SET AuthorisationStatus ='A'
                            ,ApprovedBy=@ApprovedBy
                            ,DateApproved=@DateApproved
                            ,EffectiveToTimeKey=@EffectiveFromTimeKey -1
                         FROM MOC_NPA_IntegrationDetails_MOD A
                          INNER JOIN #EntityKeyData B
                                ON B.NCIF_Id=A.NCIF_Id
									AND B.DelStatus='DP'
                        WHERE A.AuthorisationStatus in('NP','MP','DP','RM')	
						
						UPDATE A
                        SET AuthorisationStatus ='A'
                            ,ApprovedBy=@ApprovedBy
                            ,DateApproved=@DateApproved
							,ModifiedBy=@ModifiedBy
							,DateModified=@DateModified
                            ,EffectiveToTimeKey=@EffectiveFromTimeKey -1
                         FROM NPA_IntegrationDetails A
                          INNER JOIN #EntityKeyData B
                                ON B.NCIF_Id=A.NCIF_Id
									AND B.DelStatus='DP'

						/*Authorise other than delete */
						
						UPDATE A
                        SET AuthorisationStatus ='A'
                            ,ApprovedBy=@ApprovedBy
                            ,DateApproved=@DateApproved
                         FROM MOC_NPA_IntegrationDetails_MOD A
                          INNER JOIN #EntityKeyData B
                                ON B.NCIF_Id=A.NCIF_Id
									AND B.DelStatus<>'DP'
                        WHERE A.AuthorisationStatus in('NP','MP','RM')	
						
                      									
				END
				
			UPDATE A
		    SET A.AuthorisationStatus='A'
		   	,A.MOC_AssetClassAlt_Key=B.AssetClass
		   	,A.MOC_NPA_Date=NULLIF(CONVERT(DATE,B.NPA_Date,103),'')
		   	,A.ModifiedBy=@ModifiedBy
		   	,A.DateModified=@ModifiedBy
		   	,A.ApprovedBy=@ApprovedBy
		   	,A.DateApproved=@DateApproved
		   	,A.MOC_Status='Y'
		   	,A.MOC_ReasonAlt_Key=B.ReasonRemark
		   	,A.MOC_Date=B.DateModified
		   	,A.MocAppRemark=RejectionRemark 
		   	,A.MOC_Remark =B.MOC_Remark
		   FROM NPA_IntegrationDetails  A
		   INNER JOIN #NCIF_NPAUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
		   							        AND A.NCIF_ID=B.ENTCIF
		   								
		   WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')			


	END

SET @ErrorHandle=1
NCIF_AssetClassDetail_Insert:
IF @ErrorHandle=0
	BEGIN
			PRINT 'MOD INSERT'
			/* Original Asset class of NCIF level*/
			--IF NOT EXISTS (SELECT 1 FROM MOC_NPA_IntegrationDetails_MOD A 
			--				INNER JOIN #NCIF_NPAUpload B ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
			--												AND A.NCIF_ID=B.ENTCIF
			--				WHERE A.AuthorisationStatus='O'																					
			--			  )
			--				BEGIN
									PRINT '0'
										INSERT INTO MOC_NPA_IntegrationDetails_MOD
										(
											
											 NCIF_Id
											,NCIF_Changed
											,NCIF_AssetClassAlt_Key
											,NCIF_NPA_Date
											--,SrcSysAlt_Key
											,NCIF_EntityID
											,CustomerName
											,PAN
											,AuthorisationStatus
											,EffectiveFromTimeKey
											,EffectiveToTimeKey
											,CreatedBy
											,DateCreated
											,UploadFlag

										)

										SELECT 

										 A.NCIF_Id
										,A.NCIF_Changed
										,A.NCIF_AssetClassAlt_Key
										,A.NCIF_NPA_Date
										--,A.SrcSysAlt_Key
										,A.NCIF_EntityID
										,MAX(A.CustomerName)CustomerName
										,MAX(A.PAN)PAN
										,'O'---AuthorisationStatus
										,A.EffectiveFromTimeKey
										,A.EffectiveToTimeKey
										,A.CreatedBy
										,A.DateCreated
										,'U'

										FROM NPA_IntegrationDetails A

										INNER JOIN #NCIF_NPAUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																		   AND A.NCIF_ID=B.ENTCIF

										LEFT JOIN MOC_NPA_IntegrationDetails_MOD C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
																					   AND C.NCIF_Id=B.ENTCIF
										WHERE ISNULL(C.AuthorisationStatus,'')<>'O'																					
										GROUP BY 									
													 A.NCIF_Id
													,A.NCIF_Changed
													,A.NCIF_AssetClassAlt_Key
													,A.NCIF_NPA_Date
													,A.NCIF_EntityID
													,A.EffectiveFromTimeKey
													,A.EffectiveToTimeKey
													,A.CreatedBy
													,A.DateCreated
									
							--END
						

								INSERT INTO MOC_NPA_IntegrationDetails_MOD	
								(
									 NCIF_Id
									,MOC_AssetClassAlt_Key
									,MOC_NPA_Date
									,NCIF_EntityID
									,CustomerName
									,PAN
									,AuthorisationStatus
									,EffectiveFromTimeKey
									,EffectiveToTimeKey
									,CreatedBy
									,DateCreated
									,ModifiedBy
									,DateModified
									,MOC_Status
									,MOC_Date
									,MOC_ReasonAlt_Key
									,MOC_Remark
									,UploadFlag
								)

								SELECT 
								 B.NCIF_Id
								,A.AssetClass AS MOC_AssetClassAlt_Key
								,NULLIF(CONVERT(DATE,A.NPA_Date,103),'') AS MOC_NPA_Date
								,B.NCIF_EntityID
								,B.CustomerName
								,B.PAN
								,@AuthorisationStatus
								,@EffectiveFromTimeKey
								,@EffectiveToTimeKey
								,@CreatedBy
								,@DateCreated
								,@ModifiedBy
								,@DateModified
								,'Y' --MOC_Status
								,@DateModified  --MOCDATE
								,Reason
								,A.MOC_Remark
								,'U'

								FROM #NCIF_NPAUpload A
							 
							   INNER JOIN (SELECT NCIF_EntityID,NCIF_Id,MAX(CustomerName)CustomerName,MAX(PAN)PAN FROM NPA_IntegrationDetails
										    WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
										     GROUP BY NCIF_EntityID,NCIF_Id	
											)B  ON 	B.NCIF_Id=A.ENTCIF									
						
			 IF @OperationFlag=1 AND @AUTHMODE='Y'
				BEGIN
						GOTO NCIF_AssetClassDetail_Insert_Add
				END	
				
			 ELSE IF (@OperationFlag=2 OR @OperationFlag=3) AND @AUTHMODE='Y'	
				  BEGIN
						GOTO NCIF_AssetClassDetail_Insert_Edit	
				  END	
			  				
	END

COMMIT TRANSACTION
		IF @OperationFlag<>3
			BEGIN
						SET @D2Ktimestamp=(SELECT TOP 1 @D2Ktimestamp FROM MOC_NPA_IntegrationDetails_MOD A
											INNER JOIN #NCIF_NPAUpload B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																				AND A.NCIF_ID=B.ENTCIF
											)

						
						SET @Result=1
						RETURN @Result						
			END
		ELSE
			 BEGIN
					SET @Result=0
					RETURN @Result
		     END	
			
END TRY

 BEGIN CATCH
			/*cath error data*/
			/*************************************/
			SELECT ERROR_MESSAGE()
			ROLLBACK TRAN 
			SET @Result=-1
			RETURN @Result
		END CATCH	
GO