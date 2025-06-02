SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROCEDURE [dbo].[UserParametersInsertUpdate]
	(
	 @CreatedBy AS varchar(20)
	,@CreatedDate as SMALLDATETIME
	,@NONUSE AS INT
	,@PWDCHNG AS INT
	,@PWDLEN AS INT
	,@PWDNUM AS INT
	,@PWDREUSE AS INT
	,@UNLOGON AS INT
	,@USERIDALP AS INT
	,@USERIDLEN AS INT
	,@USERIDLENMAX AS INT
	,@PWDLENMAX AS INT
	,@PWDALPHAMIN AS INT
	,@USERSHOMAX AS INT
	,@USERSROMAX AS INT
	,@USERSBOMAX AS INT
	,@Remark varchar(100)
	,@EffectiveFromTimeKey AS INT
	,@EffectiveToTimeKey AS INT
	,@Flag AS Varchar(10)
	,@AuthMode char(2) = null     
	,@TimeKey AS INT 
	,@Result as int =-1 output -- NITIN : 21 DEC 2010
	)
AS
BEGIN 
DECLARE @AuthorisationStatus CHAR(2)=NULL			
			 ,@CreateModifyApprovedBy VARCHAR(20) =NULL
			 ,@DateCreatedModifiedApproved SMALLDATETIME=NULL
			 ,@Modifiedby VARCHAR(20) =NULL
			 ,@DateModified SMALLDATETIME=NULL
			 ,@ApprovedBy  VARCHAR(20)=NULL
			 ,@DateApproved  SMALLDATETIME=NULL
			 ,@ExEntityKey AS INT=0
			 ,@ErrorHandle int=0   
Declare @CurrentLoginDate Date--- added by shailesh naik on 10/06/2014
SET @AuthMode=CASE WHEN @AuthMode in('S','H','A') THEN 'Y' else 'N' END
Select @CurrentLoginDate= CurrentLoginDate from DimUserInfo where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey) AND UserLoginID=@CreatedBy

		--IF DATEDIFF(DAY,@CurrentLoginDate,GetDate()) <> 0
		--BEGIN
		--   return -12 --- User Login Date is prior. Data will not be Saved. Please Close the Application.
		--END

 IF @Flag=2 AND @AuthMode ='Y' 
 BEGIN
 PRINT 'A'

					IF OBJECT_ID('Tempdb..##temp1') IS NOT NULL
						DROP TABLE ##temp1
						create table ##temp1 

						(
							NONUSE	 		 INT	
							,PWDCHNG			 INT  
							,PWDLEN			 INT	
							,PWDNUM			  INT	
							,PWDREUSE		 INT	
							,UNLOGON			 INT	
							,USERIDALP		 INT	
							,USERIDLEN		 INT	
							,USERIDLENMAX	 INT  
							,PWDLENMAX		 INT	
							,PWDALPHAMIN		 INT	
							,USERSHOMAX		 INT	
							,USERSROMAX		 INT	
							,USERSBOMAX		 INT	
						
						
						)
			

INSERT	
INTO 
##temp1
(
NONUSE	 	
,PWDCHNG		
,PWDLEN		
,PWDNUM		
,PWDREUSE	
,UNLOGON		
,USERIDALP	
,USERIDLEN	
,USERIDLENMAX
,PWDLENMAX	
,PWDALPHAMIN	
,USERSHOMAX	
,USERSROMAX	
,USERSBOMAX	

)

(	select
 @NONUSE	 	
,@PWDCHNG		
,@PWDLEN		
,@PWDNUM		
,@PWDREUSE		
,@UNLOGON		
,@USERIDALP		
,@USERIDLEN		
,@USERIDLENMAX	
,@PWDLENMAX		
,@PWDALPHAMIN		
,@USERSHOMAX	
,@USERSROMAX	
,@USERSBOMAX	
) 

 IF OBJECT_ID('Tempdb..##temp2') IS NOT NULL
						DROP TABLE ##temp2
select *	INTO ##temp2
 FROM (
SELECT * FROM (
  SELECT * FROM ##temp1) T
  UNPIVOT ( ParameterValue FOR ParameterName IN (NONUSE,PWDCHNG,PWDLEN,PWDNUM,PWDREUSE,UNLOGON,USERIDALP,USERIDLEN,USERIDLENMAX,PWDLENMAX,PWDALPHAMIN,
  USERSHOMAX,USERSROMAX,USERSBOMAX))P)A

  --select * from ##temp2
  PRINT 'ABC'
IF EXISTS(SELECT 1 FROM dbo.DimUserParameters_mod  WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey))
BEGIN
				UPDATE dbo.DimUserParameters_mod
									SET AuthorisationStatus='FM'
									,ModifyBy=@CreatedBy
									,DateModified=@CreatedDate
								WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
										  									  																								
										  AND AuthorisationStatus IN('NP','MP','RM')

END

