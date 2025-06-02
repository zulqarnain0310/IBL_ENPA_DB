SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROCEDURE [dbo].[UserSearchSelect]
	@UserLoginID		Varchar(50)
	,@UserName  Varchar(50)
	
	,@ExtensionNo Varchar(11)
	,@ApplicableSOLID varchar(11)
	,@UserDepartment	varchar(100)
	,@UserRole  varchar(100)
	,@Email_ID varchar(200)
	,@MobileNo varchar(10)
	,@IsChecker Char(1)
	--,@IsChecker2 Varchar(1)
	,@IsActive  Char(1)
	,@TimeKey	INT
,@ApplicableBacid VARCHAR(MAX)=''
,@LoginID  Varchar(50)
AS
BEGIN

--DECLAre

--	@UserLoginID		Varchar(50)='111kk'
--	,@UserName  Varchar(50)='ak'
	
--	,@ExtensionNo Varchar(11)
--	,@ApplicableSOLID varchar(11)=''
--	,@UserDepartment	varchar(100)='14'
--	,@UserRole  varchar(100)=2
--	,@Email_ID varchar(200)
--	,@MobileNo varchar(10)
--	,@IsChecker Char(1)
--	,@IsActive  Char(1)
--	,@TimeKey	INT=25202
--	,@ApplicableBacid VARCHAR(MAX)=''

Select @TimeKey= Timekey from SysDayMatrix where Cast([Date] as date)=Cast(Getdate() as date)


--Select @TimeKey= MAX(Timekey) from SysProcessingCycle 
--WHERE Extracted='Y' and ProcessType='Full'

PRINT @TimeKey

------------MULTI SELECT FOR USER DEPARTMENT 
IF OBJECT_ID ('TEMPDB..#Dept_ALTKEY') IS NOT NULL
	DROP TABLE #Dept_ALTKEY

CREATE TABLE #Dept_ALTKEY(Dept_ALTKEY VARCHAR(MAX))
print @TimeKey
IF ISNULL(@UserDepartment,'')<>''
BEGIN
	print'Dp'
	INSERT INTO #Dept_ALTKEY
	SELECT Items AS Dept_ALTKEY
	FROM Split(@UserDepartment,',')

	----SELECT * FROM #Dept_codeS
	
END
ELSE
BEGIN

	INSERT INTO #Dept_ALTKEY
	SELECT DISTINCT deptgroupid AS Dept_ALTKEY
	--FROM dimdepartment A
		FROM Dimuserdeptgroup A
	left JOIN DimUserInfo B ON A.deptgroupid=B.DepartmentId
	AND b.EffectiveFromTimeKey<=@TimeKey AND b.EffectiveToTimeKey>=@TimeKey
							
	WHERE B.UserLoginID =@UserLoginID
	AND A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
	
