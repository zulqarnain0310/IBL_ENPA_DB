SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
  

 -- UserCreationParameterisedMasterData_New 'legalchecker',4639,'Y'

CREATE PROCEDURE [dbo].[UserCreationParameterisedMasterData_New]    
(  
@UserLoginID varchar(20),  
@TimeKey INT,  
@UserCreationModification AS CHAR(1)  
)         
AS   
DECLARE @Code VARCHAR(20) 



 SET NOCOUNT ON;    
   DECLARE  @Tier INT  
   DECLARE  @UserLocation VARCHAR(50)  
   SET @Tier =(SELECT Tier from SysReportformat where BankName='IndusInd Bank')  
   DECLARE @UserRole_Key SMALLINT  

IF(@UserLoginID <> '' AND @TimeKey <> 0)
	BEGIN
	   SET @UserRole_Key=(SELECT UserRoleAlt_Key  FROM DimUserInfo WHERE   
						 (DimUserInfo.EffectiveFromTimekey<=@TimeKey AND DimUserInfo.EffectiveToTimekey>=@TimeKey) and UserLoginID =@UserLoginID)  
    
	   SET @UserLocation=(SELECT UserLocation  FROM DimUserInfo WHERE  
						 (DimUserInfo.EffectiveFromTimekey<=@TimeKey AND DimUserInfo.EffectiveToTimekey>=@TimeKey) and  UserLoginID =@UserLoginID)   

	   SET @Code=(SELECT UserLocationCode  FROM DimUserInfo WHERE   
						 (DimUserInfo.EffectiveFromTimekey<=@TimeKey AND DimUserInfo.EffectiveToTimekey>=@TimeKey) and UserLoginID =@UserLoginID )  
	END
ELSE
	BEGIN 
		PRINT 'Blank and zero'
		SET @UserRole_Key = 2
		SET @UserLocation = 'HO'
		SET @Code = 'HO'
		SELECT @TimeKey = timekey FROM SYSDAYMATRIX WHERE CONVERT(VARCHAR(10),date,110) = CONVERT(VARCHAR(10),GETDATE(),110)	
	END
    
  print @UserRole_Key  
  print @UserLocation  
  Print '@Code '
  Print @Code  
  print @tier  
-------  
print 'tier'
print @Tier
IF (@Tier =4)  
     BEGIN  
	 PRINT 'TIER 4'
   IF  @UserLocation = 'HO'  
         SELECT UserLocationAlt_Key ,LocationShortName,LocationName as  'LocationDescription' FROM  dimuserlocation    
       Where  UserLocationAlt_Key IN(1,2,3,4) AND EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey>=@TimeKey --ii ,4
        
   ELSE IF  @UserLocation = 'ZO'  
      SELECT UserLocationAlt_Key ,LocationShortName,LocationName as  'LocationDescription' FROM  dimuserlocation    
      Where  UserLocationAlt_Key IN(2,3,4) AND EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey>=@TimeKey --ii ,4 
       
   ELSE IF  @UserLocation = 'RO'  
      SELECT UserLocationAlt_Key ,LocationShortName,LocationName as  'LocationDescription' FROM  dimuserlocation    
      Where   UserLocationAlt_Key IN(3,4) AND EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey>=@TimeKey   --ii ,4
       
   ELSE IF  @UserLocation = 'BO'  
      SELECT UserLocationAlt_Key ,LocationShortName,LocationName as  'LocationDescription' FROM  dimuserlocation    
      Where   EffectiveFromTimekey<=@TimeKey   
     AND EffectiveToTimekey>=@TimeKey AND UserLocationAlt_Key IN(4)  
     
  
      END  
ELSE IF (@Tier = '3')  
     BEGIN  
	 PRINT 'TIER 3'
   IF  @UserLocation = 'HO'  
      SELECT UserLocationAlt_Key ,LocationShortName,LocationName as  'LocationDescription' FROM  dimuserlocation    
      Where  UserLocationAlt_Key IN(1,3)  --ii ,4
   ELSE IF  @UserLocation = 'RO'  
      SELECT UserLocationAlt_Key ,LocationShortName,LocationName as  'LocationDescription' FROM  dimuserlocation    
      Where   UserLocationAlt_Key IN(3)  --ii ,4
   ELSE IF  @UserLocation = 'BO'  
      SELECT UserLocationAlt_Key ,LocationShortName,LocationName as  'LocationDescription' FROM  dimuserlocation    
      --ii Where  UserLocationAlt_Key IN(4)  
   END  
ELSE IF (@Tier = '2')  
    BEGIN  
   IF  @UserLocation = 'HO'  
      SELECT UserLocationAlt_Key ,LocationShortName,LocationName as  'LocationDescription' FROM  dimuserlocation    
      Where UserLocationAlt_Key IN(1)  --ii ,4 
      
