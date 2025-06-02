SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



create Proc [dbo].[RPT-ECS_RiverseFeed_JOB]
@MonthEndDate	VARCHAR(10)
,@TypeOfFreeze CHAR(1)='R'
,@UserID varchar(10)
,@TimeKey	INT=0
,@SourceAltKey INT=20
,@Result     SMALLINT=1   OUTPUT

AS

BEGIN TRY
Declare
@ReverseFEED AS Varchar(50)='',
@JobStatus varchar(100) =''

IF @TypeOfFreeze='R' AND @SourceAltKey NOT IN (1,2)
BEGIN


 IF @SourceAltKey=20
 BEGIN
 SET @ReverseFEED ='ECS_Reverse_Feed_Job'
 END
 IF @SourceAltKey=10
 BEGIN
 SET @ReverseFEED ='finacle_Reverse_Feed'
 END
 IF @SourceAltKey=60
 BEGIN
 SET @ReverseFEED ='Prolendz_Reverse_Feed'
 END
 IF @SourceAltKey=40
 BEGIN
 SET @ReverseFEED ='calypso_Reverse_Feed'
 END
 IF @SourceAltKey=70
 BEGIN
 SET @ReverseFEED ='Ganseva_Reverse_Feed'
 END

		SELECT @JobStatus =CASE isnull(jh.run_status,5) WHEN 0 THEN 'Error Failed'
		WHEN 1 THEN 'Succeeded'
		WHEN 2 THEN 'Retry'
		WHEN 3 THEN 'Cancelled'
		WHEN 4 THEN 'In Progress' 
		WHEN 5 THEN 'Other'
		ELSE
		'Processing' END
	    FROM
			(msdb.dbo.sysjobactivity ja LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id) join msdb.dbo.sysjobs_view j on ja.job_id = j.job_id
			WHERE ja.session_id=(SELECT MAX(session_id) from msdb.dbo.sysjobactivity) and j.name=@ReverseFEED

		
			PRINT @JobStatus
			if(@JobStatus='Processing')
			 begin
			   SET @Result=-2
			    RETURN @Result 
			  END
			  ELSE
			    BEGIN
				exec  msdb.dbo.sp_start_job @ReverseFEED
		          SET @Result=1
		          RETURN @Result 
			    END

END

ELSE 
BEGIN
 SET @ReverseFEED ='PNPA_FlatfileGeneRation'
 END

		 declare @PNPA_Status char(1)
		 IF @SourceAltKey=1
		  BEGIN 
		     update SysDataMatrix set  PNPA_Status=NULL where ExtDate=convert(date,@MonthEndDate,103) AND CurrentStatus='C'
		  END
         select @PNPA_Status=isnull(PNPA_Status,'N') from SysDataMatrix where ExtDate =convert(date,@MonthEndDate,103) AND CurrentStatus='C'
		  if(@PNPA_Status='N')
		   begin
		   
	        	IF EXISTS(SELECT 1 
                 FROM msdb.dbo.sysjobs J 
                 JOIN msdb.dbo.sysjobactivity A 
                     ON A.job_id=J.job_id 
                 WHERE J.name=N'PNPA_FlatfileGeneRation' 
                 AND A.run_requested_date IS NOT NULL 
                 AND A.stop_execution_date IS NULL
                )
	        	 begin
	        	   PRINT 'The job is running!'
	        	    SET @Result=-2
	        	   RETURN @Result 
	        	 end
                
              ELSE
	          begin
                 PRINT 'The job is not running.'
	        	  exec  msdb.dbo.sp_start_job PNPA_FlatfileGeneRation
	        	   SET @Result=-3
	        	   RETURN @Result 
	         end
	  end
	  else
	   begin
	   SET @Result=1
	        RETURN @Result 
	   end


END TRY

BEGIN CATCH
SELECT ERROR_MESSAGE()
 SET @Result=-1
 RETURN @Result 

END CATCH	

		
			


GO