INSERT INTO DimUserParameters_mod 
   (
    
	ShortNameEnum,
	ParameterType,
	ParameterValue,
	SeqNo,
	MinValue,
	MaxValue,
	AuthorisationStatus,
	DateCreated,
	CreatedBy,
	EffectiveFromTimeKey,
	EffectiveToTimeKey,
	ModifyBy,
	DateModified,
	Remark


	 )
	
        SELECT 
       
 		ShortNameEnum,
		ParameterType,
		B.ParameterValue,
		SeqNo,
		MinValue,
		MaxValue,
		'MP',
		DateCreated,
		CreatedBy,
		@EffectiveFromTimeKey,
		@EffectiveToTimeKey	,
		@CreatedBy,
		GETDATE(),
		@Remark

		from DimUserParameters A

		LEFT JOIN ##temp2 B
		ON B.ParameterName=A.ShortNameEnum
		where   A.EffectiveFromTimeKey<= @TimeKey AND A.EffectiveToTimeKey>= @TimeKey


UPDATE DimUserParameters
SET AuthorisationStatus='MP'
where EffectiveFromTimeKey<= @TimeKey AND EffectiveToTimeKey>= @TimeKey


	 END

ELSE IF @Flag=16 AND @AuthMode ='Y' 

BEGIN

	UPDATE  A

	SET	 
		
		  A.ParameterValue	=B.ParameterValue
		
		 ,ModifyBy=@CreatedBy
		 ,DateModified=@CreatedDate
		 ,ApprovedBy=CASE WHEN @AuthMode ='Y' THEN @CreatedBy ELSE NULL END
		 ,DateApproved= CASE WHEN @AuthMode ='Y' THEN @CreatedDate ELSE NULL END
		 ,AuthorisationStatus= CASE WHEN @AuthMode ='Y' THEN  'A' ELSE NULL END 	
		   from DimUserParameters A
		   INNER JOIN DimUserParameters_mod B
		   ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
		   AND B.AuthorisationStatus in('NP','MP','RM') AND A.ShortNameEnum=B.ShortNameEnum
		   where A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
		   AND A.AuthorisationStatus='MP'
			


	UPDATE DimUserParameters_mod 
		SET AuthorisationStatus='A'
		,ApprovedBy=@CreatedBy
		,DateApproved=@CreatedDate
	WHERE  (EffectiveFromTimekey<=@TimeKey AND EffectiveToTimekey>=@TimeKey) 
	 AND AuthorisationStatus in('NP','MP','RM')


 END

ELSE IF @Flag=17 AND @AuthMode ='Y' 
		BEGIN
				SET @ApprovedBy	   = @CreatedBy 
				SET @DateApproved  = GETDATE()

				UPDATE dbo.DimUserParameters_mod
					SET AuthorisationStatus='R'
					,ApprovedBy	 =@ApprovedBy
					,DateApproved=@DateApproved
					,EffectiveToTimeKey =@EffectiveFromTimeKey-1
					,Remark=@Remark
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
						 					 												 				
						  AND AuthorisationStatus in('NP','MP','DP','RM')	
						

						

				IF EXISTS(SELECT 1 FROM dbo.DimUserParameters  WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@Timekey)  )
				BEGIN
					UPDATE DimUserParameters 
						SET AuthorisationStatus='A'
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							 																	    						
							AND AuthorisationStatus IN('MP','DP','RM') 

							
				END
				
				
		END

		ELSE IF @Flag=18 AND @AuthMode ='Y' 
		BEGIN
				SET @ApprovedBy	   = @CreateModifyApprovedBy 
				SET @DateApproved  = GETDATE()

				UPDATE DimUserParameters_mod
					SET AuthorisationStatus='RM'
					,Remark=@Remark	
				WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND AuthorisationStatus in('NP','MP','DP','RM') 
														
		END

IF @AuthMode='N'
BEGIN
print 'N mode'
IF @EffectiveFromTimeKey = (SELECT EffectiveFromTimeKey from DimUserParameters               
	where ShortNameEnum='NONUSE' and (EffectiveToTimeKey >= @EffectiveFromTimeKey AND EffectiveFromTimeKey <= @EffectiveFromTimeKey) ) 
	
					  BEGIN
					  print 'same'
					  UPDATE DimUserParameters
		SET ParameterValue=@NONUSE, ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='NONUSE'
	
	
	 UPDATE DimUserParameters 
			SET ParameterValue=@PWDCHNG, ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='PWDCHNG'
	
	
	UPDATE DimUserParameters 
			SET ParameterValue=@PWDLEN , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='PWDLEN'
	

	UPDATE DimUserParameters
			SET ParameterValue=@PWDNUM , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='PWDNUM'


	UPDATE DimUserParameters 
		SET ParameterValue=@PWDREUSE , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='PWDREUSE'


	UPDATE DimUserParameters 
		SET ParameterValue=@UNLOGON , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='UNLOGON'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERIDALP  , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='USERIDALP'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERIDLEN  , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey )
	AND ShortNameEnum='USERIDLEN'


	UPDATE DimUserParameters 
	SET ParameterValue=@USERIDLENMAX  , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='USERIDLENMAX'


	UPDATE DimUserParameters 
		SET ParameterValue=@PWDLENMAX  , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='PWDLENMAX'


	UPDATE DimUserParameters 
		SET ParameterValue=@PWDALPHAMIN  , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='PWDALPHAMIN'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERSHOMAX  , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='USERSHOMAX'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERSROMAX  , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='USERSROMAX'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERSBOMAX  , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='USERSBOMAX'



	Update DimMaxLoginAllow 
		SET MaxUserLogin=@USERSHOMAX , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE UserLocation='HO'	AND MaxUserCustom='N'


	Update DimMaxLoginAllow 
		SET MaxUserLogin=@USERSROMAX , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE UserLocation='RO'	AND MaxUserCustom='N'


	Update DimMaxLoginAllow 
		SET MaxUserLogin=@USERSBOMAX , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE UserLocation='BO'	AND MaxUserCustom='N'		


	UPDATE DimUserParameters 
		SET EffectiveToTimeKey=@EffectiveFromTimeKey , ModifyBy=@CreatedBy,DateModified=GETDATE()
	WHERE  (DimUserParameters.EffectiveFromTimekey>@TimeKey AND DimUserParameters.EffectiveToTimekey<@TimeKey) 
	AND ShortNameEnum='NONUSE'

	--UPDATE DimUserParameters 
	--	SET 
	--WHERE  (DimUserParameters.EffectiveFromTimekey>@TimeKey AND DimUserParameters.EffectiveToTimekey<@TimeKey) 


		  END
					  
