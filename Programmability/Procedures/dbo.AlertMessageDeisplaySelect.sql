SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[AlertMessageDeisplaySelect]
    --@UserId int,
    @Timekey int ,
	@UserId varchar(50)
AS
  BEGIN
  
  SELECT TOP 20 MessageDesc FROM DimAlertMessage WHERE Active='Y' AND EffectiveFromTimeKey <=@Timekey AND EffectiveToTimeKey>=@Timekey

  
 -- SELECT QTR_Frozen FROM SysDataMatrix_New where  CurrentStatus='C'

  SELECT  UserLocation,UserLocationCode,UserRoleAlt_Key,'System Is Frozen Contact to HO' AS UserMasg	FROM DimUserInfo where UserLoginID=@UserId
										
--SELECT * FROM DimUserRole
  
  
   Declare @DeptGrpCode int, @MenuID varchar(Max),@UserRoleAlt_Key SMALLINT, @DeptName varchar(20)
	PRINT 'A' 
	SET @DeptGrpCode = (Select DeptGroupCode from DimUserInfo where UserLoginID = @UserId AND EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey)
	PRINT @DeptGrpCode
	PRINT 'B'
	SET @MenuID = (Select Menus from DimUserDeptGroup where DeptGroupId = @DeptGrpCode AND EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey >= @TimeKey)

	SET @DeptName = (Select DeptGroupName from DimUserDeptGroup where DeptGroupId = @DeptGrpCode AND EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey >= @TimeKey)
	PRINT 'C'
	SET @UserRoleAlt_Key = (Select UserRoleAlt_Key from DimUserInfo where UserLoginID = @UserId AND EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey)
	PRINT @UserRoleAlt_Key
	--SET @UserRoleAlt_Key = 3
	PRINT 'D'
	Select  EntityKey, MenuTitleId,DataSeq, ISNULL(MenuId,0) MenuId ,ISNULL(ParentId,0) ParentId,MenuCaption, ISNULL(CAST(ActionName AS VARCHAR(MAX)),ReportUrl)  
	ActionName,Viewpath,ngController,
	BusFld,EnableMakerChecker,NonAllowOperation,ISNULL(AccessLevel,'VIEWER')AccessLevel,'TblReport' AS TableName 
		FROM SysCRisMacMenu M 
			LEFT JOIN SysReportDirectory R
				ON M.MenuId = R.ReportMenuId
		WHERE  visible=1  --and   case when @DeptName='IT' THEN ParentId in(27,36,39,34,35,40,71,60) or MenuId=27 ELSE ParentId in(27,36,39,34,35,40,71) or MenuId=27 END 
		                 AND (CASE WHEN @DeptName = 'IT' AND ParentId in(27,36,39,34,35,40,71,60) AND MenuId NOT IN (1032,1033,1034,1035,1036,1021,1022,45) THEN 1 
						           WHEN @DeptName in('SDG','FRR') AND ParentId in(27,36,39,34,35,40,71,45) AND MenuId<>60 THEN 1 
	                               WHEN @DeptName <> 'IT' AND ParentId in(27,36,39,34,35,40,71) AND MenuId NOT IN (60,1032,1033,1034,1035,1036,1021,1022,45) THEN 1 
								   END )= 1 OR MenuId=27
		--and MenuId IN
		--(
		--	SELECT 	Split.a.value('.', 'VARCHAR(100)') AS MenuId  
		--	FROM  (
		--			SELECT CAST ('<M>' + REPLACE(@MenuID, ',', '</M><M>') + '</M>' AS XML) AS MenuId  
		--		  ) AS A CROSS APPLY MenuId.nodes ('/M') AS Split(a)   

		--   UNION 

		--	SELECT ParentId AS MenuId   FROM SysCRisMacMenu WHERE  MenuId IN (SELECT 	Split.a.value('.', 'VARCHAR(100)') AS MenuId  
		--	FROM  (
		--			SELECT CAST ('<M>' + REPLACE(@MenuID, ',', '</M><M>') + '</M>' AS XML) AS MenuId  
		--		  ) AS A CROSS APPLY MenuId.nodes ('/M') AS Split(a)   )
		--)
  END

  
 
GO