END

		--DECLARE @DEPTALTKEY INT

		--SET @DEPTALTKEY =(SELECT DISTINCT B.DepartmentAlt_Key FROM DimUserInfo A
		--					INNER JOIN dimdepartment B ON A.DepartmentId=B.DepartmentAlt_Key
		--												AND A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
		--					WHERE B.DepartmentCode IN (SELECT Dept_code FROM #Dept_codeS))

							

----IF OBJECT_ID('tempdb..#tempItem') IS NOT NULL
----    DROP TABLE #tempItem

----	    SELECT * INTO #tempItem FROM Split(@ApplicableSOLID ,',')

		----SELECT * FROM #tempItem

-----------APPLICABLE BACIDS

IF OBJECT_ID ('TEMPDB..#BACID') IS NOT NULL
	DROP TABLE #BACID

 CREATE TABLE #BACID(BACID VARCHAR(MAX))  
    PRINT 'TABLE CREATED'  

IF ISNULL(@ApplicableBacid,'')<>''
BEGIN
print 1

	INSERT INTO #BACID
	SELECT Items AS BACID
	
	FROM Split(@ApplicableBacid,',')

	----SELECT * FROM #BACID
	
END
ELSE
BEGIN


	print 2
	INSERT  INTO  #BACID
	SELECT BACID
	FROM DimDepttoBacid
	WHERE DepartmentAlt_Key=10

	
END

-------------TO DISPLAY LIST OF BACIDS ASSIGNED

----	SELECT A.BACID AS CODE,A.BACID AS DESCRIPTION , 'Bacid_list_Department' AS TABLENAME
----	FROM DimDepttoBacid A
----	INNER JOIN dimdepartment B ON A.DepartmentAlt_Key=B.DepartmentAlt_Key
----								AND B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey
----	WHERE B.DepartmentCode =ISNULL(@UserDepartment,10)
	

	----IF OBJECT_ID('tempdb..#tempSelectedItem') IS NOT NULL
 ----   DROP TABLE #tempSelectedItem
	---- Select * into #tempSelectedItem
	---- from
	---- (
	---- SELECT DISTINCT C.BranchCode,@UserLoginID as UserLoginId
 ----   FROM OAOLEntryDetaiL A
	----INNER JOIN FACTOFFICE B ON A.OAOLAlt_Key =B.OAAlt_Key	
	----						AND A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
	----						AND B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey
	----INNER JOIN DimBranch C ON A.BranchCode =C.BranchCode
	----						AND A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey
	----						AND C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey 
 ----    --WHERE 
	---- )ANC
	  --Declare @ApplicableSolidForBBOG varchar(max)

	  --Select @ApplicableSolidForBBOG=ApplicableBACID

	  --from DimDepartment where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey)
	  --AND DepartmentCode='BBOG'

	  ------SELECT * FROM #tempSelectedItem
	  --SELECT * FROM #BACID
	  --SELECT * FROM #Dept_codeS

   Select 
   DISTINCT 
    U.UserLoginID
	,U.UserName
   ,U.UserRoleAlt_Key as UserRole
   ,R.RoleDescription 
   ,U.DepartmentId
   ,U.DeptGroupCode
   ,D.DeptGroupCode AS UserDepartment
   ,Case---- when D.DepartmentCode='BBOG' THEN @ApplicableSolidForBBOG  
		WHEN D.DeptGroupCode='FNA' THEN 'ALL SOL ID' ELSE  U.ApplicableSolIds END AS ApplicableSOLID
   ----,'' AS ApplicableSOLID
   ,Case ----when D.DepartmentCode='BBOG' THEN 'ALL BACID OF BBOG DEPARTMENT' 
   WHEN D.DeptGroupCode='FNA' THEN 'ALL BACID'  ELSE U.ApplicableBACID END ApplicableBACID
   ,U.Email_ID
   ,SUBSTRING(ISNULL(U.MobileNo,''),1,10) as MobileNo
   ,SUBSTRING(ISNULL(U.MobileNo,''),12,LEN(ISNULL(U.MobileNo,'')))  ExtensionNo
   ,U.MobileNo
   ,U.IsChecker
   ,U.IsChecker2
   ,U.Activate AS IsActive
   ,'QuickSearchTable' as TableName
 
   from DimUserInfo U
   --LEFT JOIN DimDepartment D ON
    LEFT JOIN Dimuserdeptgroup D ON
	   (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey >=@TimeKey)
	   and (u.EffectiveFromTimeKey<=@TimeKey AND u.EffectiveToTimeKey >=@TimeKey)
	   AND D.deptgroupid=U.DepartmentId
   LEFT JOIN DimUserRole R ON
	   (R.EffectiveFromTimeKey<=@TimeKey AND R.EffectiveToTimeKey >=@TimeKey)
	   and (u.EffectiveFromTimeKey<=@TimeKey aND U.EffectiveToTimeKey >=@TimeKey)
	   AND R.UserRoleAlt_Key=U.UserRoleAlt_Key
   ----left join #tempSelectedItem I ON I.UserLoginId=U.UserLoginID
   --LEFT JOIN DimDepttoBacid DB ON D.DepartmentAlt_Key =DB.DepartmentAlt_Key
			--					AND D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey
   --INNER JOIN #BACID BD ON BD.BACID=DB.BACID
   WHERE ( U.UserLoginID like CASE WHEN @UserLoginID<>'' THEN '%' + @UserLoginID + '%' ELSE U.UserLoginID END)
								AND 
								(ISNULL(U.UserName,'') LIKE CASE WHEN @UserName<>'' THEN '%'+@UserName+'%' ELSE ISNULL(U.UserName,'') END)
								AND (SUBSTRING(ISNULL(U.MobileNo,''),1,10) LIKE CASE WHEN @MobileNo <> '' Then '%' + @MobileNo +'%' ELSE SUBSTRING(ISNULL(U.MobileNo,''),1,10) END )
								AND (SUBSTRING(ISNULL(U.MobileNo,''),12,LEN(ISNULL(U.MobileNo,''))) LIKE CASE WHEN @ExtensionNo <> '' Then '%' + @ExtensionNo +'%' ELSE SUBSTRING(ISNULL(U.MobileNo,''),12,LEN(ISNULL(U.MobileNo,''))) END )
								
								AND (ISNULL(D.deptgroupid,'') IN (SELECT Dept_ALTKEY FROM #Dept_ALTKEY))
								-------LIKE CASE WHEN @UserDepartment <> '' THEN '%' + @UserDepartment + '%' ELSE ISNULL(D.DepartmentCode,'') END)
								
								AND (U.UserRoleAlt_Key= CASE WHEN  @UserRole <> '' THEN @UserRole else U.UserRoleAlt_Key END)
								AND (ISNULL(U.Email_ID,'')LIKE CASE WHEN @Email_ID <> '' THEN '%' +  @Email_ID + '%' ELSE ISNUll(U.Email_ID,'') END)
								AND (ISNULL(U.IsChecker,'')LIKE CASE WHEN @IsChecker <> '' THEN @IsChecker ELSE U.IsChecker END)
								--AND (ISNULL(U.IsChecker2,'')LIKE CASE WHEN @IsChecker2 <> '' THEN @IsChecker2 ELSE U.IsChecker2 END)
								AND (ISNULL(U.Activate,'')LIKE CASE WHEN @IsActive <> '' THEN @IsActive ELSE U.Activate END)
								----AND U.UserLoginID= CASE WHEN  @ApplicableSOLID <> '' THEN I.UserLoginId else U.UserLoginID  end
								--AND (ISNULL(DB.BACID,'') IN (SELECT BACID FROM #BACID))
		AND U.UserLoginID<>@LoginID
							  
	ORDER BY U.UserLoginID 

END
GO