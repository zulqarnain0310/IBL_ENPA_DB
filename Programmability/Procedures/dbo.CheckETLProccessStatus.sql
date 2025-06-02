SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE procedure [dbo].[CheckETLProccessStatus]
(
  @Action varchar(20)='',
  @ProcessDate varchar(10)
)
as
begin
 if(@Action='execprocess')
   begin

   Declare @PDate Date 
   set @Pdate=convert(date,@ProcessDate,103)

        --CHECK IF THE PACKAGE CAN BE EXTRACT FOR GIVEN DATE OR NOT
	     declare @ETL_Completed char(1)
         select @ETL_Completed=isnull(ETL_Completed,'N') from SysDataMatrix where ExtDate =convert(date,@ProcessDate,103)
		  if(@ETL_Completed='N')
		   begin
		   --Checking if Package is Avialble or not
			    CREATE TABLE #LocalTempTable(ParameterName varchar(50),FileExist varchar(150));
			    insert into #LocalTempTable  execute FileExistornot @Pdate
				update #LocalTempTable
				set ParameterName = replace(ParameterName, 'Path', ' ')
			    declare @isFileNotFound	int; 
			    set @isFileNotFound =(select COUNT(FileExist) from #LocalTempTable where FileExist=0)
		   -- End Checking
			   if(@isFileNotFound>0)
				begin
				--TO RETURN ALL THE PACKAGE NAME WITH STATUS IF NOT AVAILBLE ANY OF THE PACKAGE 
					select 'Package Not Available' AS ETLprestatus;
					select * from #LocalTempTable;
					drop table #LocalTempTable;
	            end
			   else
				  begin
				  --select 'Packgae is ready to Extract';
					 drop table #LocalTempTable;
					 update [Package_AUDIT] set Execution_date=null,ExecutionStartTime=null,ExecutionEndTime=null,ExecutionStatus=0
			         select 'ETLStarted' AS ETLprestatus;
				  --EXTRACTING PACKGE BY Indusind_MainPackage 
				      update SysDataMatrix set CurrentStatus='U' where CurrentStatus ='C' 
				      update SysDataMatrix set CurrentStatus ='C' where ExtDate =@PDate 
			         exec msdb.dbo.sp_start_job Indusind_MainPackage 
					 
				     update SysDataMatrix set ETL_Completed='Y',ETL_CompletedDate=GETDATE() where ExtDate =@PDate 
				  end
		   end
          else
		   begin
			  select 'ETLCompleted' AS ETLprestatus;
		   end
   end
 if(@Action='getstatus')
   begin

   
		--declare @ExecutionStatus int
		--set @ExecutionStatus  = (select count(ExecutionStatus) from [Package_AUDIT] where ExecutionStatus=2)
		--if(@ExecutionStatus=2)
		-- begin
		--  update SysDataMatrix set ETL_Completed='Y',ETL_CompletedDate=GETDATE() where CurrentStatus ='C' 
		-- end

		declare @JobStatus varchar(100) =''
		SELECT @JobStatus =CASE jh.run_status WHEN 0 THEN 'Error Failed'
		WHEN 1 THEN 'Succeeded'
		WHEN 2 THEN 'Retry'
		WHEN 3 THEN 'Cancelled'
		WHEN 4 THEN 'In Progress' ELSE
		'Status Unknown' END
	    FROM
			(msdb.dbo.sysjobactivity ja LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id) join msdb.dbo.sysjobs_view j on ja.job_id = j.job_id
			WHERE ja.session_id=(SELECT MAX(session_id) from msdb.dbo.sysjobactivity) and j.name='Indusind_MainPackage'

		select Execution_date, DataBaseName,Package_AUDIT.PackageName,
		 DPA.PackageDescriptionName as description, 
		ExecutionStartTime,ExecutionStatus, ExecutionEndTime, TimeDuration_Min, 
			CASE    WHEN (@JobStatus = 'Error Failed' OR  @JobStatus = 'Cancelled') AND  ExecutionStatus =0 THEN 'EXTRACTION FAILED' 
					WHEN  ExecutionStatus  in (1,2)  THEN 'DATA EXTRACTED SUCCESSFULLY'
					WHEN  ExecutionStatus = 0  THEN 'IN PROGRESS'				 	
			END ProcessStatus
			--@JobStatus  
			--JobStatus 
		from [Package_AUDIT]  inner join DimPackageAudit as DPA on Package_AUDIT.TableName= DPA.PackageName where Execution_date<>''
		
   end
end




GO