ELSE
	BEGIN
	print 'diffrent'


	UPDATE DimUserParameters           
		   SET EffectiveToTimeKey = @EffectiveFromTimeKey - 1, 
			   ModifyBy=@CreatedBy,
			   DateModified= @CreatedDate    
			 
		   where EffectiveToTimeKey =@EffectiveToTimeKey
	
	PRINT '1'
	 INSERT INTO DimUserParameters 
   (
    
	ShortNameEnum,
	ParameterType,
	ParameterValue,
	SeqNo,
	MinValue,
	MaxValue,
	DateCreated,
	CreatedBy,
	EffectiveFromTimeKey,
	EffectiveToTimeKey,
	ModifyBy,
	DateModified


	 )
	
        SELECT 
       
		ShortNameEnum,
		ParameterType,
		ParameterValue,
		SeqNo,
		MinValue,
		MaxValue,
		DateCreated,
		CreatedBy,
		@EffectiveFromTimeKey,
		@EffectiveToTimeKey	,
		@CreatedBy,
		GETDATE()
	
				
	FROM DimUserParameters where (DimUserParameters.EffectiveToTimeKey = @EffectiveFromTimeKey - 1)

	UPDATE DimUserParameters
		SET ParameterValue=@NONUSE
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='NONUSE'
	
	
	 UPDATE DimUserParameters 
			SET ParameterValue=@PWDCHNG 
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='PWDCHNG'
	
	
	UPDATE DimUserParameters 
			SET ParameterValue=@PWDLEN 
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='PWDLEN'
	

	UPDATE DimUserParameters
			SET ParameterValue=@PWDNUM
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='PWDNUM'


	UPDATE DimUserParameters 
		SET ParameterValue=@PWDREUSE 
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='PWDREUSE'


	UPDATE DimUserParameters 
		SET ParameterValue=@UNLOGON 
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='UNLOGON'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERIDALP  
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='USERIDALP'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERIDLEN  
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey )
	AND ShortNameEnum='USERIDLEN'


	UPDATE DimUserParameters 
	SET ParameterValue=@USERIDLENMAX  
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey)
	AND ShortNameEnum='USERIDLENMAX'


	UPDATE DimUserParameters 
		SET ParameterValue=@PWDLENMAX  
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='PWDLENMAX'


	UPDATE DimUserParameters 
		SET ParameterValue=@PWDALPHAMIN  
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='PWDALPHAMIN'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERSHOMAX  
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='USERSHOMAX'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERSROMAX  
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='USERSROMAX'


	UPDATE DimUserParameters 
		SET ParameterValue=@USERSBOMAX  
	WHERE  (DimUserParameters.EffectiveFromTimekey<=@TimeKey AND DimUserParameters.EffectiveToTimekey>=@TimeKey) 
	AND ShortNameEnum='USERSBOMAX'



	Update DimMaxLoginAllow 
		SET MaxUserLogin=@USERSHOMAX 
	WHERE UserLocation='HO'	AND MaxUserCustom='N'


	Update DimMaxLoginAllow 
		SET MaxUserLogin=@USERSROMAX 
	WHERE UserLocation='RO'	AND MaxUserCustom='N'


	Update DimMaxLoginAllow 
		SET MaxUserLogin=@USERSBOMAX 
	WHERE UserLocation='BO'	AND MaxUserCustom='N'		


	UPDATE DimUserParameters 
		SET EffectiveToTimeKey=@EffectiveFromTimeKey 
	WHERE  (DimUserParameters.EffectiveFromTimekey>@TimeKey AND DimUserParameters.EffectiveToTimekey<@TimeKey) 
	AND ShortNameEnum='NONUSE'
END
END


SET @Result=	1




END






  
			  
			  
			  
			               
		    




GO