SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[LogDetailsInsertUpdate]    Script Date: 03/09/2012 17:45:04 ******/
CREATE PROCEDURE [dbo].[LogDetailsInsertUpdate_Attendence]            
					@BranchCode varchar(10),
					@MenuID int=0,
					@ReferenceID varchar(50),
					@ALTERdBy varchar(20),
					@ApprovedBy varchar(20),
					@ALTERdCheckedDt smalldatetime,
					@Remark varchar(200)='',
					@ScreenEntityAlt_Key int=16,---Adeed by kunj on 29/03/12 for Passing Unique Screen Identity
					@Flag	SMALLINT,
					@AuthMode char(1)='N'
AS            

Declare @EntityKey int,
	@LogCreationStatus	AS VARCHAR(2)
	
	SET DATEFORMAT DMY;
	SET NOCOUNT ON;                            
	
IF @AuthMode='Y' 
BEGIN
	IF @Flag = 1 OR @Flag = 6
                           
	BEGIN 
			
				IF EXISTS(SELECT 1 FROM SysUserActivityLog_Attendence WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key)
					BEGIN
							UPDATE SysUserActivityLog_Attendence 
								SET 
									LogCreationStatus='NP'
									,LogStatus='P'
									,LogALTERdBy=@ALTERdBy
									,LogCheckedBy= NULL 
									,LogCheckedDt= NULL 
									,Remark		= NULL 
							WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key

					END
						
				ELSE	
					BEGIN
						SELECT @EntityKey = ISNULL(MAX(EntityKey),0) + 1 FROM SysUserActivityLog_Attendence                        						
							
							INSERT INTO SysUserActivityLog_Attendence    
							(	 
									 EntityKey
									,BranchCode
									,MenuID
									,ReferenceID
									,LogCreationStatus
									,LogALTERdBy
									,LogALTERdDt
									,LogStatus
									,Remark
									,ScreenEntityAlt_Key
							)                             				
							SELECT 				
									 @EntityKey
									,@BranchCode
									,@MenuID
									,@ReferenceID
									,'NP'
									,@ALTERdBy
									,@ALTERdCheckedDt
									,'P'
									,@Remark
									,@ScreenEntityAlt_Key
					END	
				

	END
	IF @Flag =2 OR @Flag=3  OR @Flag=8
	BEGIN 
	PRINT 'ENTERED IN EDIT MODE'
			IF @Flag =2
					BEGIN
						SET @LogCreationStatus='MP'	
						PRINT 2
					END
			ELSE IF @Flag=3 OR @Flag=8
					BEGIN
						SET @LogCreationStatus='DP'	
					END
					SET @ALTERdCheckedDt = GETDATE()
					IF EXISTS(SELECT 1 FROM SysUserActivityLog_Attendence WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key)
						BEGIN
																	
								UPDATE SysUserActivityLog_Attendence SET LogCreationStatus=@LogCreationStatus 
									  ,LogStatus='P'
									  ,LogALTERdBy=@ALTERdBy
								WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID 
								AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key

								
						END
						
					IF NOT EXISTS(SELECT 1 FROM SysUserActivityLog_Attendence WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key)
						BEGIN
								SELECT @EntityKey = ISNULL(MAX(EntityKey),0) + 1 FROM SysUserActivityLog_Attendence
						
								INSERT INTO SysUserActivityLog_Attendence    
								(	 
										 EntityKey
										,BranchCode
										,MenuID
										,ReferenceID
										,LogCreationStatus
										,LogALTERdBy
										,LogALTERdDt
										,LogStatus
										,Remark
										,ScreenEntityAlt_Key
								)                             				
								SELECT 				
										 @EntityKey
										,@BranchCode
										,@MenuID
										,@ReferenceID
										,@LogCreationStatus
										,@ALTERdBy
										,@ALTERdCheckedDt
										,'P'
										,@Remark
										,@ScreenEntityAlt_Key
						END
				
		END

