SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROCEDURE  [dbo].[ChecksumDataInUp_20241023]
	@Timekey INT,
	@UserLoginID VARCHAR(100),
	@OperationFlag INT,
	@MenuId INT, 
	@Reason VARCHAR (500),
	@EntityID INT, 
	@Processing_Type  VARCHAR (20),
    @Result		INT=0 OUTPUT 
	--@Authlevel varchar(5)

AS
 --DECLARE @Timekey INT=26084,
--	@UserLoginID VARCHAR(100)='iblfm2',
--	@OperationFlag INT=1,
--	@MenuId INT=101, 
--  @Reason VARCHAR(100)='' 
--  @Result		INT=0   
 
  --SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus_MOC='C' and MOC_Initialised='Y')  

BEGIN TRY 
	 		 
IF (@MenuId=2030)
	BEGIN
	 IF (@OperationFlag=1) 
		BEGIN  
				print @Reason
				print @Timekey
				print @EntityID

				IF EXISTS (select 1 from Dbo.CheckSumData_FF_MOD where EntityID=@EntityID)
				BEGIN
							SET @Result=-6
							RETURN @Result 
				END
			ELSE
			BEGIN

		INSERT INTO Dbo.CheckSumData_FF_MOD
						( 
							EntityID
							,ProcessDate 
							,Timekey
							,SourceName
							,SourceAlt_Key
							,DataSet
							,CRISMAC_CheckSum
							,Source_CheckSum
							,Start_BAU
							,Processing_Type
							,Reason
							,AuthorisationStatus
							,EffectiveFromTimeKey
							,EffectiveToTimeKey
							,CreatedBy
							,DateCreated
							,ModifiedBy
							,DateModified
							,ApprovedByFirstLevel
							,DateApprovedFirstLevel
							,ApprovedBy
							,DateApproved  )
		 
		SELECT 
			EntityID
			,Convert(Varchar(10),ProcessDate,103) as ProcessDate
			,Timekey
			,SourceName
			,SourceAlt_Key
			,DataSet
			,CRISMAC_CheckSum
			,Source_CheckSum
			,'Y'
			,@Processing_Type
			,@Reason
			 ,'NP'AuthorisationStatus
			,EffectiveFromTimeKey
			,EffectiveToTimeKey
			,CreatedBy
			,DateCreated
			,@UserLoginID
			,Getdate()
			,ApprovedByFirstLevel
			,DateApprovedFirstLevel
			,ApprovedBy
			,DateApproved 
		FROM dbo.CheckSumData_FF 
		Where (EffectiveFromTimeKey<=@Timekey and EffectiveToTimeKey>=@Timekey) and EntityID=@EntityID
				AND Start_BAU='N'
 
			SET @Result=1

	END
END


IF (@OperationFlag=16)	---- FIRST LEVEL AUTHORIZE
	BEGIN	
		UPDATE dbo.CheckSumData_FF_mod 
		SET  AuthorisationStatus	='1A'
			,ApprovedByFirstLevel	= @UserLoginID
			,DateApprovedFirstLevel	= GETDATE()
		WHERE  (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) 
		AND  EntityID=@EntityID 
		
			SET @Result=1
	END

--------------------------------------------

	IF (@OperationFlag=20)----AUTHORIZE

	BEGIN
		
		UPDATE dbo.CheckSumData_FF_mod 
			SET AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE  (EffectiveFromTimeKey<=@Timekey and EffectiveToTimeKey>=@Timekey) 
					AND  EntityID=@EntityID
					AND (CreatedBy<>@UserLoginID OR ApprovedByFirstLevel<>@UserLoginID) 

				INSERT INTO Dbo.CheckSumData_FF 
						( ProcessDate
							,Timekey
							,SourceName
							,SourceAlt_Key
							,DataSet
							,CRISMAC_CheckSum
							,Source_CheckSum
							,Start_BAU
							,Processing_Type
							,Reason
							,AuthorisationStatus
							,EffectiveFromTimeKey
							,EffectiveToTimeKey
							,CreatedBy
							,DateCreated
							,ModifiedBy
							,DateModified
							,ApprovedByFirstLevel
							,DateApprovedFirstLevel
							,ApprovedBy
							,DateApproved 
							)
		 
		SELECT Convert(Varchar(10),ProcessDate,103) as ProcessDate
			,Timekey
			,SourceName
			,SourceAlt_Key
			,DataSet
			,CRISMAC_CheckSum
			,Source_CheckSum
			,Start_BAU
			,Processing_Type
			,@Reason
			,AuthorisationStatus
			,EffectiveFromTimeKey
			,EffectiveToTimeKey
			,CreatedBy
			,DateCreated
			,ModifiedBy
			,DateModified
			,ApprovedByFirstLevel
			,DateApprovedFirstLevel
			,ApprovedBy
			,DateApproved 
		FROM dbo.CheckSumData_FF_MOD 
			Where (EffectiveFromTimeKey<=@Timekey and EffectiveToTimeKey>=@Timekey)
			 AND EntityID=@EntityID
			 AND AuthorisationStatus='A'  

		Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
					from  Dbo.CheckSumData_FF  A
					WHERE EntityID=@EntityID 

					
			SET @Result=1
	END


	IF (@OperationFlag=17)	---- FIRST LEVEL REJECT
				BEGIN
					UPDATE Dbo.CheckSumData_FF_MOD
						SET AuthorisationStatus	='R'
							,ApprovedByFirstLevel	=@UserLoginID
							,DateApprovedFirstLevel	=GETDATE()
						WHERE (EffectiveFromTimeKey<=@Timekey and EffectiveToTimeKey>=@Timekey)
							AND EntityID=@EntityID
							AND AuthorisationStatus='NP'
							AND CreatedBy<> @UserLoginID 

							
					SET @Result=1
				END

	IF (@OperationFlag=21)----REJECT
				BEGIN
					UPDATE Dbo.CheckSumData_FF_MOD
						SET AuthorisationStatus	='R'
							,ApprovedByFirstLevel =@UserLoginID
							,DateApprovedFirstLevel	=GETDATE()
					WHERE (EffectiveFromTimeKey<=@Timekey and EffectiveToTimeKey>=@Timekey)
						AND EntityID=@EntityID
						AND AuthorisationStatus in('NP','1A')
						AND (CreatedBy<>@UserLoginID OR ApprovedByFirstLevel<>@UserLoginID)
			SET @Result=1
												
	 END			
END   
END TRY
		BEGIN CATCH
				SELECT ERROR_MESSAGE() 
				--ROLLBACK 
		END CATCH 
GO