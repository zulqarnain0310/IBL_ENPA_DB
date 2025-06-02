SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[AlertMessageInsertUpdate] 
	@AlertMessageAlt_key int,
  @MessageFor varchar(50),
  @Location varchar(50),
  @FromDate varchar(10),
  @ToDate varchar(10),
  @Active char(1),
  @LocationListAlt_key 	varchar(200)
  ,@MessageDesc	varchar(500)	
  ,@EffectiveFromTimeKey int                
  ,@EffectiveToTimeKey int               
  ,@DateCreatedModifiedApproved SMALLDATETIME                           
  ,@CreateModifyApprovedBy VARCHAR(20)
  ,@OperationFlag  INT     
  ,@AuthMode char(2) = null                                        
  ,@MenuID INT=NULL
  ,@TimeKey int	
  ,@D2Ktimestamp INT=0 OUTPUT   	
  ,@Result INT =0 OUTPUT
AS
BEGIN
DECLARE @AuthorisationStatus CHAR(2)=NULL			
			 ,@CreatedBy VARCHAR(20) =NULL
			 ,@DateCreated SMALLDATETIME=NULL
			 ,@Modifiedby VARCHAR(20) =NULL
			 ,@DateModified SMALLDATETIME=NULL
			 ,@ApprovedBy  VARCHAR(20)=NULL
			 ,@DateApproved  SMALLDATETIME=NULL
			 ,@ExEntityKey AS INT=0
			 ,@ErrorHandle int=0   
			 ,@AssetTagNo VARCHAR(60) = NULL


	DECLARE @UserLocation VARCHAR(5),@UserLocationCode VARCHAR(5),@UserLocationAlt_Key INT
	
	SELECT @UserLocation=UserLocation, @UserLocationCode=UserLocationCode FROM DimUserInfo 
	WHERE UserLoginID = @CreateModifyApprovedBy AND (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)

	--SELECT @UserLocationAlt_Key= UserLocationAlt_Key FROM DimUserLocation WHERE LocationShortName=@UserLocationCode


 print @MenuID
 IF @OperationFlag =1 
			
			 BEGIN
			 print 'two'
				SELECT @AlertMessageAlt_key=ISNULL(MAX(AlertMessageAlt_key),0)+1
				from (
						SELECT  MAX(AlertMessageAlt_key) as AlertMessageAlt_key FROM dbo.DimAlertMessage 
						
					 ) AlertMessageAlt_key					 
			   END	
			   
BEGIN TRY
BEGIN TRANSACTION		

IF @OperationFlag=1 

BEGIN

	INSERT INTO dbo.DimAlertMessage 
												(
														
													    
														  AlertMessageAlt_key
														 ,MessageFor
														 ,Location
														 ,FromDate
														 ,ToDate 
														 ,Active
														 ,MessageDesc	
														
													    ,EffectiveFromTimeKey
													     ,EffectiveToTimeKey
													     ,CreatedBy 
													     ,DateCreated													    
														 ,LocationListAlt_key	
														 ,UserLocationAlt_Key												  
												)

										SELECT													      
														 -- @EntityKey			
														  @AlertMessageAlt_key
														 ,@MessageFor								 													
														 ,@Location
													     ,CASE WHEN ISNULL(@FromDate,'')='' THEN NULL ELSE Convert(Date,@FromDate,103) END AS FromDate
														 ,CASE WHEN ISNULL(@ToDate,'')='' THEN NULL ELSE Convert(Date,@ToDate,103) END AS ToDate
														 --,Convert(Date,@ToDate 	,103) AS  ToDate
														 ,@Active
														 ,@MessageDesc		
																					
													    
													     ,@EffectiveFromTimeKey
													    ,@EffectiveToTimeKey
													    ,@CreateModifyApprovedBy 
													    ,@DateCreatedModifiedApproved													  
													    ,@LocationListAlt_key
													  ,  CASE WHEN @UserLocationCode  ='HO' THEN 1 ELSE @UserLocationCode END  

END
ELSE
IF @OperationFlag=2
BEGIN

												   UPDATE dbo.DimAlertMessage
												   set 											  
												
												    MessageFor			=	@MessageFor
												   ,Location			=	@Location
												   ,FromDate			=	 Convert(Date,@FromDate,103)
												   ,ToDate				=	 Convert(Date,@ToDate,103) 
												   ,Active				=	@Active
												   ,MessageDesc			=	@MessageDesc	  												
												   ,ModifyBy			=	@CreateModifyApprovedBy
												   ,DateModified		=	@DateCreatedModifiedApproved	
												   ,LocationListAlt_key	=	@LocationListAlt_key											  
												   ,UserLocationAlt_Key	=	CASE WHEN @UserLocationCode  ='HO' THEN 1 ELSE @UserLocationCode END --@UserLocationCode
												WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey) 
													
													AND AlertMessageAlt_key =@AlertMessageAlt_key
																								
													
END	
ELSE
IF @OperationFlag =3 
		BEGIN
		
				-- DELETE WITHOUT MAKER CHECKER
				BEGIN							
						SET @Modifiedby   = @CreateModifyApprovedBy 
						SET @DateModified = GETDATE() 

						UPDATE dbo.DimAlertMessage  SET
									ModifyBy =@Modifiedby 
									,DateModified =@DateModified 
									,EffectiveToTimeKey =@EffectiveFromTimeKey-1
								WHERE (EffectiveFromTimeKey=EffectiveFromTimeKey 
								       AND EffectiveToTimeKey>=@TimeKey)
								        AND AlertMessageAlt_key =@AlertMessageAlt_key								
													
										
				END

		END

       COMMIT TRANSACTION	
		print @D2Ktimestamp
		print 'd2k'

		SELECT @D2Ktimestamp=CAST(D2Ktimestamp AS INT)
				from (
						SELECT  D2Ktimestamp FROM DimAlertMessage  WHERE  EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey and AlertMessageAlt_key =@AlertMessageAlt_key 
					
		
					 )timestamp1

			select @D2Ktimestamp=ISNULL(@D2Ktimestamp,1)
		 
		--IF @OperationFlag =3
		--	BEGIN
				
		--		SET @Result =0
		--		if(@AuthMode='N')
		--		(
				
		--		 select @D2Ktimestamp=(SELECT  D2Ktimestamp FROM DimAlertMessage  WHERE  EffectiveFromTimeKey<=@TimeKey and AlertMessageAlt_key =@AlertMessageAlt_key 
				
		--		)
		--		RETURN @D2Ktimestamp
				
				
		--		RETURN @Result
		--	END
			
		--ELSE


			BEGIN
			PRINT 8		
			print @AlertMessageAlt_key
				SET @Result =@AlertMessageAlt_key
				PRINT @Result
				RETURN @Result		
				return @D2Ktimestamp		
			END

END TRY
BEGIN CATCH
select ERROR_MESSAGE()
	ROLLBACK TRAN
	SET @Result =-1				
RETURN @Result
	

END CATCH
END
  
GO