IF @Flag = 16 OR @Flag =17  -- AUTHORISE OR REJECT
	BEGIN
	                   print 'aaaaaaaaaaa'
						IF @ScreenEntityAlt_Key=0 
							BEGIN 
							   print 1
							END
						ELSE IF @ScreenEntityAlt_Key=4 --FOR RELATIONSHIP ADITIONAL SCREEN
							BEGIN
								PRINT 'ADD_REL1'							
								
							END
						ELSE
							BEGIN
								print 'UPDATE  SysUserActivityLog_Attendence'							
								PRINT @Remark
								UPDATE  SysUserActivityLog_Attendence SET  
										LogStatus=CASE WHEN @Flag=16 THEN 'A'  -- AUTHORISE
														ELSE 'R' END, -- REJECT
										LogCheckedBy= @ApprovedBy,
										LogCheckedDt= @ALTERdCheckedDt,
										Remark		= @Remark 

								WHERE BranchCode=@BranchCode 
									AND ReferenceID=@ReferenceID
									AND MenuID=@MenuID
									AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key

									print 'bjdskdhjfhdlfj'
					---For Edit,Delete,Authorise,Reject count 	
						Select @LogCreationStatus=LogCreationStatus FROM SysUserActivityLog_Attendence 
								WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID 
								AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key
								print 'select'
						UPDATE SysUserActivityLog_Attendence
						SET		DeleteCount= CASE WHEN @LogCreationStatus='DP' THEN ISNULL(DeleteCount,0)+1 ELSE DeleteCount END,
								EditCount=CASE WHEN @LogCreationStatus='MP' THEN ISNULL(EditCount,0)+1 ELSE EditCount END
						WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID 
								AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key
								

						UPDATE  SysUserActivityLog_Attendence
						SET AuthoriseCount= CASE WHEN @Flag=16 THEN ISNull(AuthoriseCount,0)+1 ELSE  AuthoriseCount END	,
						 RejectCount= CASE WHEN @Flag=17 THEN  ISNull(RejectCount,0)+1  ELSE  RejectCount END	
																  			
						WHERE BranchCode=@BranchCode 
							AND ReferenceID=@ReferenceID
							AND MenuID=@MenuID
							AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key 

							END
				------------------
			END	
		
	IF @Flag = 18 
	BEGIN
			PRINT 11111111	
			PRINT @ReferenceID
			DECLARE @ExEntityKeyRemark INT
				Select @ExEntityKeyRemark = Max(EntityKey) FROM SysUserActivityLog_Attendence 
									WHERE MenuID =@MenuID and BranchCode =@BranchCode 
									and ReferenceID =@ReferenceID 
		
			DECLARE @SlashPosition INT
			SET @SlashPosition=(SELECT CHARINDEX('/',@ReferenceID,0))

								
			BEGIN TRANSACTION
				BEGIN TRY

				IF @ScreenEntityAlt_Key =0 OR @ScreenEntityAlt_Key =1
					BEGIN
					PRINT 'entity 0'
					
							PRINT 'END'		
					END
				
				ELSE IF @ScreenEntityAlt_Key =4
					BEGIN
						PRINT 'log @ScreenEntityAlt_Key =4'					
					END
				ELSE
					BEGIN
					  
					  print 'UPDATE  SysUserActivityLog_Attendence'
					 
						UPDATE  SysUserActivityLog_Attendence set  
								Remark =@Remark
								FROM SysUserActivityLog_Attendence
						Where BranchCode=@BranchCode 
							AND ReferenceID = @ReferenceID
							AND MenuID=@MenuID
							AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key
							

						--select * FROM SysUserActivityLog_Attendence
						--Where BranchCode=@BranchCode 
						--	AND ReferenceID = @ReferenceID
						--	--AND MenuID=@MenuID
						--	--AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key
					END
							
		COMMIT TRANSACTION		
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
				RETURN -1
		END CATCH
		
	END	
END
IF @AuthMode='N'
BEGIN
Declare @LogEntityKey SMALLINT
	IF @Flag =(1) 
							BEGIN
										
										SELECT @LogEntityKey = ISNULL(MAX(EntityKey),0) + 1 FROM SysUserActivityLog_Attendence          

										INSERT INTO SysUserActivityLog_Attendence    
										(	 
											 EntityKey
											,BranchCode
											,MenuID
											,ReferenceID
											,LogCreationStatus
											,LogALTERdBy
											,LogALTERdDt
											,LogStatus
											,Remark
											,ScreenEntityAlt_Key
										)                             				
										SELECT 				
											 @LogEntityKey
											,@BranchCode
											,@MenuID
											,@ReferenceID
											,''
											,@ALTERdBy
											,getdate()
											,''
											,@Remark
											,@ScreenEntityAlt_Key
							END
						IF @Flag =(2) 
							BEGIN
							        IF  NOT EXISTS(SELECT 1 FROM SysUserActivityLog_Attendence WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key)
									BEGIN
									
										SELECT @LogEntityKey = ISNULL(MAX(EntityKey),0) + 1 FROM SysUserActivityLog_Attendence      
									    print 'insert SysUserActivityLog_Attendence'
									     INSERT INTO SysUserActivityLog_Attendence    
										(	 
											 EntityKey
											,BranchCode
											,MenuID
											,ReferenceID
											,LogCreationStatus
											,LogALTERdBy
											,LogALTERdDt
											,LogStatus
											,Remark
											,ScreenEntityAlt_Key
											,EditCount
										)                             				
										SELECT 				
											 @LogEntityKey
											,@BranchCode
											,@MenuID
											,@ReferenceID
											,''
											,@ALTERdBy
											,getdate()
											,''
											,@Remark
											,@ScreenEntityAlt_Key
											,1
											print 'done'
									END

									ELSE
									BEGIN
									      	UPDATE SysUserActivityLog_Attendence
										SET		
												EditCount=ISNULL(EditCount,0)+1  
										WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID 
												AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key
									END
							        
								
							END
						IF @Flag =(3) 
							BEGIN
							         IF  NOT EXISTS(SELECT 1 FROM SysUserActivityLog_Attendence WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key)
									BEGIN
									SELECT @LogEntityKey = ISNULL(MAX(EntityKey),0) + 1 FROM SysUserActivityLog_Attendence    
									     INSERT INTO SysUserActivityLog_Attendence    
										(	 
											 EntityKey
											,BranchCode
											,MenuID
											,ReferenceID
											,LogCreationStatus
											,LogALTERdBy
											,LogALTERdDt
											,LogStatus
											,Remark
											,ScreenEntityAlt_Key
											,EditCount
										)                             				
										SELECT 				
											 @LogEntityKey
											,@BranchCode
											,@MenuID
											,@ReferenceID
											,''
											,@ALTERdBy
											,getdate()
											,''
											,@Remark
											,@ScreenEntityAlt_Key
											,1
									END
									ELSE
									BEGIN
									     	UPDATE SysUserActivityLog_Attendence
										SET		
												DeleteCount=ISNULL(DeleteCount,0)+1  
										WHERE BranchCode=@BranchCode AND ReferenceID=@ReferenceID 
												AND MenuID=@MenuID  AND ScreenEntityAlt_Key=@ScreenEntityAlt_Key
									END
								
							END
END 
				 




GO