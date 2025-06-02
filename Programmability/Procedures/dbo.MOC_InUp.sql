SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[MOC_InUp]
	
 @XmlDocument  XML
,@OperationFlag	SMALLINT
,@AuthMode      CHAR(2)
,@EffectiveFromTimeKey	INT
,@EffectiveToTimeKey	INT
,@CrModApBy            VARCHAR(20)=''
,@Result                INT   =0 OUTPUT
,@D2Ktimestamp	        TIMESTAMP     =0 OUTPUT 
,@TimeKey				INT
,@UserID varchar(20)
AS

--DECLARE
-- @XmlDocument  XML
--,@OperationFlag	SMALLINT
--,@AuthMode      CHAR(2)
--,@EffectiveFromTimeKey	INT
--,@EffectiveToTimeKey	INT
--,@CrModApBy            VARCHAR(20)=''
--,@Result                INT   =0 --OUTPUT
--,@D2Ktimestamp	        TIMESTAMP     =0  --OUTPUT 
--,@TimeKey				INT

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


IF OBJECT_ID('TEMPDB..#NCIF_NPA_Data')IS NOT NULL
DROP TABLE #NCIF_NPA_Data

SELECT
  c.value('./ENTCIF[1]','INT')ENTCIF
 ,c.value('./CustomerName[1]','varchar(80)')CustomerName
 ,c.value('./PAN[1]','varchar(10)')PAN
 ,c.value('./AssetClassAlt_Key[1]','tinyint')AssetClass
 ,c.value('./NPA_Date[1]','varchar(10)')NPA_Date
 ,c.value('./ReasonRemark[1]','varchar(150)')ReasonRemark
 ,CASE WHEN c.value('./ApprovedAll[1]','varchar(5)') ='true' THEN 'Y' ELSE 'N' END AS ApproveAll
 ,CASE WHEN c.value('./RejectAll[1]','varchar(5)')='true' THEN 'Y'ELSE 'N' END AS RejectAll
 ,c.value('./RejectionRemark[1]','varchar(150)')RejectionRemark
 ,c.value('./Remark[1]','varchar(200)')MOC_Remark
 INTO #NCIF_NPA_Data
 FROM @XmlDocument.nodes('DataSet/GridData') AS t(c)



