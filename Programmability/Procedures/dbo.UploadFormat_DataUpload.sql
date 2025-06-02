SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create procedure [dbo].[UploadFormat_DataUpload]
 @MenuID INT=114,
@UserLoginId varchar(20)='bbogadmin',
@Timekey int=24958
as 


--DECLARE 
-- @MenuID INT=114,
--@UserLoginId varchar(20)='bbogadmin',
--@Timekey int=25292



begin

  select  ColumnName,SheetName,Department  from [DimUploadTempMaster] where MenuId=@MenuID order by EntityKey  --,'TblUploadMaster' AS TableName
 
  select  Distinct SheetName,'TblUploadSheet' AS TableName from  [DimUploadTempMaster] where MenuId=@MenuID 
 
 select  Distinct 'CatUpload' As TargetTable,'TargetTable' AS TableName from  [DimUploadTempMaster] where MenuId=@MenuID 


    --   Select @TimeKey=Max(Timekey) from SysProcessingCycle where ProcessType='Full' and ISNULL(Data_Extracted,'N')='Y'
	   --and ISNULL(DataStatus,'')=''

	   --IF ISNULL(@TimeKey,0)=0
	   --BEGIN
	   --   Select 'QtrFreezed' as TableName ,'Current Quarter is Freezed or Quarter Freezing is Pending for Authorization' as ErrorMessage
	   --END
	   --ELSE
	   --BEGIN 

	   --  Select 'QtrFreezed' as TableName ,'' as ErrorMessage

	   --END
	    --exec [SCH_9].[GetMonthFreezeForOperation]  @Timekey

end


GO