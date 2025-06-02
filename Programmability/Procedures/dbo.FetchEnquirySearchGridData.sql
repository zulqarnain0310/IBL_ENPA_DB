SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[FetchEnquirySearchGridData]
		 @DateOfData VARCHAR(10)	= ''
		,@UploadType VARCHAR(50)	= ''	
		,@UploadStatus VARCHAR(20)	= ''
		--,@Timekey INT				
		--,@UserLoginId VARCHAR(100)	= ''
		--,@Menuid INT
		--,@OperationFlag int
		--,@UniqueUploadID INT
AS

--DECLARE
--	 @DateOfData VARCHAR(10)	= '28/06/2021'
--	,@UploadType VARCHAR(50)	= 'Customer MOC Upload'
--	,@UploadStatus VARCHAR(20)	= 'Pending'

BEGIN
		SET NOCOUNT ON;

		DECLARE @Timekey INT

		--SET @Timekey=(SELECT CAST(timekey as int) from SysDaymatrix WHERE CONVERT(Date,DATE,103)=CONVERT(DATE,@DateOfData,103))

		--Set @Timekey=(select CAST(B.timekey as int) from SysDataMatrix A Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey 
		--								where A.CurrentStatus='C' OR (A.CurrentStatus_MOC='C' AND A.MOC_Initialised='Y'))

		PRINT @Timekey
		PRINT @DateOfData
		--PRINT CONVERT(DATE,@DateOfData,103) 

		IF OBJECT_ID('TEMPDB..#INT1')IS NOT NULL
				DROP TABLE #INT1

			SELECT  
				 UniqueUploadID
				,UploadedBy
				,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,
				--,DateofUpload,
				CASE WHEN  AuthorisationStatus='A' THEN 'Authorized'
					 WHEN  AuthorisationStatus='R' THEN 'Rejected'
					-- WHEN  AuthorisationStatus='1A' THEN '1Authorized'
					 WHEN  AuthorisationStatus IN ('NP','1A') THEN 'Pending' ELSE NULL END AS AuthorisationStatus
				---,Action
				,UploadType
				,CreatedBy
				,CONVERT(VARCHAR(10),DateCreated,103) AS DateCreated 
				,ApprovedBy
				,CONVERT(VARCHAR(10),DateApproved,103) AS DateApproved 

			
			INTO #INT1
			
			FROM ExcelUploadHistory
			   WHERE --(EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND 
			   --CONVERT(DATE,DateofUpload,103)=CONVERT(DATE,@DateOfData,103) 
			   AsOnDate=CONVERT(DATE,@DateOfData,103) 
			   AND CASE WHEN UploadType='Buyout Upload' THEN 'Securitization Upload' ELSE UploadType END =@UploadType
			   AND AuthorisationStatus IN('NP','MP','DP','R','RM','A','1A')
			
			ORDER BY DateofUpload  DESC

			SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType
									,CreatedBy,DateCreated,ApprovedBy,CONVERT(VARCHAR(10),DateApproved,103) AS DateApproved
									FROM #INT1 Where AuthorisationStatus=@UploadStatus
			                         ORDER BY UniqueUploadID Desc 
									 
END
GO