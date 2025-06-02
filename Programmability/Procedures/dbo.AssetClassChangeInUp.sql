SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[AssetClassChangeInUp]

 @xmlDocument XML
,@OperationFlag INT
,@AuthMode      CHAR(2)
,@EffectiveFromTimeKey	INT
,@EffectiveToTimeKey	INT
,@CrModApBy            VARCHAR(20)='' 
,@Result                INT   =0 OUTPUT 
,@D2Ktimestamp	        TIMESTAMP     =0  OUTPUT
,@TimeKey				INT
--,@UserID int
--DECLARE
-- @xmlDocument XML
--,@OperationFlag INT
--,@AuthMode      CHAR(2)
--,@EffectiveFromTimeKey	INT
--,@EffectiveToTimeKey	INT
--,@CrModApBy            VARCHAR(20)='' 
--,@Result                INT   =0 --OUTPUT 
--,@D2Ktimestamp	        TIMESTAMP     =0   --OUTPUT
--,@TimeKey				INT

AS 

DECLARE			  @AuthorisationStatus CHAR(2)=NULL			
				 ,@CreatedBy VARCHAR(20) =NULL
				 ,@DateCreated SMALLDATETIME=NULL
				 ,@ModifiedBy VARCHAR(20) =NULL
				 ,@DateModified SMALLDATETIME=NULL
				 ,@ApprovedBy  VARCHAR(20)=NULL
				 ,@DateApproved  SMALLDATETIME=NULL
				 ,@ExEntityKey AS INT=0
				 ,@ErrorHandle int=0 


IF OBJECT_ID('TEMPDB..##NPA_IntegrationDetail')IS NOT NULL
	DROP TABLE ##NPA_IntegrationDetail

	SELECT 
	c.value('./AssetClass[1]','tinyint')AssetClass
	,c.value('./NPA_Date[1]','varchar(10)')NPA_Date
	,c.value('./EnterRemark[1]','varchar(150)')EnterRemark
	,c.value('./SrcSysAlt_Key[1]','tinyint')SourceSystem
	,c.value('./ClientID[1]','varchar(20)')ClientId
	,c.value('./AccountEntityID[1]','INT')AccountNo
	,c.value('./ApprovedAll[1]','varchar(7)')ApproveAll 
	,c.value('./RejectAll[1]','varchar(7)')RejectAll
	,c.value('./RejectionRemark[1]','varchar(150)')RejectRemark
	,c.value('./AstClsChngRemark[1]','varchar(150)')AstClsChngRemark
	INTO ##NPA_IntegrationDetail
    FROM @xmlDocument.nodes('/DataSet/GridData') AS t(c)  --/DataSet/GridData


ALTER TABLE ##NPA_IntegrationDetail
 ADD  ModifiedBy VARCHAR(20)
	 ,DateModified DATETIME


	 


DECLARE
 @Approved CHAR(1)='N'
,@Rejected CHAR(1)='N'

