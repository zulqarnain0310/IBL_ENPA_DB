SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Shubham Kamble>
-- Create date: <29/12/2023>
-- Description:	<Upgrade, Downgrade, Write Off Data Select>
-- =============================================

CREATE PROCEDURE [dbo].[UpDwnWrtoff_ReportDownload]  

-- [dbo].[UpDwnWrtoff_ReportDownload]   'Shubham123','Write-Off Report','01/01/2024','31/01/2024'

@UserLoginId VARCHAR(100)
,@ReportType VARCHAR(50)
,@StartDate VARCHAR(10)
,@EndDate VARCHAR(10)
--,@Timekey INT				
,@Result INT	=0 OUTPUT

AS
BEGIN
		SET NOCOUNT ON;
	  --SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus='C') 
	  --PRINT @Timekey
		SET @StartDate	= CONVERT(DATE,@StartDate,103)
		SET @EndDate	= CONVERT(DATE,@EndDate,103)
	
		
IF (@ReportType= 'Upgrade Report' OR @ReportType= 'Downgrade Report' OR @ReportType= 'Write-Off Report' )
	BEGIN	

-----------------------------Date validation-------------------------------------	
			IF EXISTS(SELECT 1 FROM HistoryUpgradationData WHERE @StartDate > @EndDate) 
				BEGIN
							--Rollback 
							SET @Result=-8
							PRINT  'Invalid Date!'
							RETURN @Result
				END
			ELSE IF EXISTS(SELECT 1 FROM HistoryDownGradeData WHERE @StartDate > @EndDate) 
				BEGIN
							--Rollback 
							SET @Result=-8
							PRINT  'Invalid Date!'
							RETURN @Result
				END
			ELSE IF EXISTS(SELECT 1 FROM HistoryWrittenOffData WHERE @StartDate > @EndDate) 
				BEGIN
							--Rollback 
							SET @Result=-8
							PRINT  'Invalid Date!'
							RETURN @Result
				END	


------------------Select Reports If the date is valid------------------------------------

			ELSE
				BEGIN
						IF (@ReportType= 'Upgrade Report')
							BEGIN
																	
									Select	'Details' AS TableName
										
											,convert(varchar(20),AsOnDate) [AsOnDate]						
											,SourceName						
											,NCIF							
											,Account							
											,[Funded Non Funded Flag]		
											,CIF								
											,Pan								
											,[Customer Name]					
											,[Max DPD on date of upgrade]	
											,convert(varchar(20),[Date of upgrade by D2K]) [Date of upgrade by D2K]		
											,[Principal OS]					
											,[Interest OS]					
											,[Yesterday Max DPD]				
											,[Yesterday Principal OS]		
											,[Yesterday Interest OS]			
											,[Asset class prior to upgrade]	
											,convert(varchar(20),[NCIF NPA Date prior to upgrade])[NCIF NPA Date prior to upgrade]
											,[Asset class on upgrade date]	
											,[Scheme Type]					
											,[Scheme Description]			
											,[Scheme Code]					
											,Segment							
											,[Sub Segment]					
											,IS_MOC							
											,convert(varchar(20),[Renewal Date]) [Renewal Date]					
											,convert(varchar(20),[Stock statement date]) [Stock statement date]			
											,convert(varchar(20),[DCCO date]) [DCCO date]						
											,convert(varchar(20),[Project Completion Date]) [Project Completion Date]		
												
									from HistoryUpgradationData
									where  AsOnDate >=@StartDate AND AsOnDate<=@EndDate

									/*Count*/
									--SELECT 
									--		'Summary' as TableName
									--		,COUNT(*) as Count
									--FROM HistoryUpgradationData
									--where  AsOnDate >=@StartDate AND AsOnDate<=@EndDate
							END				

				--------------------------------------------------------------------------------------------------

						ELSE IF (@ReportType= 'Downgrade Report')
							BEGIN
														
									Select	'Details' AS TableName
											,convert(varchar(20),AsonDate) [AsonDate] 							
											,SourceName							
											,Account							
											,[Funded Non Funded Flag]			
											,CIF								
											,NCIF								
											,[PAN No]							
											,Name								
											,DPD_Overdue_Loans					
											,DPD_Interest_Not_Serviced			
											,[DPD_Overdue Interest]				
											,DPD_Overdrawn						
											,[DPD_Principal Overdue]			
											,[DPD_Other Overdue]				
											,DPD_Renewals						
											,[DPD_Stock Statement]				
											,[Max DPD on date of downgrade]		
											,convert(varchar(20),[Date of downgrade])	[Date of downgrade]			
											,convert(varchar(20),[Date of NPA of source system]) [Date of NPA of source system]		
											,convert(varchar(20),[Homogenized_Date of NPA])	[Homogenized_Date of NPA]		
											,[Classification of source system]	
											,Homogenized_Classification			
											,[Principal OS]						
											,[Interest OS]						
											,[Yesterday Principal OS]			
											,[Yesterday Interest OS]			
											,[Scheme Type]						
											,Scheme_Code						
											,[Scheme Description]				
											,Segment							
											,IS_MOC								
											,convert(varchar(20),[Renewal Date])	[Renewal Date]					
											,[Stock statement date]			
											,convert(varchar(20),[DCCO date]) [DCCO date]						
											,convert(varchar(20),[Restructuring date]) [Restructuring date]				
											,[Restructuring Flag]				
											,[Restructuring Type]				
											,[Fraud flag]						
											,[Culprit System]					
											,[Culprit System Account No]		
											,convert(varchar(20),[Stock statement date1]) [Stock statement date1]			
											,flgdeg		
											
									from HistoryDownGradeData
        							where  AsonDate >=@StartDate AND AsonDate<=@EndDate
							END
				--------------------------------------------------------------------------------------------------	
						
						ELSE IF (@ReportType= 'Write-Off Report') 
							BEGIN

									Select
											'Details' AS TableName
											--,convert(varchar(50),@InsertDate) [InsertDate] 							
											,AsonDate
											,SourceName							
											,[Account No]						
											,CIF								
											,NCIF								
											,Pan								
											,CustomerName						
											,DPD_Overdue_Loans					
											,DPD_Interest_Not_Serviced			
											,[DPD_Overdue Interest]				
											,DPD_Overdrawn						
											,[DPD_Principal Overdue]			
											,[DPD_Other Overdue]				
											,DPD_Renewals						
											,[DPD_Stock Statement]				
											,[Max DPD on date of write off]		
											,convert(varchar(20),[Date of Write off by D2K])	[Date of Write off by D2K]			
											,[Principal OS]						
											,[Interest OS]						
											,convert(varchar(20),[NCIF NPA date prior to write off])	[NCIF NPA date prior to write off]	
											,[Asset class prior to write off]	
											,Scheme_Type						
											,Scheme_Code						
											,[Scheme Description]				
											,Segment							
											,IS_MOC								
											,convert(varchar(20),[Renewal Date])	[Renewal Date] 						
											,convert(varchar(20),[Stock statement date]) [Stock statement date]				
											,convert(varchar(20),[DCCO date])	[DCCO date]						
											,convert(varchar(20),[Restructuring date])	[Restructuring date]				
											,convert(varchar(20),[NPA Date NCIF])	[NPA Date NCIF]				
											,[Fraud Flag]						
											,[Woff Flag]						
											,[ARC Flag]							
											,[OTS Flag]							
											
									from HistoryWrittenOffData
									where  AsonDate >=@StartDate AND AsonDate<=@EndDate
							END
				END -- ELSE closed
	END

END

GO