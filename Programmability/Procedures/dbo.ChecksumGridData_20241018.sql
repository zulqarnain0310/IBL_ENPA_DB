SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

Create PROCEDURE [dbo].[ChecksumGridData_20241018] 
	 @Timekey INT
	,@UserLoginId VARCHAR(100)
	,@Menuid INT
	,@OperationFlag int 

AS
BEGIN

SET DATEFORMAT DMY
	SET NOCOUNT ON;  
	    PRINT @Timekey   

IF (@MenuId=2030) 
	BEGIN
		IF (@OperationFlag=20) 
		BEGIN
			print'0'
			PRINT 'OPERATIONFLAG 20'

			IF OBJECT_ID('TEMPDB..#INT1')IS NOT NULL
			DROP TABLE #INT1
				
			SELECT  
				 EntityID,ProcessDate 
				,SourceName 
				,DataSet 
				,CRISMAC_CheckSum 
				,Source_CheckSum 
				,Start_BAU 
				,Processing_Type  
				,Reason
				,CASE WHEN  AuthorisationStatus='A' THEN 'Authorized'
					 WHEN  AuthorisationStatus='R' THEN 'Rejected'
					 WHEN  AuthorisationStatus='1A' THEN '1Authorized'
					 WHEN  AuthorisationStatus='NP' THEN 'Pending' ELSE NULL END AS AuthorisationStatus	 
				--,IsNull(ModifiedBy,CreatedBy)as CrModBy
				--,IsNull(DateModified,DateCreated)as CrModDate
				--,ISNULL(ApprovedBy,CreatedBy) as CrAppBy
				--,ISNULL(DateApproved,DateCreated) as CrAppDate
				--,ISNULL(ApprovedBy,ModifiedBy) as ModAppBy
				--,ISNULL(DateApproved,DateModified) as ModAppDate				
			INTO #INT1			
			FROM CheckSumData_FF_MOD
			WHERE   EffectiveFromTimeKey<=@Timekey
			    AND EffectiveToTimeKey>=@Timekey  
				AND AuthorisationStatus='1A' 
		              

            SELECT 
		         EntityID,ProcessDate 
				,SourceName 
				,DataSet 
				,CRISMAC_CheckSum 
				,Source_CheckSum 
				,Start_BAU 
				,Processing_Type  
				,Reason 
				,AuthorisationStatus 
				--,CrModBy
				--,CrModDate
				--,CrAppBy
				--,CrAppDate
				--,ModAppBy
				--,ModAppDate
            FROM #INT1
		    Where AuthorisationStatus Not In ('Authorized','Rejected','Pending') 
								 
	END
  

	
	ELSE
		IF (@OperationFlag =16)
			BEGIN
				print'1'
				PRINT 'OPERATIONFLAG 16'
			
					IF OBJECT_ID('TEMPDB..#INT3')IS NOT NULL
					DROP TABLE #INT3 
			SELECT  
				 EntityID,ProcessDate 
				,SourceName 
				,DataSet 
				,CRISMAC_CheckSum 
				,Source_CheckSum 
				,Start_BAU 
				,Processing_Type 
				,Reason
				,CASE WHEN  AuthorisationStatus='A' THEN 'Authorized'
					 WHEN  AuthorisationStatus='R' THEN 'Rejected'
					 WHEN  AuthorisationStatus='1A' THEN '1Authorized'
					 WHEN  AuthorisationStatus='NP' THEN 'Pending' ELSE NULL END AS AuthorisationStatus	 
				--,IsNull(ModifiedBy,CreatedBy)as CrModBy
				--,IsNull(DateModified,DateCreated)as CrModDate
				--,ISNULL(ApprovedBy,CreatedBy) as CrAppBy
				--,ISNULL(DateApproved,DateCreated) as CrAppDate
				--,ISNULL(ApprovedBy,ModifiedBy) as ModAppBy
				--,ISNULL(DateApproved,DateModified) as ModAppDate			
			 INTO #INT3				
			 FROM CheckSumData_FF_MOD
			 WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) 
			 AND AuthorisationStatus IN('NP','MP','DP','R','RM') 


			 SELECT  
						 EntityID,ProcessDate 
						,SourceName 
						,DataSet 
						,CRISMAC_CheckSum 
						,Source_CheckSum 
						,Start_BAU 
						,Processing_Type   
						,Reason
						,AuthorisationStatus 
						--,CrModBy
						--,CrModDate
						--,CrAppBy
						--,CrAppDate
						--,ModAppBy
						--,ModAppDate
					 FROM #INT3 
					 Where AuthorisationStatus Not In ('Authorized','Rejected','1Authorized')  
	END  

			ELSE
					IF(@OperationFlag=2)
					BEGIN
					
						 SELECT 
									 EntityID,ProcessDate 
									,SourceName 
									,DataSet 
									,CRISMAC_CheckSum 
									,Source_CheckSum 
									,Start_BAU 
									,Processing_Type 
									,Reason	 
									,AuthorisationStatus 
									--,CreatedBy 
									--,DateCreated 
									--,ModifiedBy 
									--,DateModified 
									--,ApprovedByFirstLevel 
									--,DateApprovedFirstLevel 
									--,ApprovedBy 
									--,DateApproved 
								 FROM CheckSumData_FF 
						 WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) 
						 --AND ISNULL(Start_BAU,'N')='N'  AND ISNULL(AuthorisationStatus,'N')='N'

				END 

	END
END
  
GO