ELSE IF  @UserLocation = 'BO'  
      SELECT UserLocationAlt_Key ,LocationShortName,LocationName as  'LocationDescription' FROM  dimuserlocation    
      --ii Where UserLocationAlt_Key IN(4)  
     
   END  
--  
IF  @UserLocation = 'ZO'  
   BEGIN  
         print '@UserLocation'
		 print @UserLocation
		 PRINT 'Code'
		 PRINT @Code
    SELECT DISTINCT Branch_Key,BranchCode,BranchName,DimBranch.BranchZoneAlt_Key  
                      FROM DimBranch   
        
          WHERE   
          (DimBranch.EffectiveFromTimeKey    < = @TimeKey     
          AND DimBranch.EffectiveToTimeKey  > = @TimeKey)  
          --AND BranchType ='ZO'  
       --   and  DimBranch.BranchRegionAlt_Key  = @Code  
               and  DimBranch.BranchZoneAlt_Key  = @Code  
          AND ISNULL(DimBranch.AllowLogin,'N')='Y'     
          ORDER BY DimBranch.BranchName     
            
    SELECT DISTINCT RegionAlt_Key, RegionName   
      FROM DimBranch   
        
       INNER JOIN DimRegion ON DimBranch.BranchRegionAlt_Key = DimRegion.RegionAlt_Key  
         
          WHERE   
               (DimRegion.EffectiveFromTimeKey    < = @TimeKey     
          AND DimRegion.EffectiveToTimeKey  > = @TimeKey)   
          and BranchZoneAlt_Key = @Code  
      
          ORDER BY RegionName     
         
	SELECT DISTINCT ZoneAlt_Key,DimZone.ZoneName   
                     FROM DimBranch  
        
       INNER JOIN DimZone ON DimBranch.BranchZoneAlt_Key = DimZone.ZoneAlt_Key  
        
                      WHERE   
                      (DimZone.EffectiveFromTimeKey    < = @TimeKey     
                AND DimZone.EffectiveToTimeKey  > = @TimeKey)  
                      and ZoneAlt_Key = @Code   
                        ORDER BY DimZone.ZoneName    

	SELECT ZoneName AS BranchName, 'ZO' AS BranchType FROM DIMZone 
		WHERE ZoneAlt_Key = @Code 
		AND DimZone.EffectiveFromTimeKey < = @TimeKey AND DimZone.EffectiveToTimeKey  > = @TimeKey

	 IF @UserRole_Key=1
		BEGIN
			SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole
		END   
	ELSE IF @UserRole_Key=2
		BEGIN  
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(2,3,4)  
		  END
	ELSE IF @UserRole_Key=3
		BEGIN  
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(3,4)  
		  END
	ELSE IF @UserRole_Key=4
		BEGIN  
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(4)  
		  END

    END  
    -- why we need a seperate condition for RI  
 --ELSE IF  @UserLocation = 'RI'  
 -- BEGIN  
  
 --    SELECT DISTINCT BranchCode AS RegionAlt_Key, BranchName AS RegionName, 2 AS CODE   
 --     FROM DimBranch   
 --     WHERE BranchType='RI'  
 --   END  
      
   ELSE IF @UserLocation = 'RO' OR @UserLocation = 'RI'  
      BEGIN  
  
  SELECT DISTINCT Branch_Key,BranchCode,BranchName,DimBranch.BranchRegionAlt_Key AS BranchZoneAlt_Key    
                      FROM DimBranch   
       
          WHERE    
          (DimBranch.EffectiveFromTimeKey    < = @TimeKey     
          AND DimBranch.EffectiveToTimeKey  > = @TimeKey)  
         -- and   BranchType  IN ('RI','RO') and  
         AND DimBranch.BranchRegionAlt_Key    = @Code  
       --AND BranchType NOT IN ('HO','HI','RI','RO')  
          AND (ISNULL(DimBranch.AllowLogin,'N')='Y'  or ISNULL(DimBranch.AllowMakerChecker,'N')='Y')       
          ORDER BY DimBranch.BranchName     
      
    SELECT   RegionAlt_Key,RegionName FROM  
            (SELECT DISTINCT RegionAlt_Key, RegionName, 1 AS CODE   --'RO - '+RegionName AS RegionName
              FROM DimBranch  
               
              INNER JOIN DimRegion ON DimBranch.BranchRegionAlt_Key = DimRegion.RegionAlt_Key  
               
              WHERE   
               (DimRegion.EffectiveFromTimeKey    < = @TimeKey     
              AND DimRegion.EffectiveToTimeKey  > = @TimeKey)   
              AND RegionAlt_Key = @Code  
                
              
            UNION  
            SELECT DISTINCT BranchCode  AS RegionAlt_Key, BranchName AS RegionName, 2 AS CODE   
              FROM DimBranch   
              WHERE BranchType='RI')  
         DimBranch ORDER BY CODE  
     
	SELECT '' AS ZoneAlt_Key,'' AS ZoneName 
	
	 SELECT RegionName AS BranchName, 'RO' AS BranchType FROM DimRegion 
		WHERE RegionAlt_Key = @Code 
		AND DimRegion.EffectiveFromTimeKey < = @TimeKey AND DimRegion.EffectiveToTimeKey  > = @TimeKey

	 IF @UserRole_Key=1
		BEGIN
			SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole
		END   
	ELSE IF @UserRole_Key=2
		BEGIN  
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(2,3,4)  
		  END
	ELSE IF @UserRole_Key=3
		BEGIN  
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(3,4)  
		  END
	ELSE IF @UserRole_Key=4
		BEGIN  
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(4)  
		  END

           END   
     
   ELSE IF @UserLocation = 'BO'  
        BEGIN  
          SELECT DISTINCT Branch_Key,BranchCode,BranchName,BranchZoneAlt_Key    
                      FROM DimBranch   
       
                   WHERE   
                   (DimBranch.EffectiveFromTimeKey    < = @TimeKey     
                   AND DimBranch.EffectiveToTimeKey  > = @TimeKey)  
                 --AND  BranchType NOT IN ('HO','HI','RI','RO')   
                  -- AND  BranchType='BO'   
                   AND BranchCode  = @Code  
                   ORDER BY BranchName    
	
	 SELECT '' AS RegionAlt_Key,'' AS RegionName
	 
	 SELECT '' AS ZoneAlt_Key,'' AS ZoneName
	  
	 SELECT BranchName, 'BO' AS BranchType FROM dimbranch 
		WHERE BranchCode = @Code 
		AND dimbranch.EffectiveFromTimeKey < = @TimeKey AND dimbranch.EffectiveToTimeKey  > = @TimeKey

	 IF @UserRole_Key=1
		BEGIN
			SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole
		END   
	ELSE IF @UserRole_Key=2
		BEGIN  
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(2,3,4)  
		  END
	ELSE IF @UserRole_Key=3
		BEGIN  
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(3,4)  
		  END
	ELSE IF @UserRole_Key=4
		BEGIN  
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(4)  
		  END

     END   
   ELSE IF  @UserLocation = 'HO'  
    BEGIN  
	print 't'
   SELECT DISTINCT Branch_Key,BranchCode,BranchName,BranchZoneAlt_Key    
                      FROM DimBranch   
                   WHERE  (DimBranch.EffectiveFromTimeKey    < = @TimeKey     
                AND DimBranch.EffectiveToTimeKey  > = @TimeKey)   
                AND ISNULL(BranchType,'ZO') NOT IN ('HO','HI','RI','RO')  
                --and BranchType='HO' not worked when user select Branch in UI  
                AND BranchName IS NOT NULL  
                  
                AND (ISNULL(DimBranch.AllowLogin,'Y')='Y'  or ISNULL(DimBranch.AllowMakerChecker,'Y')='Y')    
                      ORDER BY Dimbranch.BranchName     

    SELECT   RegionAlt_Key,RegionName FROM  
            (SELECT DISTINCT RegionAlt_Key, RegionName, 1 AS CODE   -- 'RO - '+RegionName AS RegionName
              FROM DimBranch   
               
              INNER JOIN DimRegion ON DimBranch.BranchRegionAlt_Key = DimRegion.RegionAlt_Key  
               
              WHERE (DimRegion.EffectiveFromTimeKey    < = @TimeKey     
              AND DimRegion.EffectiveToTimeKey  > = @TimeKey)   
               
            UNION  
            SELECT DISTINCT BranchCode AS RegionAlt_Key, BranchName AS RegionName, 2 AS CODE   
              FROM DimBranch   
              WHERE BranchType='RI')  
         DimBranch ORDER BY CODE  

   SELECT DISTINCT ZoneAlt_Key,DimZone.ZoneName   
                     FROM    DimBranch   
      
       LEFT JOIN DimZone ON DimBranch.BranchZoneAlt_Key = DimZone.ZoneAlt_Key  
       
                      WHERE (DimZone.EffectiveFromTimeKey    < = @TimeKey     
                AND DimZone.EffectiveToTimeKey  > = @TimeKey)   ORDER BY ZoneName    
      PRINT 'BRANCH Testing'
   SELECT BranchName,BranchType FROM DIMBRANCH WHERE ISNULL(BranchType,'HO') IN ('HO','HI')  
		PRINT 'BRANCH TESTING OVER'
   IF @UserRole_Key=1
		BEGIN
			PRINT 1
			SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole
		END   
	ELSE IF @UserRole_Key=2
		BEGIN  
		PRINT 2
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(2,3,4)
		PRINT 22			 
					 
		  END
	ELSE IF @UserRole_Key=3
		BEGIN  
		PRINT 3
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(3,4)  
		  END
	ELSE IF @UserRole_Key=4
		BEGIN  
		PRINT 4
		   SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				Where  UserRoleAlt_Key IN(4)  
		  END
      END  
    --  IF @UserLocation='HO'AND @UserRole_Key=1  
		  --BEGIN  
		  -- SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole --Where [RecordStatus]='c'   
		  --END   
    --  ELSE   
		  --BEGIN  
		  -- SELECT UserRoleAlt_Key ,UserRoleShortNameEnum as RoleDescription FROM  DimUserRole   
				--Where  UserRoleAlt_Key IN(2,3,4)  
		  --END   
         
  
   IF @UserCreationModification='N'   
  
    BEGIN  
    print 'meta data'  
    SELECT * from metaUserFieldDetail WHERE FrmName ='frmUserCreationNew'    
    END  
  
  ELSE  
  
    BEGIN 
	PRINT 111111 
   SELECT * from metaUserFieldDetail WHERE FrmName ='frmUserModification'    
    END      
   
    
