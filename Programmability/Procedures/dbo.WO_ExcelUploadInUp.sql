SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[WO_ExcelUploadInUp]
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

IF OBJECT_ID('TEMPDB..#WO_DataUpload')IS NOT NULL
DROP TABLE #WO_DataUpload 

SELECT
 -- c.value('./NCIF_ID[1]','VARCHAR(30)')NCIF_ID
 c.value('./SourceSystem[1]','tinyint')SrcSysAlt_Key					---- Source System Name
 ,c.value('./NCIF_ID[1]','VARCHAR(30)')NCIF_ID							---- Dedupe ID - UCIC - Enterprise CIF
 ,c.value('./CustomerID[1]','varchar(80)')CustomerID					---- Source System CIF - Customer Identifier 
 ,c.value('./CustomerAcID[1]','varchar(80)')CustomerAcID				---- Account No
 ,c.value('./WriteOffDt[1]','varchar(10)')WriteOffDt				---- Write off Date
 ,c.value('./WO_PWO[1]','varchar(30)')WO_PWO							---- Write Off Type
 ,c.value('./IntSacrifice[1]','DECIMAL(18,2)')IntSacrifice	---- Write off amount - PrincipalInterest
 ,c.value('./WriteOffAmt[1]','DECIMAL(18,2)')WriteOffAmt	---- Write off amount - Interest
 ,c.value('./Action[1]','varchar(5)')Action								---- Action
 ,c.value('./CreatedBy[1]','varchar(20)')CreatedBy
 ,c.value('./DateCreated[1]','smalldatetime')DateCreated
 ,c.value('./ModifiedBy[1]','varchar(20)')ModifiedBy
 ,c.value('./DateModified[1]','smalldatetime')DateModified
 INTO #WO_DataUpload
 FROM @XmlDocument.nodes('DataSet/GridData') AS t(c)

 	SET @ErrorMsg=NULL
 --UPDATE A
 --SET A.AssetClass=B.AssetClassAlt_Key
 --,A.ReasonRemark=C.MocReasonName
 --FROM #WO_DataUpload A
 --LEFT JOIN DimAssetClass B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
	--							AND A.AssetClassName=B.AssetClassShortName
 --LEFT JOIN DimMocReason  C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
	--							AND C.MocReasonAlt_Key=A.Reason

select * from #WO_DataUpload


BEGIN TRY

	BEGIN TRANSACTION

 IF @OperationFlag=1 AND @AuthMode='Y'
	BEGIN
		 SET @CreatedBy=@CrModApBy
		 SET @DateCreated=GETDATE()
		 SET @AuthorisationStatus='NP'
		 
		 GOTO NCIF_WODetail_Insert
		 NCIF_WODetail_Insert_Add:

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
				SELECT @CreatedBy=A.CreatedBy ,@DateCreated=A.DateCreated FROM CURDAT.AdvAcWoDetail A
				INNER JOIN #WO_DataUpload B  ON A.NCIF_Id=B.NCIF_ID
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
			    GROUP BY A.CreatedBy,A.DateCreated			
					
				 ---FIND CREATED BY FROM MOD TABLE IN CASE OF DATA IS NOT AVAILABLE IN MAIN TABLE
			   IF ISNULL(@CreatedBy,'')=''
					BEGIN
							
							SELECT @CreatedBy=A.CreatedBy ,@DateCreated=A.DateCreated FROM AdvAcWoDetail_MOD A
							INNER JOIN #WO_DataUpload  B  ON A.NCIF_Id=B.NCIF_ID
							WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND A.AuthorisationStatus IN ('NP','MP','DP','RM')
							GROUP BY A.CreatedBy,A.DateCreated
					END	
					
				--IF DATA IS AVAILABLE IN MAIN TABLE
				
				ELSE
					 BEGIN
								UPDATE A
								SET A.AuthorisationStatus=@AuthorisationStatus
								FROM CURDAT.AdvAcWoDetail A
								INNER JOIN #WO_DataUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																   AND A.NCIF_Id=B.NCIF_ID
					 END
					 
			   --UPDTAE FM FLAG
			   UPDATE A
			   SET A.AuthorisationStatus='FM'
			   FROM  AdvAcWoDetail_Mod A
			   INNER JOIN #WO_DataUpload B ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)									
											 AND A.NCIF_Id=B.NCIF_ID
			   WHERE A.AuthorisationStatus IN ('MP')									
		
			  GOTO NCIF_WODetail_Insert
			  NCIF_WODetail_Insert_Edit:	

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
				--,A.MOC_Status='Y'
				--,A.WriteOffDt=@ModifiedBy
			FROM CURDAT.AdvAcWoDetail A
			INNER JOIN #WO_DataUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
											   AND A.NCIF_Id=B.NCIF_ID
	END

