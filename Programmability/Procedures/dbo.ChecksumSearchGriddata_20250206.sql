SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ChecksumSearchGriddata_20250206] 
 @SourceName VARCHAR(100) 
,@TIMEKEY INT

AS
--Declare  
--@SourceName VARCHAR(100) ='Ganaseva'
--,@TIMEKEY INT=27163
BEGIN 
SET DATEFORMAT DMY
	SET NOCOUNT ON;  
	    PRINT @Timekey   
		 
		
	--Select Distinct SourceName FROM CheckSumData_FF 
	--					 WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) 

	IF ISNULL(@SourceName,'')<>'' 
				BEGIN
						SELECT 
								 EntityID
								,Convert(Varchar(10),ProcessDate,103) as ProcessDate
								,SourceName 
								,DataSet 
								,CRISMAC_CheckSum 
								,Source_CheckSum 
								,Start_BAU 
								,Processing_Type 
								,Reason	 
								,AuthorisationStatus  
								 FROM CheckSumData_FF 
								 WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) 
								 --AND ISNULL(Start_BAU,'N')='N'  AND ISNULL(AuthorisationStatus,'N')='N'
								 AND SourceName=@SourceName  
					END
			Else
					BEGIN 
							SELECT 'Please select any one source system'				  
					END
					 
END



GO