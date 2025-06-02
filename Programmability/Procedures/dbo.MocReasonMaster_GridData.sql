SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MocReasonMaster_GridData] --26922,'shubham','16'
	 @Timekey INT,
	 @UserLoginId VARCHAR(100),
	 @OPERATIONFLAG VARCHAR(3)
AS


BEGIN
		SET NOCOUNT ON;

		SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus='C') 

    PRINT @Timekey 

		IF @OPERATIONFLAG=2
			BEGIN 
				SELECT * FROM 
					(	SELECT 
							MocReasonAlt_Key
							,MocReasonCategory
							,MocReasonName
							,CreatedBy AS [CrModBy]
							,ModifiedBy as [ModAppBy]
							,ApprovedByFirstLevel AS [FirstLevelApprovedBy]
							,DateCreated as [Operation Date]
							,ISNULL(AuthorisationStatus,'A') as AuthorisationStatus

						FROM DimMocReason A
						WHERE ISNULL(AuthorisationStatus,'A')in('A') AND A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
					
					UNION 

						SELECT 
							MocReasonAlt_Key
							,MocReasonCategory
							,MocReasonName
							,CreatedBy AS [CrModBy]
							,ModifiedBy as [ModAppBy]
							,ApprovedByFirstLevel AS [FirstLevelApprovedBy]
							,DateCreated as [Operation Date]
							,AuthorisationStatus						
							FROM DimMocReason_Mod A
						WHERE ISNULL(AuthorisationStatus,'A')IN ('NP','MP','1A','DP','1D') AND A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
					)A
				ORDER BY MocReasonAlt_Key
			END		
			

		ELSE IF @OPERATIONFLAG=16
				BEGIN
						SELECT 
							MocReasonAlt_Key
							,MocReasonCategory
							,MocReasonName
							,CreatedBy AS [CrModBy]
							,ModifiedBy as [ModAppBy]
							,ApprovedByFirstLevel AS [FirstLevelApprovedBy]
							,DateCreated as [Operation Date]
							,AuthorisationStatus
						FROM DimMocReason_Mod
						where AuthorisationStatus IN ('NP','MP','DP')
						AND EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				
			
				END 

		ELSE IF @OPERATIONFLAG=20
				BEGIN
						SELECT 
							MocReasonAlt_Key
							,MocReasonCategory
							,MocReasonName
							,CreatedBy AS [CrModBy]
							,ModifiedBy as [ModAppBy]
							,ApprovedByFirstLevel AS [FirstLevelApprovedBy]
							,DateCreated as [Operation Date]
							,AuthorisationStatus
						FROM DimMocReason_Mod A

				 where (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)
						AND AuthorisationStatus IN ('1A','1D')
				
				END 

	
END
GO