SELECT * FROM DimUserParameters WHERE (EffectiveFromTimeKey    < = @TimeKey   AND EffectiveToTimeKey  > = @TimeKey) order by SeqNo     -- EffectiveToTimeKey     =9999  order by SeqNo    
 PRINT 22222  
IF @UserCreationModification='Y'   
  
BEGIN  
	PRINT 333333
    select 1 as Code,'Change User Location' as Description  
    UNION ALL   
     
    select 2 as Code,'Activate/Deactivate' as Description     
    UNION ALL   
    select 3 as Code,'Changing Of Role' as Description  
	UNION ALL
	Select 4 as Code,'Change Dept/Group' as Description
		PRINT 444444
  
 END    
 
	--select DeptGroupId, REPLACE(DeptGroupCode,'#','') as DeptGroupCode,DeptGroupName,Menus from DimUserDeptGroup
	--	where EffectiveFromTimeKey    < = @TimeKey     
    --  AND EffectiveToTimeKey  > = @TimeKey
	--Union
	-- Select 0, 'Select','Select','' from DimUserDeptGroup 
	-- Union
	-- Select 1, 'ALL','ALL','' from DimUserDeptGroup 
	 EXEC UserGroupsAuxSelect @TimeKey
	 PRINT 'UserGroupsAuxSelect '
	--Select DataSequence
	--			  ,MenuTitleId
	--			  ,MenuId
	--			  ,Isnull(ParentId,0) as ParentId
	--			  ,MenuCaption
	--			  ,BusFld
	--			  ,ThirdGroup
	--			  ,ApplicableFor
	--			  ,Visible
	--			  ,Report
	--			  ,AvailableFor
	--			  ,DeptGroupCode as Department
	--			  ,AuthorisationStatus 
	--				from SysCRisMacMenu 
	--			 where report='N' and Visible=1 AND Menucaption<>'Authorize' 
	--			 AND ((len(ISNULL(ApplicableFor,''))=4 OR ApplicableFor IS NULL)) and MenuCaption not in ('&Operations','Mode of Operation','Add','Edit/Delete','View','E&xit','Exit','Change Branch Selection')
				
	--			 ORDER BY MENUTITLEID,DATASEQ

		 Select  EntityKey, MenuTitleId,DataSeq, ISNULL(MenuId,0) MenuId ,ISNULL(ParentId,0) ParentId,MenuCaption, ActionName,BusFld
					From SysCRisMacMenu WHERE Visible=1
					Order by MenuTitleID, DataSeq

   SELECT	UserDeletionReasonAlt_Key AS Code
					,UserDeletionReasonName AS Description
					,UserDeletionReason_Key 
					,UserDeletionReasonGroup AS _Group
					,UserDeletionReasonSubGroup AS SubGroup
					,UserDeletionReasonSegment AS Segment
					,UserDeletionReasonShortName AS ShortName
					,UserDeletionReasonShortNameEnum AS ShortNameEnum
					,EffectiveFROMTimeKey
					,EffectiveToTimeKey  
			FROM DimUserDeletionReason
	
	SELECT ParameterValue FROM SysSolutionParameter Where ParameterName='BankEmpIdUIdSame'

	SELECT DesignationAlt_Key, DesignationName, DesignationShortName  FROM DimDesignation  
	
   

   SET ANSI_NULLS ON
     
   SELECT Cast(0 as smallint) AS Code,'NA' AS Description

 select ParameterAlt_Key as Code, ParameterName as Description  from DimParameter  where DimParameterName='DimEmployeeType' 

select ParameterAlt_Key as Code, ParameterName as Description  from DimParameter  where DimParameterName='DimGrade' AND ParameterAlt_Key<>0
order by ParameterAlt_Key	






GO