ELSE IF @OperationFlag=17 AND @AuthMode='Y'
	 BEGIN
			SET @ApprovedBy=@CrModApBy
			SET @DateApproved=GETDATE()

			UPDATE A
			SET A.AuthorisationStatus='R'
				,A.ApprovedBy=@ApprovedBy
				,A.DateApproved=@DateApproved
			FROM AdvAcWoDetail_Mod A
			INNER JOIN #WO_DataUpload B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_Id=B.NCIF_ID
			WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')

			UPDATE A
			SET A.AuthorisationStatus='A'
			FROM CURDAT.AdvAcWoDetail A
			INNER JOIN #WO_DataUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_Id=B.NCIF_ID
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
								    FROM CURDAT.AdvAcWoDetail A
									INNER JOIN #WO_DataUpload  B  ON A.NCIF_Id=B.NCIF_ID
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
						
						SELECT MAX(EntityKey)MaxEntityKey,MIN(EntityKey)MinEntityKey,A.NCIF_Id INTO #EntityKeyData FROM AdvAcWoDetail_Mod A
						INNER JOIN #WO_DataUpload B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
														  AND A.NCIF_Id=B.NCIF_Id
					    WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')
						GROUP BY A.NCIF_Id

						ALTER TABLE #EntityKeyData
						ADD DelStatus VARCHAR(2),CurrRecordFromTimeKey INT

						UPDATE A SET A.DelStatus=B.AuthorisationStatus,
						A.CurrRecordFromTimeKey=C.EffectiveFromTimeKey 
						FROM #EntityKeyData A
						LEFT JOIN AdvAcWoDetail_Mod B ON A.MaxEntityKey=B.EntityKey  
						LEFT JOIN AdvAcWoDetail_Mod C ON A.MinEntityKey=C.EntityKey 
						
						UPDATE A
						SET A.EffectiveToTimeKey=B.CurrRecordFromTimeKey-1
						FROM  AdvAcWoDetail_Mod A
						INNER JOIN #EntityKeyData     B      ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																AND A.NCIF_Id=B.NCIF_Id
																AND ISNULL(A.AuthorisationStatus,'A')='A'
						
						/* Delete Authorise records*/
						UPDATE A
                        SET AuthorisationStatus ='A'
                            ,ApprovedBy=@ApprovedBy
                            ,DateApproved=@DateApproved
                            ,EffectiveToTimeKey=@EffectiveFromTimeKey -1
                         FROM AdvAcWoDetail_Mod A
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
                         FROM CURDAT.AdvAcWoDetail A
                          INNER JOIN #EntityKeyData B
                                ON B.NCIF_Id=A.NCIF_Id
									AND B.DelStatus='DP'

						/*Authorise other than delete */
						
						UPDATE A
                        SET AuthorisationStatus ='A'
                            ,ApprovedBy=@ApprovedBy
                            ,DateApproved=@DateApproved
                         FROM AdvAcWoDetail_Mod A
                          INNER JOIN #EntityKeyData B
                                ON B.NCIF_Id=A.NCIF_Id
									AND B.DelStatus<>'DP'
                        WHERE A.AuthorisationStatus in('NP','MP','RM')	
						
                      									
				END
				
			UPDATE A
		    SET A.AuthorisationStatus='A'
			,A.SrcSysAlt_Key=B.SrcSysAlt_Key
			,A.NCIF_Id=B.NCIF_Id
			,A.CustomerID=B.CustomerID
			,A.CustomerAcID=B.CustomerAcID
		    ,A.WriteOffDt=NULLIF(CONVERT(DATE,B.WriteOffDt,103),'')
			,A.WO_PWO=B.WO_PWO
			,A.IntSacrifice=B.IntSacrifice
			,A.WriteOffAmt=B.WriteOffAmt
			,A.Action=B.Action
		   	,A.ModifiedBy=@ModifiedBy
		   	,A.DateModified=@ModifiedBy
		   	,A.ApprovedBy=@ApprovedBy
		   	,A.DateApproved=@DateApproved
		   	
		   FROM CURDAT.AdvAcWoDetail  A
		   INNER JOIN #WO_DataUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
		   							        AND A.NCIF_ID=B.NCIF_ID
		   								
		   WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')			


	END

