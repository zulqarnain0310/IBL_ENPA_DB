SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


--exec SelectMasterTableVersion 'F','DimConstitution'
CREATE PROCEDURE [dbo].[SelectMasterTableForJson] 
  
   @TableName varchar(100)='ExpenseDetails'

AS
BEGIN

	
	SELECT TableVersionAlt_Key	,TableName	MasterTableName,VersionNo	,LastModifiedDate ,'VersionTbl' TableName
		FROM [dbo].[SysMasterTableVersion] WHERE TableName = @TableName

	exec [dbo].[ParameterisedCommonMasterData] @TableName
		
END


GO