SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[DocumentDetailsInsertUpdate]	
	 @EntityId				 VARCHAR(10),						---Pan								
	 @MenuId                    INT,	
	 @xmlDocument               XML,
	 @IsMainGrid                CHAR(1)=NULL,
	 @Remark                    varchar(max)=null,
	 @CreatedModifyApprovedBy	VARCHAR(20)=NULL,
     @DateCreatedModified		DATETIME=NULL,							 
	 @EffectiveFromTimeKey		INT=NULL,
	 @EffectiveToTimeKey		INT=NULL, 	 
     @OperationFlag				INT,   
     @AuthMode					CHAR(2) = NULL ,
	 @TimeKey					INT,
	 @Result					INT=0 OUTPUT ,
	 @EventEntityId				INT=NULL,
     @LenderEntityID			INT=NULL
AS
BEGIN
SET QUERY_GOVERNOR_COST_LIMIT 0;
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET DATEFORMAT DMY  	
	SET NOCOUNT ON;
	DECLARE @AuthorisationStatus CHAR(2)=NULL			
			 ,@CreatedBy VARCHAR(20) =NULL
			 ,@DateCreated SMALLDATETIME=NULL
			 ,@ModifyBy VARCHAR(20) =NULL
			 ,@DateModify SMALLDATETIME=NULL
			 ,@ApprovedBy  VARCHAR(20)=NULL
			 ,@DateApproved  SMALLDATETIME=NULL
			 ,@ExEntityKey AS INT=0
			 ,@ErrorHandle int=0
			 ,@docHandle INT 
			 ,@DocumentAlt_key INT
			 ,@EntityKey INT
			
			
			
			 
BEGIN TRY
BEGIN TRAN

