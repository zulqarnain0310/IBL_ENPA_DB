SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================  
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- =============================================  
create PROCEDURE [dbo].[UserMasterSearchMeta]  
@UserLoginID varchar(20),    
@TimeKey INT   
AS  
  
--DECLARE   
--@UserLoginID varchar(20)='FNASUPERADMIN',    
--@TimeKey INT =25202  
  
BEGIN  
 --Select DepartmentAlt_Key as Code,DepartmentName as [Description],'DimDepartment' as TableName from DimDepartment  
 IF ISNULL(@TimeKey,0)=0  
  BEGIN  
    Select @TimeKey=Timekey from SysDayMatrix where [Date]=Cast(getdate() as date)  
  END  
  
  
 -- Select @Timekey=Max(Timekey) from SysProcessingCycle  
 --where Extracted='Y' and ProcessType='Full' and PreMOC_CycleFrozenDate IS NULL  
  
 PRINT @TimeKey  
  
  
  
 DECLARE @DepartmentCode VARCHAR(50),@DepartmentAlt_Key VARCHAR(50)   
   
 SELECT @DepartmentCode = dep.DeptGroupCode,@DepartmentAlt_Key=DEP.DeptGroupid   
 FROM DimUserInfo INFO  
 --INNER JOIN DimDepartment DEP
  INNER JOIN DimuserDeptgroup DEP    
  ON INFO.EffectiveFromTimeKey <= @Timekey AND INFO.EffectiveToTimeKey >= @Timekey  
  AND DEP.EffectiveFromTimeKey <= @Timekey AND DEP.EffectiveToTimeKey >= @Timekey  
  AND UserLoginID = @UserLoginId  
  AND INFO.DepartmentId = DEP.DeptGroupid 
  
  PRINT @DepartmentCode   
  PRINT @DepartmentAlt_Key  
  
 Select deptgroupid as Code,DeptgroupCode as [Description],'DimDepartment' as TableName   
 from DimuserDeptgroup  
 where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey)  
 AND ISNULL(AuthorisationStatus,'A')='A'  
 AND (  
        CASE   
     WHEN @DepartmentCode IN ('FNA') THEN 1  
     WHEN @DepartmentCode =deptgroupcode THEN 1  
     end  
     )=1  
  ORDER BY 2
 --  Declare @ApplicableBACID varchar(max)=''  
 --Select @ApplicableBACID=  
 --ApplicableBACID from DimDepartment  
 --where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey)  
 --AND DepartmentAlt_Key=@DepartmentAlt_Key
 ------AND ISNULL(AuthorisationStatus,'A')='A'  
 ----AND (  
 ----       CASE   
 ----    WHEN @DepartmentCode IN ('FNA') THEN 0  
 ----    WHEN @DepartmentCode =DepartmentCode THEN 1  
 ----    end  
 ----    )=1 AND DepartmentAlt_Key=@DepartmentAlt_Key  
   
 --PRINT '@ApplicableBACID '+@ApplicableBACID  
  
  
 --IF OBJECT_ID('TEMPDB..#BACID') IS NOT NULL  
 --DROP TABLE #BACID  
  
 --SELECT Items AS BACID      
 --INTO #BACID    
 --FROM dbo.Split(@ApplicableBACID,',')    
  
 --  UPDATE #BACID SET BACID =REPLACE(REPLACE(BACID, CHAR(13), ''), CHAR(10), '')   
 --     UPDATE #BACID SET BACID =LTRIM(RTRIM(BACID))  
  
   ----select * from #bacid  
  
 --IF @DepartmentCode IN ('FNA')  
 --BEGIN  
 --   Select   
 --BACID,OAName,'DimOfficeAccountBACID' as TableName  
 --from DimOfficeAccountBACID  
 --where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey)  
 --AND ISNULL(AuthorisationStatus,'A')='A'  
      
 --Select  
 --BranchCode as Code,BranchCode as [Description],'DimBranch' as TableName  
 --from DimBranch  
 --WHERE (EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey)  
 --END  
 --ELSE  
  
  
  
 BEGIN  
   --  Select * into #TempDimDepartmentBACID  
   --from  
   --(  
   --  Select  
   --  DepartmentAlt_Key,applicableBACID  
   --  from DimDepartment DBAC  
   --  --Inner join DimBranch B ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey >=@TimeKey)  
   --  --AND #BranchCode.BranchCode=B.BranchCode  
       
   --  where (DBAC.EffectiveFromTimeKey<=@TimeKey AND DBAC.EffectiveToTimeKey >=@TimeKey)  
   --   AND DBAC.DepartmentAlt_Key=@DepartmentAlt_Key  
   --) K  
  
   --Insert into #TempDimDepartmentBACID  
   --(  
   --    DepartmentAlt_Key  
   --  ,BACID  
       
  
   --)  
   --(  
   --   Select  
   --  @DepartmentAlt_Key  
   --  ,BACID  
    
   -- from DimOfficeAccountBACID BAC  
      
   -- where (BAC.EffectiveFromTimeKey<=@TimeKey AND BAC.EffectiveToTimeKey >=@TimeKey)  
   -- AND ISNULL(BAC.AuthorisationStatus,'A')='A'  
   -- --AND ISNULL(BAC.BACIDscope,1)=1  
  
   --)  
        
  --   Select   
  --BAC.BACID as Code ,BAC.BACID as Description,'DimOfficeAccountBACID' as TableName  
  ----BAC.BACID as Code ,OAName as Description,'DimOfficeAccountBACID' as TableName  
  --from DimOfficeAccountBACID BAC  
  ------inner join #BACID DBAC  
  ------ ON DBAC.BACID=BAC.BACID  
  -- --AND DBAC.DepartmentAlt_Key=@DepartmentAlt_Key  
  --where (BAC.EffectiveFromTimeKey<=@TimeKey AND BAC.EffectiveToTimeKey >=@TimeKey)  
  --AND ISNULL(BAC.AuthorisationStatus,'A')='A'  
  ----AND DBAC.BACID NOT LIKE'%[A-Z]%'  
  --ORDER BY 2
   Select  
   B.BranchCode as Code,b.BranchCode as [Description],'DimBranch' as TableName  
   from DimBranch B  
   --inner join #BranchCode ON B.BranchCode=#BranchCode.BranchCode  
    WHERE (EffectiveFromTimeKey <=@TimeKey AND EffectiveToTimeKey >=@TimeKey) 
	ORDER BY 2
 END  
   
 IF @DepartmentCode='FNA'  
 BEGIN  
    Select   
  UserRoleAlt_Key as Code,UserRoleName as [Description],'DimUserRole' as TableName  
  from DimUserRole  
  where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey)
  ORDER BY 2
 END  
 ELSE  
 BEGIN  
     Select   
  UserRoleAlt_Key as Code,UserRoleName as [Description],'DimUserRole' as TableName  
  from DimUserRole  
  where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey)  
  AND UserRoleAlt_Key IN (2,3,4)  
  ORDER BY 2
 END  
   
  
 Select  
 ParameterShortName as Code,ParameterName as [Description],'DimYesNo' as TableName  
 from DimParameter  
 where DimParameterName='DimYesNo'  
  ORDER BY 2
 Select @DepartmentAlt_Key AS Code,@DepartmentCode AS [Description] ,'UserDept' as TableName  
  ORDER BY 2
   SET ANSI_NULLS ON    
END  
GO