ALTER TABLE #NCIF_NPA_Data
ADD   ModifiedBy VARCHAR(20)
	 ,DateModified DATETIME	
	 ,AuthorisationStatus VARCHAR(2)
	 ,SrcSysAlt_Key    TINYINT
	 ,CustomerId		VARCHAR(20)

 DECLARE
  @ApprovedAll  CHAR(1)='N'
 ,@RejectAll   CHAR(1)='N'

 IF EXISTS(SELECT 1 FROM #NCIF_NPA_Data WHERE ApproveAll='Y' AND RejectAll='N')
	BEGIN
				SET @ApprovedAll='Y'

	END

IF EXISTS(SELECT 1 FROM #NCIF_NPA_Data WHERE RejectAll='Y' AND ApproveAll='N')
	BEGIN
				SET @RejectAll='Y'
	END

IF EXISTS(SELECT 1 FROM #NCIF_NPA_Data WHERE ApproveAll='Y' AND RejectAll='N')
	BEGIN
				PRINT 'YY'
				SET  @RejectAll='Y'
				SET  @ApprovedAll='Y'
	END

/*FIND MINIMUM ACCOUNT */

--DECLARE
-- @MIN_AccountEntityId INT
--,@AC_AssetClassAlt_Key TINYINT
--,@AC_NPA_Dt			   DATE
--,@NCIF_EntityID  INT

--SELECT @AC_AssetClassAlt_Key=A.NCIF_AssetClassAlt_Key ,@AC_NPA_Dt=A.NCIF_NPA_Date,@NCIF_EntityID=NCIF_EntityID  FROM NPA_IntegrationDetails A
--INNER JOIN #NCIF_NPA_Data     B  ON	(EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
--										AND A.NCIF_EntityID=B.ENTCIF
--										AND ISNULL(A.AuthorisationStatus,'A')='A'	   
--GROUP BY NCIF_EntityID,NCIF_AssetClassAlt_Key,NCIF_NPA_Date

--SELECT @MIN_AccountEntityId=MIN(AccountEntityID) FROM NPA_IntegrationDetails
--WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) AND NCIF_EntityID=@NCIF_EntityID
--		AND AC_AssetClassAlt_Key=@AC_AssetClassAlt_Key AND AC_NPA_Date=@AC_NPA_Dt
--		AND ISNULL(AuthorisationStatus,'A')='A'	
--GROUP BY NCIF_EntityID


/*FIND MINIMUM ACCOUNT CRETAED BY AND DATECREATED */

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
				SELECT @CreatedBy=CreatedBy ,@DateCreated=DateCreated FROM NPA_IntegrationDetails A
				INNER JOIN #NCIF_NPA_Data  B  ON A.NCIF_EntityID=B.ENTCIF
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
						--AND AccountEntityID=@MIN_AccountEntityId
			    GROUP BY CreatedBy,DateCreated			
					
				 ---FIND CREATED BY FROM MOD TABLE IN CASE OF DATA IS NOT AVAILABLE IN MAIN TABLE
			   IF ISNULL(@CreatedBy,'')=''
					BEGIN
							
							SELECT @CreatedBy=CreatedBy ,@DateCreated=DateCreated FROM MOC_NPA_IntegrationDetails_MOD A
							INNER JOIN #NCIF_NPA_Data  B  ON A.NCIF_EntityID=B.ENTCIF
							WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							AND A.AuthorisationStatus IN ('NP','MP','DP','RM')
							GROUP BY CreatedBy,DateCreated
					END	
					
				--IF DATA IS AVAILABLE IN MAIN TABLE
				
				ELSE
					 BEGIN
								UPDATE A
								SET A.AuthorisationStatus=@AuthorisationStatus
								FROM NPA_IntegrationDetails A
								INNER JOIN #NCIF_NPA_Data  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																   AND A.NCIF_EntityID=B.ENTCIF
					 END
					 
			   --UPDTAE FM FLAG
			   UPDATE A
			   SET A.AuthorisationStatus='FM'
			   FROM  MOC_NPA_IntegrationDetails_MOD A
			   INNER JOIN #NCIF_NPA_Data B ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)									
											 AND A.NCIF_EntityID=B.ENTCIF
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
				---,A.EffectiveToTimeKey=@EffectiveFromTimeKey-1
				,A.MOC_Status='Y'
				,A.MOC_Date=@ModifiedBy
			FROM NPA_IntegrationDetails A
			INNER JOIN #NCIF_NPA_Data  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
											   AND A.NCIF_EntityID=B.ENTCIF
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
			INNER JOIN #NCIF_NPA_Data  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_EntityID=B.ENTCIF
			WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')

			UPDATE A
			SET A.AuthorisationStatus='A'
			FROM NPA_IntegrationDetails A
			INNER JOIN #NCIF_NPA_Data  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_EntityID=B.ENTCIF
			WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')		
			
			update A  set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			FROM DocumentUploadDetails A INNER JOIN #NCIF_NPA_Data B ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_EntityID=B.ENTCIF					
													

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

									SELECT @CreatedBy=CreatedBy ,@DateCreated=DateCreated FROM NPA_IntegrationDetails A
									INNER JOIN #NCIF_NPA_Data  B  ON A.NCIF_EntityID=B.ENTCIF
									WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
									---AND AccountEntityID=@MIN_AccountEntityId
									AND B.ApproveAll=1
									GROUP BY CreatedBy,DateCreated

									SET @ApprovedBy=@CrModApBy
									SET @DateApproved=GETDATE()
							END			

				END

			IF @AuthMode='Y'
				BEGIN
						IF OBJECT_ID('TEMPDB..#EntityKeyData')IS NOT NULL
						DROP TABLE #EntityKeyData	
						
						SELECT MAX(EntityKey)EntityKey INTO #EntityKeyData FROM MOC_NPA_IntegrationDetails_MOD A
						INNER JOIN #NCIF_NPA_Data  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
														  AND A.NCIF_EntityID=B.ENTCIF
					    WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')
						GROUP BY A.NCIF_Id




						UPDATE A
						SET 
						 A.PAN=B.PAN
						,A.CustomerName=A.CustomerName
						,A.CustomerId=b.CustomerId
						,A.NPA_Date=B.MOC_NPA_Date
						,A.AssetClass=B.MOC_AssetClassAlt_Key
						,A.ModifiedBy=B.ModifiedBy
						,A.DateModified=B.DateModified
						,A.AuthorisationStatus=B.AuthorisationStatus
						,A.ReasonRemark=B.MOC_ReasonAlt_Key
						,A.MOC_Remark = B.MOC_Remark
						FROM #NCIF_NPA_Data  A
						INNER JOIN
						(
							SELECT A.PAN,A.CustomerId,A.CustomerName,A.MOC_AssetClassAlt_Key,A.MOC_NPA_Date
							,A.ModifiedBy,A.DateModified,A.AuthorisationStatus,A.NCIF_Id,A.NCIF_EntityID,A.MOC_ReasonAlt_Key,MOC_Remark
							FROM MOC_NPA_IntegrationDetails_MOD  A
							INNER JOIN #EntityKeyData B ON A.EntityKey=B.EntityKey
						)B  ON A.ENTCIF=B.NCIF_EntityID

						SET @ApprovedBy = @CrModApBy	
						SET @DateApproved=GETDATE()	
						
										
				END	
				
			/*IF <> DP FLAG*/
			UPDATE A
			SET  A.AuthorisationStatus='A'
				,A.DateApproved=@DateApproved
				,A.ApprovedBy=@ApprovedBy
				,A.MocAppRemark=B.RejectionRemark
			FROM MOC_NPA_IntegrationDetails_MOD  A
			INNER JOIN #NCIF_NPA_Data   B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
										        AND A.NCIF_EntityID=B.ENTCIF
												AND B.ApproveAll='Y'
			WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')
			/*IF <> DP FLAG*/	
			
			IF @RejectAll='Y'
				BEGIN
							
						UPDATE A
						SET A.AuthorisationStatus='R'
							,A.DateApproved=@DateApproved
							,A.ApprovedBy=@ApprovedBy
							,A.MocAppRemark=B.RejectionRemark
						FROM MOC_NPA_IntegrationDetails_MOD  A
						INNER JOIN #NCIF_NPA_Data   B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
													        AND A.NCIF_EntityID=B.ENTCIF
															AND B.RejectAll='Y'
						WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')


						UPDATE A
						SET A.AuthorisationStatus='A'
						FROM NPA_IntegrationDetails  A
						INNER JOIN #NCIF_NPA_Data   B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
													        AND A.NCIF_EntityID=B.ENTCIF
															AND B.RejectAll='Y'
						WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')

						update A  set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			            FROM DocumentUploadDetails A INNER JOIN #NCIF_NPA_Data B ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_EntityID=B.ENTCIF AND B.RejectAll='Y'
				END
	

			IF @ApprovedAll='Y'
				BEGIN
							/*SCD1*/
							PRINT '@ApprovedAll_Y'

							--SELECT * FROM #NCIF_NPA_Data
							UPDATE A
							SET A.AuthorisationStatus='A'
								,A.MOC_AssetClassAlt_Key=B.AssetClass
								,A.MOC_NPA_Date=NULLIF(CAST(B.NPA_Date AS DATE),'')
								,A.ModifiedBy=B.ModifiedBy
								,A.DateModified=B.DateModified
								,A.ApprovedBy=@ApprovedBy
								,A.DateApproved=@DateApproved
								,A.MOC_Status='Y'
								,A.MOC_ReasonAlt_Key=B.ReasonRemark
								,A.MOC_Date=B.DateModified
								,A.MocAppRemark=RejectionRemark 
								,A.MOC_Remark =B.MOC_Remark
							FROM NPA_IntegrationDetails  A
							INNER JOIN #NCIF_NPA_Data   B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
														        AND A.NCIF_EntityID=B.ENTCIF
																AND B.ApproveAll='Y'
							WHERE A.AuthorisationStatus IN ('NP','MP','DP','RM')
							/*SCD1*/	

					END

			
						

	END





SET @ErrorHandle=1
NCIF_AssetClassDetail_Insert:
IF @ErrorHandle=0
	BEGIN

		
			IF NOT EXISTS (SELECT 1 FROM MOC_NPA_IntegrationDetails_MOD A INNER JOIN #NCIF_NPA_Data B ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																											AND A.NCIF_EntityID=B.ENTCIF
							WHERE A.AuthorisationStatus='O'																					
						  )
							BEGIN

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

										FROM NPA_IntegrationDetails A
										INNER JOIN #NCIF_NPA_Data  B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																		   AND A.NCIF_EntityID=B.ENTCIF
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
										
																			
							END

			
								INSERT INTO MOC_NPA_IntegrationDetails_MOD	
								(
									 NCIF_Id
									,MOC_AssetClassAlt_Key
									,MOC_NPA_Date
									--,SrcSysAlt_Key
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
								)

								SELECT 
								 B.NCIF_Id
								,A.AssetClass
								,NULLIF(CAST(A.NPA_Date AS DATE),'')
								--,B.SrcSysAlt_Key
								,A.ENTCIF
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
								,ReasonRemark
								---,CASE WHEN @OperationFlag=16 THEN A.RejectionRemark ELSE A.MOC_Remark END
								,A.MOC_Remark

								FROM #NCIF_NPA_Data A
								--INNER JOIN NPA_IntegrationDetails B ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
								--										 AND B.NCIF_EntityID=A.ENTCIF
								--										 --AND ISNULL(B.AuthorisationStatus,'A')='A'
							 --   WHERE 	B.AccountEntityID=@MIN_AccountEntityId	
							 
							   INNER JOIN (SELECT NCIF_EntityID,NCIF_Id,MAX(CustomerName)CustomerName,MAX(PAN)PAN FROM NPA_IntegrationDetails
										    WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
										     GROUP BY NCIF_EntityID,NCIF_Id	
											)B  ON 	B.NCIF_EntityID=A.ENTCIF									
						
						

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
											INNER JOIN #NCIF_NPA_Data   B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
																				AND A.NCIF_EntityID=B.ENTCIF
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
			 INSERT INTO ErrorLog (ErrorNumber,ErrorMsg,ErrorProc,ErrorCrDt)
				SELECT ERROR_NUMBER() [ERROR_NUMBER] ,ERROR_MESSAGE()[ERROR_MESSAGE],ERROR_PROCEDURE()[ERROR_PROCEDURE],GETDATE()[ErrorDt]	

					SELECT * FROM ErrorLog  WHERE ErrorCrDt= 
					(
						SELECT MAX(ErrorCrDt)ErrorCrDt FROM ErrorLog  WHERE ErrorNumber=(SELECT ERROR_NUMBER())

					)
			SET @Result=-1
			RETURN @Result
		END CATCH
GO