IF OBJECT_ID('TEMPDB..#TempDocumentUploadDetails') IS NOT NULL
DROP TABLE #TempDocumentUploadDetails

	 IF @xmlDocument IS NOT NULL
	 BEGIN
		             SELECT  
					 c.value('./DocumentAlt_key[1]','INT')DocumentAlt_key	
					,c.value('./DocumentTypeAlt_Key[1]','INT')DocumentTypeAlt_key
					,c.value('./DocTitle[1]','VARCHAR(100)')DocTitle
					,c.value('./DocumentDesc[1]','VARCHAR(1000)')DocumentDesc
					,c.value('./DocExtn[1]','VARCHAR(30)')DocExtn
					,c.value('./DocLocation[1]','VARCHAR(200)')DocLocation	
					--,c.value('./InUpDeNo[1]','CHAR(1)')InUpDeNo
					--,c.value('./DBCheck[1]','CHAR(1)')DBCheck			
					,c.value('./AuthorisationStatus[1]','VARCHAR(2)')AuthorisationStatus
					,c.value('./DocumentTypeDt[1]','VARCHAR(10)')DocumentTypeDt
					,c.value('./LenderEntityId[1]',	'INT')LenderEntityId
					,c.value('./CreatedBy[1]','VARCHAR(50)')CreatedBy
					,c.value('./ModifyBy[1]','VARCHAR(50)')ModifyBy
					,c.value('./ClientID[1]','VARCHAR(20)') CustomerId
					,c.value('./ENTCIF[1]','VARCHAR(20)') NCIF_Id
					,c.value('./NCIF_EntityID[1]','VARCHAR(20)') NCIF_EntityID
					,c.value('./SrcSysAlt_Key[1]','VARCHAR(2)') SrcSysAlt_Key
					,c.value('./MenuId[1]','VARCHAR(2)') MenuId
					,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) RowID
			        INTO #TempDocumentUploadDetails
			        FROM @xmlDocument.nodes('/DataSet/GridData') AS t(c)
		
			      ALTER TABLE #TempDocumentUploadDetails
				  ADD DateCreated	SMALLDATETIME,
				      --CreatedBy	VARCHAR(20),
				      DateModify	SMALLDATETIME,
				      --ModifyBy VARCHAR(20),
				      EntityId VARCHAR(10)
	                 -- MenuId INT


				SELECT * FROM #TempDocumentUploadDetails

				 set @EventEntityId= (select top 1 NCIF_Id from #TempDocumentUploadDetails)
				 set @MenuId= (select top 1 MenuId from #TempDocumentUploadDetails)
				 Update #TempDocumentUploadDetails
								Set CreatedBy=@CreatedModifyApprovedBy,
								DateCreated=Getdate()

	 END
	 ELSE
	 BEGIN
	    RETURN 0
	 END
	 

	SELECT @DocumentAlt_key= ISNULL(Max(DocumentAlt_key),0) FROM (Select ISNULL(Max(DocumentAlt_key),0) DocumentAlt_key from DocumentUploadDetails  		 
																	UNION
																	Select ISNULL(Max(DocumentAlt_key),0) DocumentAlt_key from DocumentUploadDetails_Mod   
															      ) K
	SELECT @EntityKey= ISNULL(Max(EntityKey),0) FROM (Select ISNULL(Max(EntityKey),0) EntityKey from DocumentUploadDetails  		 
																	UNION
																	Select ISNULL(Max(EntityKey),0) EntityKey from DocumentUploadDetails_Mod   
													      ) K
														  -- SET @DateCreated = GETDATE()
     
  --RETURN	
   print 'sb'			
  print @EntityKey
	  IF @OperationFlag=1 AND @AuthMode='Y'
	  BEGIN
	             
				 SET @CreatedBy =@CreatedModifyApprovedBy 
				 SET @DateCreated = GETDATE()
				 SET @AuthorisationStatus='NP'				
				
				
			     GOTO AdvPreArbitration_Insert
				 AdvPreArbitration_Insert_ADD:
	  END
	  ELSE IF (@OperationFlag=2 OR @OperationFlag=3) AND @AuthMode ='Y'
	  BEGIN
				
			Print 'edit'
			 SET @ModifyBy   = @CreatedModifyApprovedBy 
			 SET @DateModify = GETDATE() 
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

				  -- UPDATE #TempDocumentUploadDetails
						--SET CreatedBy=@CreatedModifyApprovedBy,
						--    DateCreated=Getdate()							
				  -- Where #TempDocumentUploadDetails.InUpDeNo='I'	
				   --ISNULL(DocumentAlt_key,0)=0
						IF EXISTS(Select 1 from #TempDocumentUploadDetails 
								 INNER JOIN DocumentUploadDetails ON (DocumentUploadDetails.EffectiveFromTimeKey<=@TimeKey AND DocumentUploadDetails.EffectiveToTimeKey>=@TimeKey)
									  AND #TempDocumentUploadDetails.DocumentAlt_key=DocumentUploadDetails.DocumentAlt_key
									  AND ISNULL(#TempDocumentUploadDetails.DocumentAlt_key,0)<> 0		
								      AND DocumentUploadDetails.NCIF_Id = @EventEntityId 
																 									 
									  --AND DocumentUploadDetails.EntityId =@EntityId
									  --AND DocumentUploadDetails.AssetDocumentUploadEventAlt_key=@AssetDocumentUploadEventAlt_key
								 )
						BEGIN
						      Update DocumentUploadDetails
							          SET DocumentUploadDetails.AuthorisationStatus =CASE WHEN @OperationFlag=3 THEN @AuthorisationStatus ELSE #TempDocumentUploadDetails.AuthorisationStatus END
							   from #TempDocumentUploadDetails
							   INNER JOIN DocumentUploadDetails ON (DocumentUploadDetails.EffectiveFromTimeKey<=@TimeKey AND DocumentUploadDetails.EffectiveToTimeKey>=@TimeKey)
								     
									  AND #TempDocumentUploadDetails.DocumentAlt_key=DocumentUploadDetails.DocumentAlt_key
									  AND ISNULL(#TempDocumentUploadDetails.DocumentAlt_key,0)<> 0		
									 
								     AND DocumentUploadDetails.NCIF_Id = @EventEntityId 								  									 

							   Update #TempDocumentUploadDetails
							          Set #TempDocumentUploadDetails.CreatedBy =DocumentUploadDetails.CreatedBy
									      ,#TempDocumentUploadDetails.DateCreated=DocumentUploadDetails.DateCreated
										  ,#TempDocumentUploadDetails.ModifyBy=@CreatedModifyApprovedBy
										  ,#TempDocumentUploadDetails.DateModify=GetDate()
							   from #TempDocumentUploadDetails
							   INNER JOIN DocumentUploadDetails ON (DocumentUploadDetails.EffectiveFromTimeKey<=@TimeKey AND DocumentUploadDetails.EffectiveToTimeKey>=@TimeKey)
									  AND #TempDocumentUploadDetails.DocumentAlt_key=DocumentUploadDetails.DocumentAlt_key
									  AND ISNULL(#TempDocumentUploadDetails.DocumentAlt_key,0)<> 0									  
								     -- AND DocumentUploadDetails.EntityId = @EntityId 
									   AND DocumentUploadDetails.NCIF_Id=@EventEntityId
									--AND DocumentUploadDetails.DocumentAlt_key=B.DocumentAlt_key								  
									  --AND DocumentUploadDetails.EntityId  =@EntityId
									  --AND DocumentUploadDetails.AssetDocumentUploadEventAlt_key=@AssetDocumentUploadEventAlt_key
						END
					    ELSE
						BEGIN
								 Update #TempDocumentUploadDetails
							          Set #TempDocumentUploadDetails.CreatedBy =DocumentUploadDetails_Mod.CreatedBy
									      ,#TempDocumentUploadDetails.DateCreated=DocumentUploadDetails_Mod.DateCreated
										  ,#TempDocumentUploadDetails.ModifyBy=@CreatedModifyApprovedBy
										  ,#TempDocumentUploadDetails.DateModify=GetDate()
							   from #TempDocumentUploadDetails
							   INNER JOIN DocumentUploadDetails_Mod ON (DocumentUploadDetails_Mod.EffectiveFromTimeKey<=@TimeKey AND DocumentUploadDetails_Mod.EffectiveToTimeKey>=@TimeKey)
								     
									  AND #TempDocumentUploadDetails.DocumentAlt_key=DocumentUploadDetails_Mod.DocumentAlt_key
									  AND ISNULL(#TempDocumentUploadDetails.DocumentAlt_key,0)<> 0
									  	
								     AND DocumentUploadDetails_Mod.NCIF_Id = @EventEntityId 							 
									  --AND DocumentUploadDetails_Mod.EntityId  =@EntityId
									  --AND DocumentUploadDetails_Mod.AssetDocumentUploadEventAlt_key=@AssetDocumentUploadEventAlt_key
						END
						--IF @OperationFlag =2
						--BEGIN
					 --     UPDATE DocumentUploadDetails_Mod								
						--			SET AuthorisationStatus='FM'
						--			, ModifiedBy=@ModifyBy
						--			,DateModified=@DateModify

						--	FROM #TempDocumentUploadDetails
						--	INNER JOIN DocumentUploadDetails_Mod ON (DocumentUploadDetails_Mod.EffectiveFromTimeKey<=@TimeKey AND DocumentUploadDetails_Mod.EffectiveToTimeKey>=@TimeKey)
						--	 AND #TempDocumentUploadDetails.DocumentAlt_key=DocumentUploadDetails_Mod.DocumentAlt_key
						--			  --AND ISNULL(#TempDocumentUploadDetails.DocumentAlt_key,0)<> 0

						--		WHERE  DocumentUploadDetails_Mod.AuthorisationStatus IN('NP','MP','RM')									  
						--					 AND DocumentUploadDetails_Mod.EntityId = @EntityId 
								
						--END

					 GOTO AdvPreArbitration_Insert
					 PreArbitration_Insert_ADD_Edit_Delete:

			 END

	  END
	  ELSE IF @OperationFlag =3 AND @AuthMode ='N'
	  BEGIN
	
	    SET @ModifyBy   = @CreatedModifyApprovedBy 
						SET @DateModify = GETDATE() 

				UPDATE A SET
						 A.ModifiedBy =@ModifyBy 
						,A.DateModified =@DateModify 
						,A.EffectiveToTimeKey =@EffectiveFromTimeKey-1
					FROM DocumentUploadDetails A	
					INNER JOIN #TempDocumentUploadDetails B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)	
													 --AND A.EntityId = @EntityId 				
													  AND A.NCIF_Id=@EventEntityId
													  AND A.DocumentAlt_key=B.DocumentAlt_key
													 --AND ISNULL(A.LenderEntityId,0)=ISNULL(B.LenderEntityId,0)
													 AND ISNULL(A.AuthorisationStatus,'A')='A' AND B.AuthorisationStatus='DP'
		END
	  ELSE IF @OperationFlag=17 AND @AuthMode ='Y' 
      BEGIN
			UPDATE A
					SET A.AuthorisationStatus='R'
						,A.ApprovedBy	 =@ApprovedBy
						,A.DateApproved=@DateApproved
						,A.EffectiveToTimeKey =@EffectiveFromTimeKey-1
			FROM DocumentUploadDetails_Mod A	
			INNER JOIN #TempDocumentUploadDetails B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)	
													 AND A.EntityId = @EntityId 				
													 AND A.NCIF_Id=@EventEntityId
												--	 AND ISNULL(A.LenderEntityId,0)=ISNULL(B.LenderEntityId,0)
													 AND A.AuthorisationStatus in('NP','MP','DP')	
					  

				IF EXISTS(SELECT 1 FROM DocumentUploadDetails A  INNER JOIN #TempDocumentUploadDetails B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)	
													 AND A.EntityId = @EntityId 				
													 AND A.NCIF_Id=@EventEntityId
													-- AND ISNULL(A.LenderEntityId,0)=ISNULL(B.LenderEntityId,0)
						 )
				BEGIN

				    UPDATE A 
					SET  A.AuthorisationStatus='A'
					FROM DocumentUploadDetails A	
					INNER JOIN #TempDocumentUploadDetails B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)	
													 AND A.EntityId = @EntityId 				
													 AND A.EventEntityId=@EventEntityId
													-- AND ISNULL(A.LenderEntityId,0)=ISNULL(B.LenderEntityId,0)
													-- AND ISNULL(A.AuthorisationStatus,'A')='A' 
				END


				



	END
	  ELSE IF @OperationFlag=16 OR @AuthMode='N'
	  BEGIN
				SELECT * FROM #TempDocumentUploadDetails	
			     Print 'arbi1'
				 PRINT 1
			     IF @AuthMode='N'
				 BEGIN
								Update #TempDocumentUploadDetails
								Set CreatedBy=@CreatedModifyApprovedBy,
								DateCreated=Getdate()
				
							 IF @OperationFlag=1
							  BEGIN
							  PRINT 2
							     SET @CreatedBy =@CreatedModifyApprovedBy
								  SET @DateCreated =GETDATE()
							  END
							 ELSE
								 BEGIN
										
										Print 'edit mode'
										SET @ModifyBy  =@CreatedModifyApprovedBy
										SET @DateModify =GETDATE()

									  SELECT	
											@CreatedBy=B.CreatedBy
											,@DateCreated=B.DateCreated
									  FROM DocumentUploadDetails B
											INNER JOIN DocumentUploadDetails A ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.DocumentAlt_key=B.DocumentAlt_key
												AND A.EntityId = @EntityId
												AND A.NCIF_Id=@EventEntityId
												--AND A.LenderEntityId=ISNULL(B.LenderEntityId,0)	
									

										SET @ApprovedBy = @CreatedModifyApprovedBy			
										SET @DateApproved=GETDATE()

										PRINT 4
										

									 Update B
							          SET B.CreatedBy =A.CreatedBy
									      ,B.DateCreated=A.DateCreated
										  ,B.ModifyBy=@ModifyBy
										  ,B.DateModify=@DateModify 
							           FROM #TempDocumentUploadDetails B
							           INNER JOIN DocumentUploadDetails A ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												--AND A.DocumentTypeAlt_Key=B.DocumentTypeAlt_Key
												--AND A.EntityId = @EntityId
												 AND A.NCIF_Id=@EventEntityId
												--AND A.LenderEntityId=ISNULL(B.LenderEntityId,0)
									  																		
									
							 END

		       END
				 IF @AuthMode='Y'
				 BEGIN
						 Print 'Y mode authorise'
						 DECLARE @DelStatus CHAR(2)
			 
						IF ISNULL(@DelStatus,'')='' 
						BEGIN
								SET @DelStatus='A'
						END

						SET @ApprovedBy = @CreatedModifyApprovedBy			
						SET @DateApproved=GETDATE()
				
						 IF @DelStatus='DP' 
						 BEGIN
									UPDATE A
									SET AuthorisationStatus ='A'
									,A.ApprovedBy=@ApprovedBy
									,A.DateApproved=@DateApproved
									,A.EffectiveToTimeKey =@EffectiveFromTimeKey -1
									FROM DocumentUploadDetails_Mod A
									INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
																		   AND A.DocumentAlt_key=B.DocumentAlt_key
																			 AND A.NCIF_Id=@EventEntityId
																			--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
									WHERE A.AuthorisationStatus in('NP','MP','DP','RM')
								

									IF EXISTS(SELECT 1 FROM DocumentUploadDetails A INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
																	 AND A.DocumentAlt_key=B.DocumentAlt_key
																	AND A.NCIF_Id=@EventEntityId
																--	AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)		
											 )

										BEGIN
												UPDATE A
													SET A.AuthorisationStatus ='A'
														,A.ModifiedBy=@ModifyBy
														,A.DateModified=@DateModify
														,A.ApprovedBy=@ApprovedBy
														,A.DateApproved=@DateApproved
														,A.EffectiveToTimeKey =@EffectiveFromTimeKey-1
												FROM DocumentUploadDetails A
													INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
																				 AND A.DocumentAlt_key=B.DocumentAlt_key
																				AND A.NCIF_Id=@EventEntityId
																				--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
											
										END
					 END

						 ELSE
							BEGIN
										 Print 'other than edit'
										 UPDATE A
										 SET  A.ApprovedBy=@ApprovedBy
														,A.DateApproved=@DateApproved
														,A.EffectiveToTimeKey=Case When A.AuthorisationStatus='DP' THEN @EffectiveFromTimeKey-1 ELSE EffectiveToTimeKey END 
										FROM DocumentUploadDetails_Mod A
									    INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
																	 AND A.DocumentAlt_key=B.DocumentAlt_key
																	AND A.NCIF_Id=@EventEntityId
																	--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
																	AND A.AuthorisationStatus in('NP','MP','DP') 
													 	 
														
								IF @OperationFlag<>16
								BEGIN	

									 UPDATE #TempDocumentUploadDetails
							          SET #TempDocumentUploadDetails.CreatedBy =DocumentUploadDetails_Mod.CreatedBy
									      ,#TempDocumentUploadDetails.DateCreated=DocumentUploadDetails_Mod.DateCreated
										  ,#TempDocumentUploadDetails.ModifyBy=DocumentUploadDetails_Mod.ModifiedBy
										  ,#TempDocumentUploadDetails.DateModify=DocumentUploadDetails_Mod.DateModified
									FROM #TempDocumentUploadDetails
									INNER JOIN DocumentUploadDetails_Mod ON (DocumentUploadDetails_Mod.EffectiveFromTimeKey<=@TimeKey 
											AND DocumentUploadDetails_Mod.EffectiveToTimeKey>=@TimeKey)
										 ---AND #TempDocumentUploadDetails.DocumentTypeAlt_Key=DocumentUploadDetails_Mod.DocumentTypeAlt_Key
											AND DocumentUploadDetails_Mod.DocumentAlt_key=#TempDocumentUploadDetails.DocumentAlt_key
											AND ISNULL(#TempDocumentUploadDetails.DocumentAlt_key,0)<> 0	
											--AND DocumentUploadDetails_Mod.EntityId = @EntityId 
											AND DocumentUploadDetails_Mod.NCIF_Id=@EventEntityId	
											--AND ISNULL(DocumentUploadDetails_Mod.LenderEntityId,0)=ISNULL(#TempDocumentUploadDetails.LenderEntityId,0)								 
							   END		

					 		
						
									  Print 'other than edit complete'
				 END
			 END
				
				 IF @DelStatus <>'DP' OR @AuthMode ='N'
				 BEGIN
														
							DECLARE @IsAvailable CHAR(1)='N'
									,@IsSCD2 CHAR(1)='N'				  

							IF EXISTS(SELECT 1 FROM DocumentUploadDetails A  INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
																	AND A.DocumentAlt_key=B.DocumentAlt_key
																	AND A.NCIF_Id=@EventEntityId
																	--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
												 ---AND ISNULL(LenderEntityId,0)=ISNULL(@LenderEntityID,0)		
										)
								  BEGIN
								
									SET @IsAvailable='Y'
									SET @AuthorisationStatus='A'
					       

									IF EXISTS(SELECT 1 FROM DocumentUploadDetails  A
											INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
																	 AND A.DocumentAlt_key=B.DocumentAlt_key
																	AND A.NCIF_Id=@EventEntityId
																	--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
											WHERE A.EffectiveFromTimeKey=@EffectiveFromTimeKey							
										  )
												BEGIN							
							
													IF 	@OperationFlag<>16
													  BEGIN
															PRINT'DELETED'
															
															 Update DocumentUploadDetails 
														     SET ModifiedBy = #TempDocumentUploadDetails.ModifyBy
															,DateModified =#TempDocumentUploadDetails.DateModify 
															,EffectiveToTimeKey =@EffectiveFromTimeKey-1
														     FROM #TempDocumentUploadDetails
														     INNER JOIN DocumentUploadDetails ON (DocumentUploadDetails.EffectiveFromTimeKey<=@TimeKey AND DocumentUploadDetails.EffectiveToTimeKey>=@TimeKey) 
																										AND	 DocumentUploadDetails.EffectiveFromTimeKey<=@EffectiveFromTimeKey	
																										AND DocumentUploadDetails.DocumentAlt_key=#TempDocumentUploadDetails.DocumentAlt_key								
																										AND DocumentUploadDetails.DocumentTypeAlt_Key=#TempDocumentUploadDetails.DocumentTypeAlt_key
																										AND DocumentUploadDetails.NCIF_Id=@EventEntityId	
																										--AND ISNULL(DocumentUploadDetails.LenderEntityId,0)=ISNULL(#TempDocumentUploadDetails.LenderEntityID,0)
																										
														     Update DocumentUploadDetails 
														     SET ModifiedBy = #TempDocumentUploadDetails.ModifyBy
															,DateModified =#TempDocumentUploadDetails.DateModify 
															,EffectiveToTimeKey =@EffectiveFromTimeKey-1
														     FROM #TempDocumentUploadDetails
														     INNER JOIN DocumentUploadDetails ON (DocumentUploadDetails.EffectiveFromTimeKey<=@TimeKey AND DocumentUploadDetails.EffectiveToTimeKey>=@TimeKey) 
																										AND	 DocumentUploadDetails.EffectiveFromTimeKey<=@EffectiveFromTimeKey	
																										AND DocumentUploadDetails.DocumentAlt_key=#TempDocumentUploadDetails.DocumentAlt_key									
																										AND DocumentUploadDetails.DocumentTypeAlt_Key=#TempDocumentUploadDetails.DocumentTypeAlt_key
																								     	AND DocumentUploadDetails.DocTitle=#TempDocumentUploadDetails.DocTitle	
																									    AND DocumentUploadDetails.NCIF_Id=@EventEntityId
																										WHERE 	#TempDocumentUploadDetails.DocumentTypeAlt_key=1 AND #TempDocumentUploadDetails.AuthorisationStatus='DP'

															
																										 
                        
															INSERT INTO DocumentUploadDetails(								
																EntityKey,
																DocumentAlt_key, 	
																EntityId,
																MenuId,
																DocumentTypeAlt_key,      
																DocTitle   ,
																Remark,
																DocDate,
																DocExtn,
																DocLocation
																,EffectiveFromTimeKey
																,EffectiveToTimeKey
																,AuthorisationStatus								
																,DateCreated
																,CreatedBy
																,DateModified
																,ModifiedBy	 							
																,ApprovedBy
	 															,DateApproved
																 --EventEntityId
																,DocumentTypeDt
																--,LenderEntityID
																,NCIF_Id
																,CustomerId
																,NCIF_EntityID
																,SrcSysAlt_Key
															)

															SELECT  
															@entityKey+ROW_NUMBER() over(Order by rowid),
															@DocumentAlt_key+ROW_NUMBER() over (order by (SELECT 1)),
															--Case When ISNULL(#TempDocumentUploadDetails.DocumentAlt_key,0)=0 
															--THEN(ROW_NUMBER() over (order by #TempDocumentUploadDetails.DocumentAlt_key))+ @DocumentAlt_key 
															--ELSE #TempDocumentUploadDetails.DocumentAlt_key END as ID ,
						      								@EntityId,	
															@MenuId,
															#TempDocumentUploadDetails.DocumentTypeAlt_key,      
															#TempDocumentUploadDetails.DocTitle,   
															#TempDocumentUploadDetails.DocumentDesc,
															CONVERT(date, getdate()),
															#TempDocumentUploadDetails.DocExtn,
															#TempDocumentUploadDetails.DocLocation
															,@EffectiveFromTimeKey
															,@EffectiveToTimeKey 
															,CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END				
															,#TempDocumentUploadDetails.DateCreated	
															,#TempDocumentUploadDetails.CreatedBy		
															,#TempDocumentUploadDetails.DateModify		
															,#TempDocumentUploadDetails.ModifyBy
															,CASE WHEN @AuthMode ='Y' THEN @ApprovedBy ELSE NULL END
															,CASE WHEN @AuthMode ='Y' THEN @DateApproved ELSE NULL END 	
															--,@EventEntityId	
															,CASE WHEN DocumentTypeDt<>'' THEN CONVERT(DATE,DocumentTypeDt,103) ELSE NULL END DocumentTypeDt
															--,LenderEntityID 
															,#TempDocumentUploadDetails.NCIF_Id
															,#TempDocumentUploadDetails.CustomerId
															,#TempDocumentUploadDetails.NCIF_EntityID
															,#TempDocumentUploadDetails.SrcSysAlt_Key
															FROM #TempDocumentUploadDetails  
															WHERE #TempDocumentUploadDetails.AuthorisationStatus <> 'DP'	
															
																
															 											
										
													END	
													ELSE 
													   BEGIN				
																	INSERT INTO DocumentUploadDetails(
																						EntityKey,
																						DocumentAlt_key, 	
																						EntityId,
																						MenuId,
																						DocumentTypeAlt_key,      
																						DocTitle   ,
																						Remark,
																						DocDate,
																						DocExtn,
																						DocLocation
																						,EffectiveFromTimeKey
																						,EffectiveToTimeKey
																						,AuthorisationStatus								
																						,DateCreated
																						,CreatedBy
																						,DateModified
																						,ModifiedBy	 							
																						,ApprovedBy
	 																					,DateApproved
																						--,EventEntityId
																						,DocumentTypeDt
																						--,LenderEntityID
																						,NCIF_Id
															                            ,CustomerId
																						,NCIF_EntityID
																                        ,SrcSysAlt_Key
																						 
																					)

																			SELECT  
																					@entityKey+ROW_NUMBER() over(Order by adm.EntityKey),
																			        DocumentAlt_key ,
																			      	@EntityId,	
																				    @MenuId, 
																					DocumentTypeAlt_key,      
																					DocTitle,   
																				    Remark,
																					CONVERT(date, getdate()),
																					 DocExtn,
																				     DocLocation
																					,@EffectiveFromTimeKey
																					,@EffectiveToTimeKey 
																					,CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END				
																					,ADM.DateCreated	
																					,ADM.CreatedBy		
																					,ADM.DateModified		
																					,ADM.ModifiedBy
																					,CASE WHEN @AuthMode ='Y' THEN @ApprovedBy ELSE NULL END
																					,CASE WHEN @AuthMode ='Y' THEN @DateApproved ELSE NULL END 	
																					--,@EventEntityId	
																					,CASE WHEN DocumentTypeDt<>'' THEN CONVERT(DATE,DocumentTypeDt,103) ELSE NULL END DocumentTypeDt	
																					--,LenderEntityID	
																					,adm.NCIF_Id
															                        ,adm.CustomerId
																					,ADM.NCIF_EntityID
																                    ,ADM.SrcSysAlt_Key
																				FROM DocumentUploadDetails_Mod ADM
																					INNER JOIN (SELECT MAX(EntityKey) AS EntityKey FROM [DocumentUploadDetails_Mod] SER
																								WHERE (SER.EffectiveFromTimeKey <= @TimeKey AND SER.EffectiveToTimeKey >= @TimeKey)
																									--AND SER.EntityId = @EntityId
																									AND SER.NCIF_Id=@EventEntityId 
																									--AND ISNULL(SER.LenderEntityId,0)=ISNULL(@LenderEntityID,0)							  
																								GROUP BY SER.EntityId ,SER.DocumentAlt_key--,SER.EventEntityId
																								)
																			    AS A ON A.EntityKey=ADM.EntityKey
																				WHERE (ADM.EffectiveFromTimeKey<=@TimeKey 
																					AND ADM.EffectiveToTimeKey>=@TimeKey)
																					AND ADM.AuthorisationStatus NOT IN( 'DP','FM','A')
														
																				UPDATE A
																				SET A.AuthorisationStatus ='A'
																					,A.ApprovedBy=@ApprovedBy
																					,A.DateApproved=@DateApproved
																					,A.EffectiveToTimeKey=Case When A.AuthorisationStatus='DP' THEN @EffectiveFromTimeKey-1 ELSE A.EffectiveToTimeKey END 
																				FROM DocumentUploadDetails_Mod A
																				INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
																							AND a.DocumentAlt_key=b.DocumentAlt_key	
																							 AND A.NCIF_Id=@EventEntityId
																							--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
																				WHERE  A.AuthorisationStatus in('NP','MP','DP','RM')

																			  			
																		 

													END	
							                     END
								  ELSE
								      BEGIN
								           SET @IsSCD2='Y'
								       END
				 

			              END

				IF @IsAvailable='N' OR @IsSCD2='Y'
				 BEGIN		
							
						IF @OperationFlag<>16
						   BEGIN

						   --select * from #TempDocumentUploadDetails
								PRINT 16

						       INSERT INTO 	DocumentUploadDetails(
											 EntityKey,
											DocumentAlt_key, 	
											EntityId,
											MenuId,
											DocumentTypeAlt_key,      
											DocTitle   ,
											Remark,
											DocDate,
											DocExtn,
											DocLocation
											,EffectiveFromTimeKey
											,EffectiveToTimeKey
											,AuthorisationStatus								
											,DateCreated
											,CreatedBy
											,DateModified
											,ModifiedBy	 							
											,ApprovedBy
	 										,DateApproved
											--,EventEntityId
											,DocumentTypeDt
											--,LenderEntityId
											,NCIF_Id
											,CustomerId
											,NCIF_EntityID
											,SrcSysAlt_Key
											 
										)
						
										SELECT  
												@EntityKey+ROW_NUMBER() over(order by rowid),
												@DocumentAlt_key+ROW_NUMBER() over (order by (SELECT 1)),
										        --Case When ISNULL(#TempDocumentUploadDetails.DocumentAlt_key,0)=0 THEN(ROW_NUMBER() over (order by #TempDocumentUploadDetails.DocumentAlt_key))+ @DocumentAlt_key ELSE #TempDocumentUploadDetails.DocumentAlt_key END as ID ,
												@EntityId,
												@MenuId,		
												#TempDocumentUploadDetails.DocumentTypeAlt_key,      
												#TempDocumentUploadDetails.DocTitle,   
												#TempDocumentUploadDetails.DocumentDesc,
												CONVERT(date, getdate()),
												#TempDocumentUploadDetails.DocExtn,
												#TempDocumentUploadDetails.DocLocation
												,@EffectiveFromTimeKey
												,@EffectiveToTimeKey 
												,CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END				
												,#TempDocumentUploadDetails.DateCreated	
												,#TempDocumentUploadDetails.CreatedBy		
												,#TempDocumentUploadDetails.DateModify		
												,#TempDocumentUploadDetails.ModifyBy
												,CASE WHEN @AuthMode ='Y' THEN @ApprovedBy ELSE NULL END
												,CASE WHEN @AuthMode ='Y' THEN @DateApproved ELSE NULL END 	
												--,@EventEntityId	
												,CASE WHEN DocumentTypeDt<>'' THEN CONVERT(DATE,DocumentTypeDt,103) ELSE NULL END DocumentTypeDt
												--,ISNULL(LenderEntityID,0)
												,#TempDocumentUploadDetails.NCIF_Id
											    ,#TempDocumentUploadDetails.CustomerId
												,#TempDocumentUploadDetails.NCIF_EntityID
												,#TempDocumentUploadDetails.SrcSysAlt_Key
											FROM #TempDocumentUploadDetails WHERE #TempDocumentUploadDetails.AuthorisationStatus <> 'DP'
			            END
						 ELSE
								BEGIN
										print 'asas'

											INSERT INTO DocumentUploadDetails(
														EntityKey,								
														DocumentAlt_key, 	
														EntityId,
														MenuId,
														DocumentTypeAlt_key,      
														DocTitle   ,
														Remark,
														DocDate,
														DocExtn,
														DocLocation
													   ,EffectiveFromTimeKey
													   ,EffectiveToTimeKey
													   ,AuthorisationStatus								
													   ,DateCreated
													   ,CreatedBy
													   ,DateModified
													   ,ModifiedBy	 							
													   ,ApprovedBy
	 												   ,DateApproved
													  -- ,EventEntityId
													   ,DocumentTypeDt
													 --  ,LenderEntityId
													 ,NCIF_Id
											         ,CustomerId
													 ,NCIF_EntityID
												     ,SrcSysAlt_Key 
													)
											
											SELECT  @EntityKey+ROW_NUMBER() over(order by adm.EntityKey),
											        DocumentAlt_key ,
											      	@EntityId,	
												    @MenuId, 
													DocumentTypeAlt_key,      
													DocTitle,   
												    Remark,
													CONVERT(date, getdate()),
													 DocExtn,
												     DocLocation
													,@EffectiveFromTimeKey
													,@EffectiveToTimeKey 
													,CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END				
													,ADM.DateCreated	
													,ADM.CreatedBy		
													,ADM.DateModified		
													,ADM.ModifiedBy
													,CASE WHEN @AuthMode ='Y' THEN @ApprovedBy ELSE NULL END
													,CASE WHEN @AuthMode ='Y' THEN @DateApproved ELSE NULL END 	
												--	,@EventEntityId		
													,CASE WHEN DocumentTypeDt<>'' THEN CONVERT(DATE,DocumentTypeDt,103) ELSE NULL END DocumentTypeDt
													--,LenderEntityID	
													,adm.NCIF_Id
											        ,adm.CustomerId
													,adm.NCIF_EntityID
												    ,adm.SrcSysAlt_Key
												FROM DocumentUploadDetails_Mod ADM
													INNER JOIN (SELECT MAX(EntityKey) AS EntityKey FROM [DocumentUploadDetails_Mod] SER
																 WHERE (SER.EffectiveFromTimeKey <= @TimeKey AND SER.EffectiveToTimeKey >= @TimeKey)
																		--AND SER.EntityId = @EntityId
																		AND SER.NCIF_Id=@EventEntityId 
																		 --AND ISNULL(SER.LenderEntityId,0)=ISNULL(@LenderEntityID,0)	
																		GROUP BY SER.EntityId ,SER.DocumentAlt_key--,SER.EventEntityId
														    	)
											  AS A ON A.EntityKey=ADM.EntityKey
												WHERE (ADM.EffectiveFromTimeKey<=@TimeKey 
													AND ADM.EffectiveToTimeKey>=@TimeKey)
													AND ADM.AuthorisationStatus NOT IN( 'DP','FM')

											UPDATE A								 
											SET A.AuthorisationStatus ='A'
												,A.ApprovedBy=@ApprovedBy
												,A.DateApproved=@DateApproved
												,A.EffectiveToTimeKey=Case WHEN A.AuthorisationStatus='DP' THEN @EffectiveFromTimeKey-1 ELSE EffectiveToTimeKey END 																					
												FROM DocumentUploadDetails_Mod A
											  INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
											  			--AND A.EntityId = @EntityId 
														AND a.DocumentAlt_key=b.DocumentAlt_key	
											  			 AND A.NCIF_Id=@EventEntityId
											  			--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
											  WHERE  A.AuthorisationStatus in('NP','MP','DP','RM')
												


		     	           END
						
		END					
									
	END

			 IF @IsSCD2='Y' 
						BEGIN
						    Print 'error'
							UPDATE A SET
										EffectiveToTimeKey=@EffectiveFromTimeKey-1
										,AuthorisationStatus =CASE WHEN @AUTHMODE='Y' THEN  'A' ELSE NULL END
									FROM DocumentUploadDetails A
									INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
													AND a.DocumentAlt_key=b.DocumentAlt_key	
												  AND A.NCIF_Id=@EventEntityId
												--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
									
						END	
			

		 END

	--ELSE IF @OperationFlag=17 AND @AuthMode ='Y' 
	--	BEGIN
	--			SET @ApprovedBy	   = @CreatedModifyApprovedBy 
	--			SET @DateApproved  = GETDATE()

	--			UPDATE A
	--				SET AuthorisationStatus='R'
	--				,ApprovedBy	 =@ApprovedBy
	--				,DateApproved=@DateApproved
	--				,EffectiveToTimeKey =@EffectiveFromTimeKey-1
	--			FROM DocumentUploadDetails_Mod A
	--			INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
	--						AND A.EntityId = @EntityId 
	--						AND A.EventEntityId=@EventEntityId
	--						AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
	--			WHERE  A.AuthorisationStatus in('NP','MP','DP','RM')

	--			IF EXISTS(SELECT 1 FROM DocumentUploadDetails 
	--						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@Timekey) 
	--							 AND EntityId = @EntityId 
	--							 AND EventEntityId=@EventEntityId
	--							 AND ISNULL(LenderEntityId,0)=ISNULL(@LenderEntityID,0)	
	--					 )
	--				BEGIN
	--					UPDATE A
	--						SET A.AuthorisationStatus='A'
	--					FROM DocumentUploadDetails A
	--						INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
	--						AND A.EntityId = @EntityId 
	--						AND A.EventEntityId=@EventEntityId
	--						AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
	--								 AND A.AuthorisationStatus IN('MP','DP','RM') 	
	--				END
												
	ELSE IF @OperationFlag=18 AND @AuthMode ='Y'  /* NEW SCINERIO FOR UPDATE REMARK STATUS IN MAIN AND MOD TABLE */
		BEGIN
				UPDATE A
					SET  A.AuthorisationStatus='RM'
				FROM DocumentUploadDetails_Mod A
							INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
								AND a.DocumentAlt_key=b.DocumentAlt_key	
							AND A.NCIF_Id=@EventEntityId
							--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
									AND A.AuthorisationStatus in('NP','MP','DP','RM')	

				UPDATE A
					SET A.AuthorisationStatus='RM'
				FROM DocumentUploadDetails A
							INNER JOIN #TempDocumentUploadDetails  B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)  
								AND a.DocumentAlt_key=b.DocumentAlt_key	 
							AND A.NCIF_Id=@EventEntityId
							--AND ISNULL(A.LenderEntityId,0) =ISNULL(B.LenderEntityId,0)
							AND A.AuthorisationStatus in('NP','MP','DP','RM') 	
		END

	 SET @ErrorHandle=1
	 AdvPreArbitration_Insert:
	 IF @ErrorHandle=0
	 BEGIN
	    
		Print 'com'
	
		INSERT INTO 
		   DocumentUploadDetails_Mod(
								EntityKey,
								DocumentAlt_key, 	
								EntityId,
								MenuId,
								DocumentTypeAlt_key,      
								DocTitle   ,
								Remark,
								DocDate,
								DocExtn,
								DocLocation
								,EffectiveFromTimeKey
								,EffectiveToTimeKey
								,AuthorisationStatus								
								,DateCreated
								,CreatedBy
								,DateModified
								,ModifiedBy	 							
								,ApprovedBy
	 							,DateApproved
								,DocumentTypeDt
								--,LenderEntityId
								,NCIF_Id
							   ,CustomerId
							   ,NCIF_EntityID
							   ,SrcSysAlt_Key
							)

						SELECT  
								@EntityKey+ROW_NUMBER() over(order by rowid),
								@DocumentAlt_key+ROW_NUMBER() over (order by (SELECT 1)),
						        --Case When ISNULL(#TempDocumentUploadDetails.DocumentAlt_key,0)=0 THEN(ROW_NUMBER() over (order by #TempDocumentUploadDetails.DocumentAlt_key))+ @DocumentAlt_key ELSE #TempDocumentUploadDetails.DocumentAlt_key END as ID ,
								@EntityId,		
								@MenuId ,
								#TempDocumentUploadDetails.DocumentTypeAlt_key,      
								#TempDocumentUploadDetails.DocTitle,   
								#TempDocumentUploadDetails.DocumentDesc,
							--	 CAse WHEN ISNULL(#TempDocumentUploadDetails.AssetDocumentDate,'')='' THEN NULL ELSE convert(date,#TempDocumentUploadDetails.AssetDocumentDate,103)  END,
							--	 CAse WHEN ISNULL(#TempDocumentUploadDetails.AssetDocumentUploadDate,'')='' THEN NULL ELSE convert(date,#TempDocumentUploadDetails.AssetDocumentUploadDate,103)  END,
								CONVERT(date, getdate()),
								#TempDocumentUploadDetails.DocExtn,
								#TempDocumentUploadDetails.DocLocation
								,@EffectiveFromTimeKey
								,@EffectiveToTimeKey 
								,Case When ISNULL(#TempDocumentUploadDetails.AuthorisationStatus,'')='Y' THEN 'NP' ELSE 	@AuthorisationStatus END				
								,#TempDocumentUploadDetails.DateCreated	
								,#TempDocumentUploadDetails.CreatedBy		
								,#TempDocumentUploadDetails.DateModify		
								,#TempDocumentUploadDetails.ModifyBy
								,@ApprovedBy 
								,@DateApproved 	
								,CASE WHEN DocumentTypeDt<>'' THEN CONVERT(DATE,DocumentTypeDt,103) ELSE NULL END DocumentTypeDt
								--,ISNULL(LenderEntityID,0)LenderEntityID
								,#TempDocumentUploadDetails.NCIF_Id
							    ,#TempDocumentUploadDetails.CustomerId
								,#TempDocumentUploadDetails.NCIF_EntityID
							    ,#TempDocumentUploadDetails.SrcSysAlt_Key
							FROM #TempDocumentUploadDetails WHERE #TempDocumentUploadDetails.AuthorisationStatus<>'DP'
	
	 END

	 	--***********maintain log table

	IF @OperationFlag IN(1,2,3,16,17,18) AND @AuthMode ='Y'
			BEGIN
					PRINT 5
				IF @OperationFlag=2 
					BEGIN 

						SET @CreatedBy=@CreatedModifyApprovedBy
						SET @ApprovedBy=NULL
					--end

					END


					IF @OperationFlag IN(16,17) 
						BEGIN 
							SET @DateCreated= GETDATE()
						END
										
								--EXEC LogDetailsInsertUpdate_Attendence -- MAINTAIN LOG TABLE
								--	0,
								--	@MenuId,
								--	@EntityId,-- ReferenceID ,
								--	@CreatedModifyApprovedBy,
								--	@ApprovedBy,-- @ApproveBy 
								--	@DateCreatedModified,
								--	@Remark,
								--	@MenuId, -- for FXT060 screen
								--	@OperationFlag,
								--	@AuthMode

						
					
			END	

	 COMMIT TRANSACTION	
	 SET @Result=@EventEntityId
	 RETURN @Result
	END TRY
	 BEGIN CATCH	     
		SELECT ERROR_MESSAGE()
		ROLLBACK TRANSACTION
		SET @Result=-1	
		RETURN @Result
	 END CATCH 	 
	 END
GO