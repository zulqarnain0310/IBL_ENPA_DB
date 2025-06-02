SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[BranchMasterUploadCheckerView]

--declare
@MenuID INT=2010,  
@UserLoginId  VARCHAR(20)='FnaAdmin',  
@Timekey INT=49999,
@UploadID as Int
WITH RECOMPILE  
AS 


BEGIN

BEGIN TRY  

     
	 SET DATEFORMAT DMY

 
 --Select   @Timekey=Max(Timekey) from sysDayMatrix where Cast(date as Date)=cast(getdate() as Date)
  set  @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
 where A.CurrentStatus='C')

  PRINT @Timekey  

  IF (@MenuID=2010)

  BEGIN
		select count(BranchCode) BranchCode --,'TotalCount' as TableName
			   --,BranchName
			   --,Add_1
			   --,Add_2
			   --,Add_3
			   --,Place
			   --,PinCode
			   --,BranchOpenDt
			   --,BranchAreaCategory
			   --,BranchDistrictName
			   --,BranchStateName
			   --,Action
			   from 
		DimBranch_Mod
		Where UploadID=@UploadID
		and (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
		

	END
End Try
BEGIN CATCH
	

	INSERT INTO dbo.Error_Log
				SELECT ERROR_LINE() as ErrorLine,ERROR_MESSAGE()ErrorMessage,ERROR_NUMBER()ErrorNumber
				,ERROR_PROCEDURE()ErrorProcedure,ERROR_SEVERITY()ErrorSeverity,ERROR_STATE()ErrorState
				,GETDATE()


END CATCH

END
  
   
GO