SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ChecksumGridData] 
	 @Timekey INT
	,@UserLoginId VARCHAR(100)
	,@Menuid INT
	,@OperationFlag int 

AS
BEGIN

SET DATEFORMAT DMY
	SET NOCOUNT ON;  
	    PRINT @Timekey   

		/**** Distinct Source name in search  *****/
	Select Distinct SourceName FROM CheckSumData_FF 
						 WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) 
						 
	/****  ProcessingType in search  *****/
	Select 'AUTO' as ProcessingType Union 
	Select 'MANUAL' as ProcessingType


IF (@MenuId=2030) 
	BEGIN
		IF (@OperationFlag=20) 
		BEGIN
			print'0'
			PRINT 'OPERATIONFLAG 20'

			IF OBJECT_ID('TEMPDB..#INT1')IS NOT NULL
			DROP TABLE #INT1
				
			SELECT  
				 EntityID,Convert(Varchar(10),ProcessDate,103) as ProcessDate 
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
				,IsNull(ModifiedBy,CreatedBy)as CrModBy
				,IsNull(DateModified,DateCreated)as CrModDate
				,IsNull(ApprovedByFirstLevel,ModifiedBy)as FirstLevelApprovedBy
				,IsNull(DateApprovedFirstLevel,DateModified)as FirstLevelApprovedDate
				,ISNULL(ApprovedBy,CreatedBy) as CrAppBy
				,ISNULL(DateApproved,DateCreated) as CrAppDate
				,ISNULL(ApprovedBy,ModifiedBy) as ModAppBy
				,ISNULL(DateApproved,DateModified) as ModAppDate				
			INTO #INT1			
			FROM CheckSumData_FF_MOD
			WHERE   EffectiveFromTimeKey<=@Timekey
			    AND EffectiveToTimeKey>=@Timekey  
				AND AuthorisationStatus='1A' 
		              

            SELECT 
		         EntityID,Convert(Varchar(10),ProcessDate,103) as ProcessDate 
				,SourceName 
				,DataSet 
				,CRISMAC_CheckSum 
				,Source_CheckSum 
				,Start_BAU 
				,Processing_Type  
				,Reason 
				,AuthorisationStatus 
				,CrModBy
				,CrModDate
				,FirstLevelApprovedBy
				,FirstLevelApprovedDate
				,CrAppBy
				,CrAppDate
				,ModAppBy
				,ModAppDate
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
				 EntityID,Convert(Varchar(10),ProcessDate,103) as ProcessDate 
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
					 WHEN  AuthorisationStatus='MP' THEN 'MODIFY PENDING' /*ADDED BY ZAIN ON 20250307*/
					 WHEN  AuthorisationStatus='NP' THEN 'Pending' ELSE NULL END AS AuthorisationStatus	 
				,IsNull(ModifiedBy,CreatedBy)as CrModBy
				,IsNull(DateModified,DateCreated)as CrModDate
				,IsNull(ApprovedByFirstLevel,ModifiedBy)as FirstLevelApprovedBy
				,IsNull(DateApprovedFirstLevel,DateModified)as FirstLevelApprovedDate
				,ISNULL(ApprovedBy,CreatedBy) as CrAppBy
				,ISNULL(DateApproved,DateCreated) as CrAppDate
				,ISNULL(ApprovedBy,ModifiedBy) as ModAppBy
				,ISNULL(DateApproved,DateModified) as ModAppDate				
			 INTO #INT3				
			 FROM CheckSumData_FF_MOD
			 WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) 
			 AND AuthorisationStatus IN('NP','MP','DP','R','RM') 


			 SELECT  
						 EntityID,Convert(Varchar(10),ProcessDate,103) as ProcessDate 
						,SourceName 
						,DataSet 
						,CRISMAC_CheckSum 
						,Source_CheckSum 
						,Start_BAU 
						,Processing_Type   
						,Reason
						,AuthorisationStatus 
						,CrModBy
						,CrModDate
						,FirstLevelApprovedBy
						,FirstLevelApprovedDate
						,CrAppBy
						,CrAppDate
						,ModAppBy
						,ModAppDate
					 FROM #INT3 
					 Where AuthorisationStatus Not In ('Authorized','Rejected','1Authorized')  
	END  

			ELSE
					IF(@OperationFlag=2)
					BEGIN
					
						 SELECT 
									 EntityID,Convert(Varchar(10),ProcessDate,103) as ProcessDate 
									,SourceName 
									,DataSet 
									,CRISMAC_CheckSum 
									,Source_CheckSum 
									,Start_BAU 
									,Processing_Type 
									,Reason	 
									,AuthorisationStatus  
				,IsNull(ModifiedBy,CreatedBy)as CrModBy
				,IsNull(DateModified,DateCreated)as CrModDate
				,IsNull(ApprovedByFirstLevel,ModifiedBy)as FirstLevelApprovedBy
				,IsNull(DateApprovedFirstLevel,DateModified)as FirstLevelApprovedDate
				,ISNULL(ApprovedBy,CreatedBy) as CrAppBy
				,ISNULL(DateApproved,DateCreated) as CrAppDate
				,ISNULL(ApprovedBy,ModifiedBy) as ModAppBy
				,ISNULL(DateApproved,DateModified) as ModAppDate				
								 FROM CheckSumData_FF 
						 WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) 

/*ADDED BY ZAIN ON 20250307*/
				--UNION 
				--		SELECT 
				--					 EntityID,Convert(Varchar(10),ProcessDate,103) as ProcessDate 
				--					,SourceName 
				--					,DataSet 
				--					,CRISMAC_CheckSum 
				--					,Source_CheckSum 
				--					,Start_BAU 
				--					,Processing_Type 
				--					,Reason	 
				--					,AuthorisationStatus  
				--,IsNull(ModifiedBy,CreatedBy)as CrModBy
				--,IsNull(DateModified,DateCreated)as CrModDate
				--,IsNull(ApprovedByFirstLevel,ModifiedBy)as FirstLevelApprovedBy
				--,IsNull(DateApprovedFirstLevel,DateModified)as FirstLevelApprovedDate
				--,ISNULL(ApprovedBy,CreatedBy) as CrAppBy
				--,ISNULL(DateApproved,DateCreated) as CrAppDate
				--,ISNULL(ApprovedBy,ModifiedBy) as ModAppBy
				--,ISNULL(DateApproved,DateModified) as ModAppDate				
				--				 FROM CheckSumData_FF_MOD 
				--		 WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) 
				--				AND AuthorisationStatus IN('NP','MP') 

/*ADDED BY ZAIN ON 20250307 END*/


						 --AND ISNULL(Start_BAU,'N')='N'  AND ISNULL(AuthorisationStatus,'N')='N'

				END 

	END
END
 


GO