IF EXISTS (SELECT 1 FROM ##NPA_IntegrationDetail WHERE ApproveAll='true' AND RejectAll='false')
	BEGIN
	
			SET @Approved ='Y'
	END	

IF EXISTS (SELECT 1 FROM ##NPA_IntegrationDetail WHERE ApproveAll='false' AND RejectAll='true')
	BEGIN
	
			
			SET @Rejected ='Y'
	END

IF EXISTS (SELECT 1 FROM ##NPA_IntegrationDetail WHERE ApproveAll='true' AND RejectAll='true' )
	BEGIN
				SET @Approved ='Y'
				SET @Rejected ='Y'	
	END
	


BEGIN TRY
BEGIN TRANSACTION																
																 
IF @OperationFlag=1 AND @AuthMode='Y'
	BEGIN
			
			SET @CreatedBy =@CrModApBy 
			SET @DateCreated = GETDATE()
			SET @AuthorisationStatus='NP'
			
			GOTO NPA_IntegrationDetail_Insert
			NPA_IntegrationDetail_Insert_Add:
			PRINT 5
	END

ELSE IF(@OperationFlag =2 OR @OperationFlag = 3) AND @AuthMode = 'Y'
	 BEGIN
				PRINT 22222	
				
				
				SET @Modifiedby=@CrModApBy   -----add
				SET @DateModified =GETDATE()   -----add	

				IF @OperationFlag = 2
						BEGIN
							SET @AuthorisationStatus ='MP'
						END

					ELSE
						BEGIN
							SET @AuthorisationStatus ='DP'
						END

				---FIND CREATED BY FROM MAIN TABLE
				
				SELECT  @CreatedBy		= A.CreatedBy
						,@DateCreated	= A.DateCreated 
				FROM NPA_IntegrationDetails A
				INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
															AND A.AccountEntityId =B.AccountNo
															AND A.CustomerId=B.ClientId
				
			   ---FIND CREATED BY FROM MOD TABLE IN CASE OF DATA IS NOT AVAILABLE IN MAIN TABLE
			   
			   IF ISNULL(@CreatedBy,'')=''
				  BEGIN
						SELECT  @CreatedBy		= A.CreatedBy
								,@DateCreated	= A.DateCreated 
						FROM NPA_IntegrationDetails_MOD A
						INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																	AND A.AccountEntityId =B.AccountNo
																	AND A.CustomerId=B.ClientId	
						WHERE A.AuthorisationStatus IN ('NP','MP','RM')												
				  
				  END	
				  
			 --IF DATA IS AVAILABLE IN MAIN TABLE	
			 ELSE 
				 BEGIN
							UPDATE A
							SET A.AuthorisationStatus=@AuthorisationStatus  
							FROM NPA_IntegrationDetails A
							INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																		AND A.AccountEntityId =B.AccountNo
																		AND A.CustomerId=B.ClientId
				 END	
				 
			 ---UPDTAE FM FLAG
			 		 											
				UPDATE A
				SET A.AuthorisationStatus='FM'
					,A.ModifiedBy=@Modifiedby 
					,A.DateModified=@DateModified 
				FROM NPA_IntegrationDetails_MOD A
				INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
															AND A.AccountEntityId =B.AccountNo
															AND A.CustomerId=B.ClientId
		        WHERE A.AuthorisationStatus IN ('NP','MP')
				
				GOTO NPA_IntegrationDetail_Insert
				NPA_IntegrationDetail_Insert_Edit:
				PRINT 6
																
			
	 END

ELSE IF @OperationFlag=3 AND @AuthMode='N'
	BEGIN
				--MAKER CHECK DISABLE
				SET @Modifiedby   = @CrModApBy 
				SET @DateModified = GETDATE() 	

				UPDATE A
				SET 
					--A.EffectiveToTimeKey=@EffectiveFromTimeKey-1
					 ModifiedBy =@Modifiedby 
					,DateModified =@DateModified 
					,A.AuthorisationStatus='DP'
				FROM NPA_IntegrationDetails A
				INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
															AND A.AccountEntityId =B.AccountNo
														 	AND A.CustomerId=B.ClientId
	END

ELSE IF @OperationFlag=17 AND @AuthMode='Y'
		BEGIN
					SET @ApprovedBy	   = @CrModApBy 
					SET @DateApproved  = GETDATE()

					UPDATE A
					SET  
						--A.EffectiveToTimeKey=@EffectiveFromTimeKey-1
						 A.AuthorisationStatus='R'
						,A.ApprovedBy	 =@ApprovedBy
						,A.DateApproved	 =@DateApproved
						
					FROM NPA_IntegrationDetails_MOD A
					INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																AND A.AccountEntityId =B.AccountNo
																AND A.CustomerId=B.ClientId
																AND B.RejectAll='true'
					WHERE A.AuthorisationStatus in('NP','MP','DP','RM')	

					UPDATE A
					SET A.AuthorisationStatus='A'
					FROM NPA_IntegrationDetails A
					INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																AND A.AccountEntityId =B.AccountNo
																AND A.CustomerId=B.ClientId	
																AND B.RejectAll='true'
					WHERE A.AuthorisationStatus IN('MP','DP','RM')																							

		END

ELSE IF @OperationFlag=16 OR @AuthMode='Y'
		BEGIN
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

							SELECT	@CreatedBy=A.CreatedBy,@DateCreated=A.DATECreated
							FROM NPA_IntegrationDetails A
							INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
															AND A.AccountEntityId =B.AccountNo
															AND A.CustomerId=B.ClientId
							WHERE B.ApproveAll='true'									
						
						SET @ApprovedBy = @CrModApBy			
						SET @DateApproved=GETDATE()

						END
				END
				
				IF @AuthMode='Y'
					BEGIN
							

								IF OBJECT_ID('TEMPDB..##EntityKeyData')IS NOT NULL
								DROP TABLE ##EntityKeyData	

								SELECT MAX(A.EntityKey) AS EntityKey INTO ##EntityKeyData FROM NPA_IntegrationDetails_MOD A
														 INNER JOIN ##NPA_IntegrationDetail   B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																										AND A.AccountEntityId=B.AccountNo
																										AND A.CustomerId=B.ClientId
																										AND B.ApproveAll='true'	
								WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')
								GROUP BY AccountEntityId

		
							--UPDATE A
							--SET  A.ModifiedBy=B.ModifiedBy
							--	,A.DateModified=B.DateModified
							--	,A.AuthorisationStatus=B.AuthorisationStatus
							--	,A.EnterRemark=B.AstClsChngRemark
							--	,A.AssetClass=B.AC_AssetClassAlt_Key
							--	,A.NPA_Date=B.AC_NPA_Date
							--FROM  ##NPA_IntegrationDetail A
							--INNER JOIN
							--(
							--		SELECT AccountEntityId,CustomerId,ModifiedBy,DateModified,AuthorisationStatus,AstClsChngRemark,AC_NPA_Date,AC_AssetClassAlt_Key FROM NPA_IntegrationDetails_MOD A
							--		WHERE  (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey) AND A.AuthorisationStatus IN ('NP','MP','DP','RM') AND 
							--		EntityKey IN (
							--						SELECT MAX(A.EntityKey) AS EntityKey  FROM NPA_IntegrationDetails_MOD A
							--							 INNER JOIN ##NPA_IntegrationDetail   B   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
							--														AND A.AccountEntityId=B.AccountNo
							--														AND A.CustomerId=B.ClientId
							--														AND B.ApproveAll='true'	
							--							 WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')
							--						GROUP BY AccountEntityId		 
							--					 )			
							--)B  ON B.AccountEntityId=A.AccountNo	
							--		AND B.CustomerId=A.ClientId	
							--WHERE A.ApproveAll='true'	
							
							UPDATE A
							SET  A.ModifiedBy=B.ModifiedBy
								,A.DateModified=B.DateModified
								,A.EnterRemark=B.AstClsChngRemark
								,A.AssetClass=B.AC_AssetClassAlt_Key
								,A.NPA_Date=CAST(B.AC_NPA_Date AS DATE)

							FROM  ##NPA_IntegrationDetail A
							INNER JOIN
							(
									SELECT AccountEntityId,CustomerId,ModifiedBy,DateModified,AuthorisationStatus,AstClsChngRemark,AC_NPA_Date,AC_AssetClassAlt_Key,CreatedBy,DateCreated FROM 
									NPA_IntegrationDetails_MOD A
									INNER JOIN ##EntityKeyData B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey) 
																			AND B.EntityKey=A.EntityKey
							        WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM') 													
																			
									 
							 )B  ON B.AccountEntityId=A.AccountNo	
									AND B.CustomerId=A.ClientId	
							WHERE A.ApproveAll='true'		

							SET @ApprovedBy = @CrModApBy	
							SET @DateApproved=GETDATE()	
							
						
									
					END	

				/*IF <> DP FLAG*/
				UPDATE A
				SET A.AuthorisationStatus ='A'
					,A.ApprovedBy=@ApprovedBy
					,A.DateApproved=@DateApproved
					,A.Remark=B.RejectRemark
				FROM NPA_IntegrationDetails_MOD A
				INNER JOIN ##NPA_IntegrationDetail  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
														  AND A.AccountEntityId=B.AccountNo
														  AND A.CustomerId=B.ClientId
														  AND B.ApproveAll='true'
				WHERE A.AuthorisationStatus IN('NP','MP','RM') 
					

				/*IF <> DP FLAG*/


				IF @Rejected='Y'
					BEGIN
				
							 /*REJECT RECORD */	

							   UPDATE A
								SET  --A.EffectiveToTimeKey=@EffectiveFromTimeKey-1
									 A.AuthorisationStatus='R'
									,ApprovedBy		=@ApprovedBy
									,A.DateApproved = @DateApproved
									,A.Remark		=B.RejectRemark
								FROM NPA_IntegrationDetails_MOD A
								INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																			AND A.AccountEntityId =B.AccountNo
																			AND A.CustomerId=B.ClientId
																			AND B.RejectAll='true'
								WHERE A.AuthorisationStatus in('NP','MP','DP','RM')	

								UPDATE A
								SET A.AuthorisationStatus='A'
								FROM NPA_IntegrationDetails A
								INNER JOIN ##NPA_IntegrationDetail	B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																			AND A.AccountEntityId =B.AccountNo
																			AND A.CustomerId=B.ClientId	
																			AND B.RejectAll='true'
								WHERE A.AuthorisationStatus IN('MP','DP','RM','NP')	
							 /*REJECT RECORD */	
						END
									
						
				IF @Approved='Y'
					BEGIN
							PRINT 'YYYYYY'
					
							/*SCD1*/
										UPDATE A
										SET  
											  A.AC_AssetClassAlt_Key=B.AssetClass
											 ,A.AC_NPA_Date=NULLIF(CAST(B.NPA_Date AS DATE),'')
											 ,A.AstClsChngRemark=B.EnterRemark
											 ,A.AuthorisationStatus ='A'
											 ,A.ApprovedBy=@ApprovedBy
											 ,A.DateApproved=@DateApproved
											 ,A.ModifiedBy=B.ModifiedBy
											 ,A.DateModified=B.DateModified
											 ,A.AstClsChngByUser='Y'
											 ,A.AstClsChngDate=B.DateModified
											 ,A.AstClsAppRemark	=B.RejectRemark 
											 
										FROM NPA_IntegrationDetails A
										INNER JOIN ##NPA_IntegrationDetail  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																				  AND A.AccountEntityId=B.AccountNo
																				  AND A.CustomerId=B.ClientId
																				  AND B.ApproveAll='true'
							 
							 /*SCD1*/	
							 
					END	
					
																																

			
		END

SET @ErrorHandle=1

NPA_IntegrationDetail_Insert:

IF @ErrorHandle=0
	BEGIN
			PRINT 111111
			IF NOT EXISTS (  SELECT 1 FROM NPA_IntegrationDetails_MOD  A INNER JOIN ##NPA_IntegrationDetail B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																													AND A.AccountEntityId=B.AccountNo
																													AND A.CustomerId=B.ClientId
								WHERE A.AuthorisationStatus='O'
							)
				BEGIN
							/*Insert Original Records*/
							print 'vinayak'

							INSERT INTO NPA_IntegrationDetails_MOD
							(
									 NCIF_Id
									,NCIF_Changed
									,SrcSysAlt_Key
									,NCIF_EntityID
									,CustomerId
									,CustomerName
									,AccountEntityID
									,CustomerACID
									,AC_AssetClassAlt_Key
									,AC_NPA_Date
									,AstClsChngByUser
									,AstClsChngDate
									,AstClsChngRemark
									,AuthorisationStatus
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
							 A.NCIF_Id
							,A.NCIF_Changed
							,A.SrcSysAlt_Key
							,A.NCIF_EntityID
							,A.CustomerId
							,A.CustomerName
							,A.AccountEntityID
							,A.CustomerACID
							,A.AC_AssetClassAlt_Key
							,NULLIF(A.AC_NPA_Date,'1900-01-01')AC_NPA_Date
							,A.AstClsChngByUser
							,A.AstClsChngDate
							,A.AstClsChngRemark
							,'O'---AuthorisationStatus
							,A.EffectiveFromTimeKey
							,A.EffectiveToTimeKey
							,A.CreatedBy
							,A.DateCreated
							,A.ModifiedBy
							,A.DateModified
							,A.ApprovedBy
							,A.DateApproved
							FROM NPA_IntegrationDetails A
							INNER JOIN ##NPA_IntegrationDetail   B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																		AND A.AccountEntityId=B.AccountNo
																		AND A.CustomerId=B.ClientId
																		---AND ISNULL(A.AuthorisationStatus,'A')='A'
				END

			--ELSE
			--		BEGIN
			print 'vinayak1'
							INSERT INTO NPA_IntegrationDetails_MOD
							(
									 NCIF_Id
									,NCIF_Changed
									,SrcSysAlt_Key
									,NCIF_EntityID
									,CustomerId
									,CustomerName
									,CustomerACID
									,AccountEntityID
									,AC_AssetClassAlt_Key
									,AC_NPA_Date
									,AstClsChngByUser
									,AstClsChngDate
									,AstClsChngRemark
									,Remark
									,AuthorisationStatus
									,EffectiveFromTimeKey
									,EffectiveToTimeKey
									,CreatedBy
									,DateCreated
									,ModifiedBy
									,DateModified
							)

							SELECT 
							 A.NCIF_Id
							,A.NCIF_Changed
							,A.SrcSysAlt_Key
							,A.NCIF_EntityID
							,B.ClientId
							,A.CustomerName
							,A.CustomerACID
							,B.AccountNo
							,B.AssetClass
							,NULLIF(CAST(B.NPA_Date AS DATE),'')
							,'Y'--AstClsChngByUser
							,@DateModified--AstClsChngDate
							,B.AstClsChngRemark
							,B.RejectRemark
							,@AuthorisationStatus---AuthorisationStatus
							,@EffectiveFromTimeKey
							,@EffectiveToTimeKey
							,A.CreatedBy
							,A.DateCreated
							,@ModifiedBy
							,@DateModified
							FROM ##NPA_IntegrationDetail B 
							INNER JOIN NPA_IntegrationDetails A   ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																		AND A.AccountEntityId=B.AccountNo
																		AND A.CustomerId=B.ClientId	
																    
				IF @OperationFlag =1 AND @AUTHMODE='Y'
					BEGIN
						PRINT 3
						GOTO NPA_IntegrationDetail_Insert_Add

					END
				ELSE IF (@OperationFlag =2 OR @OperationFlag =3)AND @AUTHMODE='Y'
					BEGIN
						GOTO NPA_IntegrationDetail_Insert_Edit
					END										
																		
					

	END

COMMIT TRANSACTION
	IF @OperationFlag <>3 
		BEGIN
			SELECT TOP 1 @D2Ktimestamp =CAST(D2Ktimestamp AS INT) FROM NPA_IntegrationDetails_MOD  A
			INNER JOIN ##NPA_IntegrationDetail   B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																		AND A.AccountEntityId=B.AccountNo
																		AND A.CustomerId=B.ClientId
															
			SET @Result=1
			RETURN  @Result
		END
	ELSE
		BEGIN
			SET @Result=0
			RETURN @Result
		END
END TRY
BEGIN CATCH
		PRINT ERROR_MESSAGE()
		ROLLBACK TRAN
				SET @Result=-1
				RETURN @Result

END CATCH

	

GO