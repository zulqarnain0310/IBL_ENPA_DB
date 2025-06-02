SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
--USE [IndusInd_New]
--GO
--/****** Object:  StoredProcedure [dbo].[User_NCIF]    Script Date: 15-Jan-18 10:07:30 AM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
----EXEC User_NCIF 'NPAMakerUser' ,24745  

CREATE PROC [dbo].[User_NCIF](@UserLoginId VARCHAR(10), @Timekey INT, @ClientID	   VARCHAR(20)=NULL  )
AS
--DECLARE @UserLoginId VARCHAR(10) = 'NPAMakerUser'
--DECLARE @Timekey INT = 24745
--PRINT @Timekey
DECLARE @SourceAlt_key VARCHAR(50)

DECLARE @DeptGroupCode INT

SELECT @DeptGroupCode =  DeptGroupCode FROM DimUserInfo	WHERE EffectiveFromTimeKey <= @Timekey 
														AND    EffectiveToTimeKey  >= @Timekey
														AND    UserLoginID          = @UserLoginId



SELECT @SourceAlt_key = SourceAlt_Key FROM DimUserDeptGroup	WHERE EffectiveFromTimeKey <= @Timekey
															AND	  EffectiveToTimeKey   >= @Timekey
															AND   DeptGroupId           = @DeptGroupCode

SELECT NCIF_Id FROM NPA_IntegrationDetails	WHERE EffectiveFromTimeKey <= @Timekey
											AND   EffectiveToTimeKey   >= @Timekey
											AND   CustomerId			= CASE	WHEN ISNULL(@ClientID,'')=''
																				THEN CustomerId
																				ELSE @ClientID
																			END
											AND  SrcSysAlt_Key			= CASE	WHEN ISNULL(@SourceAlt_key,'')=''
																				THEN SrcSysAlt_Key
																				ELSE @SourceAlt_key
																			END
GROUP BY NCIF_Id


GO