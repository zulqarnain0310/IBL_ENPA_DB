SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE proc [dbo].[BranchOfficeDtl_Select]
	(
	
		@BranchCode VARCHAR(10)
		,@TimeKey INT 
		,@Mode INT
		,@UserId Varchar(50)
	)

as 
begin

IF @Mode <>16
	BEGIN
	select
	BranchCode			
	,BranchName		
	,BranchOpenDt		
	,BranchRegion
	,BranchRegionAlt_Key
	,BranchZone
	,BranchZoneAlt_Key
	,RBI_Part_1 
		
	,RBI_Part_2 
	,BranchAreaCategoryAlt_Key as AreaAlt_Key
	,BranchAreaCategory BranchAreaCat		
	,Add_1 				
	,Add_2 			
	,Add_3 
	,CityAlt_Key
	,Place				
	,cast(Pincode  as int) PinCode	
	--,Pincode PinCode	
	,BranchDistrictName District
	,BranchDistrictAlt_Key as DistrictAlt_Key	 	
	,BranchStateName State				
	,BranchStateAlt_Key as StateAlt_Key
	,'Y' IsMainTable
	--,AuthorisationStatus
	,ISNULL(ModifyBy,CreatedBy)CreatedModifiedBy
	,ISNULL(ModifyBy,CreatedBy) AS OperationBy
	--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
	,ISNULL(DateModified,DateCreated) AS OperationDate
	,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
			WHEN  AuthorisationStatus='R' THEN 'Rejected'
			WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
	 ELSE NULL END AS AuthorisationStatus
	 from DimBranch
		where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
		and BranchCode=@BranchCode
		and ISNULL(AuthorisationStatus,'A')='A'

	UNION 
	select
	BranchCode			
	,BranchName		
	,BranchOpenDt		
	,BranchRegion
	,BranchRegionAlt_Key
	,BranchZone
	,BranchZoneAlt_Key
	,RBI_Part_1 
		
	,RBI_Part_2 
	,BranchAreaCategoryAlt_Key as AreaAlt_Key
	,BranchAreaCategory BranchAreaCat	
	,Add_1 				
	,Add_2 			
	,Add_3 
	,CityAlt_Key
	,Place	
	--,Pincode PinCode			
	,cast(Pincode  as int)  PinCode		
	,BranchDistrictName District
	,BranchDistrictAlt_Key as DistrictAlt_Key	 	
	,BranchStateName State				
	,BranchStateAlt_Key as StateAlt_Key
	,'N' IsMainTable
	--,AuthorisationStatus
	,ISNULL(ModifyBy,CreatedBy)CreatedModifiedBy
	,ISNULL(ModifyBy,CreatedBy) AS OperationBy
	--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
	,ISNULL(DateModified,DateCreated) AS OperationDate
	,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
			WHEN  AuthorisationStatus='R' THEN 'Rejected'
			WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
	 ELSE NULL END AS AuthorisationStatus
	 from DimBranch_MOD
		where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
		and BranchCode=@BranchCode
		AND AuthorisationStatus IN('NP','MP','DP','RM')
		AND Branch_Key IN(SELECT MAX(Branch_Key)Branch_Key FROM DimBranch_MOD 
								where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
								and BranchCode=@BranchCode
								AND AuthorisationStatus IN('NP','MP','DP','RM')
		)

	END 

IF @Mode=16
	BEGIN
		select
	BranchCode			
	,BranchName		
	,BranchOpenDt		
	,BranchRegion
	,BranchRegionAlt_Key
	,BranchZone
	,BranchZoneAlt_Key
	,RBI_Part_1 
		
	,RBI_Part_2 
	,BranchAreaCategoryAlt_Key as AreaAlt_Key
	,BranchAreaCategory BranchAreaCat	
	,Add_1 				
	,Add_2 			
	,Add_3 
	,CityAlt_Key
	,Place				
	,cast(Pincode  as int)  PinCode
	--,Pincode PinCode		
	,BranchDistrictName District
	,BranchDistrictAlt_Key as DistrictAlt_Key	 	
	,BranchStateName State				
	,BranchStateAlt_Key as StateAlt_Key
	,'N' IsMainTable
	--,AuthorisationStatus
	,ISNULL(ModifyBy,CreatedBy)CreatedModifiedBy
	,ISNULL(ModifyBy,CreatedBy) AS OperationBy
	--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
	,ISNULL(DateModified,DateCreated) AS OperationDate
	,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
			WHEN  AuthorisationStatus='R' THEN 'Rejected'
			WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
	 ELSE NULL END AS AuthorisationStatus
	 from DimBranch_MOD
		where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
		and BranchCode=@BranchCode
		AND AuthorisationStatus IN('NP','MP','DP','RM')
		AND Branch_Key IN(SELECT MAX(Branch_Key)Branch_Key FROM DimBranch_MOD 
								where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
								and BranchCode=@BranchCode
								AND AuthorisationStatus IN('NP','MP','DP','RM')
		)

	END 



end 

GO