SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/* CREATED BY DF627 on 23-05-24 FOR STORING THE RECORDS OF CURRENTLY EXECUTING QUERIES WITHIN THE SQL SERVER INSTANCE   */

CREATE PROC [dbo].[BlockCommandInUp]
AS
BEGIN
INSERT INTO DBO.SpBlock
SELECT      r.start_time [Start Time],r.session_ID [SPID],
            DB_NAME(r.database_id) [Database],
			t.TEXT AS QueryName, --ADDED ON 18-07-2023
            SUBSTRING(t.text,(r.statement_start_offset/2)+1,
            CASE WHEN statement_end_offset=-1 OR statement_end_offset=0
            THEN (DATALENGTH(t.Text)-r.statement_start_offset/2)+1
            ELSE (r.statement_end_offset-r.statement_start_offset)/2+1
            END) [Executing SQL],
            r.Status,command,wait_type,wait_time,wait_resource,
            last_wait_type
            ,A.program_name --ADDED ON 18-07-2023
			,A.login_name --ADDED ON 18-07-2023
			,A.host_name --ADDED ON 18-07-2023
			--,A.last_request_start_time --ADDED ON 18-07-2023
			,case when t.TEXT like '%create proc%' then replace(replace(replace(replace(SUBSTRING(t.text,CHARINDEX('create proc',t.text),CHARINDEX('as',t.text))
,'create procedure',''),'declare',''),'@',''),'create proc','') end as SpName			
FROM        sys.dm_exec_requests r
OUTER APPLY sys.dm_exec_sql_text(sql_handle) t
LEFT JOIN   sys.dm_exec_sessions A ON A.session_id=R.session_id--ADDED ON 18-07-2023
WHERE       r.session_id != @@SPID -- don't show this query
AND         r.session_id > 50 -- don't show system queries
AND t.TEXT IS NOT NULL --ADDED ON 18-07-2023
ORDER BY    r.start_time

END
GO