SET @ErrorHandle=1
NCIF_WODetail_Insert:
IF @ErrorHandle=0
	BEGIN
			PRINT 'MOD INSERT'
			/* Original Asset class of NCIF level*/
			--IF NOT EXISTS (SELECT 1 FROM AdvAcWoDetail_Mod A 
			--				INNER JOIN #WO_DataUpload B ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
			--												AND A.NCIF_ID=B.NCIF_ID
			--				WHERE A.AuthorisationStatus='O'																					
			--			  )
			--				BEGIN
									PRINT '0'
										INSERT INTO AdvAcWoDetail_Mod
										(
											
											-- SrcSysAlt_Key
											--,NCIF_Id
											--,NCIF_Changed
											--,NCIF_AssetClassAlt_Key
											--,NCIF_NPA_Date
											----,SrcSysAlt_Key
											--,NCIF_EntityID
											--,CustomerName
											--,PAN
											--,AuthorisationStatus
											--,EffectiveFromTimeKey
											--,EffectiveToTimeKey
											--,CreatedBy
											--,DateCreated
											--,UploadFlag

											 SrcSysAlt_Key
											,NCIF_Id
											,CustomerID
											,CustomerAcID
											,WriteOffDt
											,WO_PWO
											,IntSacrifice
											,WriteOffAmt
											,Action
											,AuthorisationStatus
											,EffectiveFromTimeKey
											,EffectiveToTimeKey
											,CreatedBy
											,DateCreated

										)

										SELECT 


										 A.SrcSysAlt_Key
										,A.NCIF_Id
										,A.CustomerID
										,A.CustomerAcID
										,A.WriteOffDt
										,A.WO_PWO
										,A.IntSacrifice
										,A.WriteOffAmt
										,A.Action
										,A.AuthorisationStatus
										,A.EffectiveFromTimeKey
										,A.EffectiveToTimeKey
										,A.CreatedBy
										,A.DateCreated

										FROM CURDAT.AdvAcWoDetail A

										INNER JOIN #WO_DataUpload  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																		   AND A.NCIF_ID=B.NCIF_ID

										LEFT JOIN AdvAcWoDetail_Mod C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
																					   AND C.NCIF_Id=B.NCIF_ID
										WHERE ISNULL(C.AuthorisationStatus,'')<>'O'																					
										--GROUP BY 									
										--			 A.NCIF_Id
									
							--END
						

								INSERT INTO AdvAcWoDetail_Mod	
								(
									-- NCIF_Id
									--,MOC_AssetClassAlt_Key
									--,MOC_NPA_Date
									--,NCIF_EntityID
									--,CustomerName
									--,PAN
									--,AuthorisationStatus
									--,EffectiveFromTimeKey
									--,EffectiveToTimeKey
									--,CreatedBy
									--,DateCreated
									--,ModifiedBy
									--,DateModified
									--,MOC_Status
									--,MOC_Date
									--,MOC_ReasonAlt_Key
									--,MOC_Remark
									--,UploadFlag

									 SrcSysAlt_Key
									,NCIF_Id
									,CustomerID
									,CustomerAcID
									,WriteOffDt
									,WO_PWO
									,IntSacrifice
									,WriteOffAmt
									,AuthorisationStatus
									,EffectiveFromTimeKey
									,EffectiveToTimeKey
									,CreatedBy
									,DateCreated
									,ModifiedBy
									,DateModified
									,Action
								)

								SELECT 
								  B.SrcSysAlt_Key
								 ,B.NCIF_Id
								 ,B.CustomerID
								 ,B.CustomerAcID
								 ,NULLIF(CONVERT(DATE,B.WriteOffDt,103),'') AS WriteOffDt
								 ,B.WO_PWO
								 ,B.IntSacrifice
								 ,B.WriteOffAmt
								,@AuthorisationStatus
								,@EffectiveFromTimeKey
								,@EffectiveToTimeKey
								,@CreatedBy
								,@DateCreated
								,@ModifiedBy
								,@DateModified
								,B.Action

								FROM #WO_DataUpload A
							 
							   INNER JOIN (SELECT SrcSysAlt_Key,NCIF_Id,CustomerID,CustomerAcID,
											WriteOffDt,WO_PWO,IntSacrifice,WriteOffAmt,Action FROM CURDAT.AdvAcWoDetail
										    WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
										     --GROUP BY NCIF_Id	
											)B  ON 	B.NCIF_Id=A.NCIF_ID									
						
			 IF @OperationFlag=1 AND @AUTHMODE='Y'
				BEGIN
						GOTO NCIF_WODetail_Insert_Add
				END	
				
			 ELSE IF (@OperationFlag=2 OR @OperationFlag=3) AND @AUTHMODE='Y'	
				  BEGIN
						GOTO NCIF_WODetail_Insert_Edit	
				  END	
			  				
	END

COMMIT TRANSACTION
		IF @OperationFlag<>3
			BEGIN
						SET @D2Ktimestamp=(SELECT TOP 1 @D2Ktimestamp FROM AdvAcWoDetail_Mod A
											INNER JOIN #WO_DataUpload B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																				AND A.NCIF_ID=B.NCIF_ID
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