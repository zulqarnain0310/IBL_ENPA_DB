SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROCEDURE [dbo].[BranchMasterUploadDownloadData]
	@Timekey INT
	,@UserLoginId VARCHAR(100)
	,@ExcelUploadId INT
	,@UploadType VARCHAR(50)
	--,@Page SMALLINT =1     
 --   ,@perPage INT = 30000   
AS


BEGIN
		SET NOCOUNT ON;

		set @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
 where A.CurrentStatus='C')
		  		  PRINT @Timekey  


IF (@UploadType='Branch_Master_Upload')

BEGIN
		PRINT 'REV'
		--SELECT * FROM(
		SELECT 'Details' as TableName
				,BranchCode
			   ,BranchName
			   ,Add_1
			   ,Add_2
			   ,Add_3
			   ,Place
			   ,A.PinCode
			   ,BranchOpenDt
			   --,BranchAreaCategoryAlt_Key
			   ,BranchAreaCategory
			   --,BranchDistrictAlt_Key
			   ,BranchDistrictName
			  -- ,BranchStateAlt_Key
			   ,BranchStateName
			   ,Action
			   ,UploadId	
				
			FROM DimBranch_Mod  A
			WHERE A.UploadID=@ExcelUploadId
			AND (A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey)


		SELECT 'Summary' as TableName,
		count(*) as BranchCodecount
		
		FROM DimBranch_Mod  A
			WHERE A.UploadID=@ExcelUploadId
		AND EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey

		--)A
		--WHERE ROW_NUM BETWEEN  @PageFrom AND @PageTo
		--ORDER BY ROW_NUM  

END



END
GO