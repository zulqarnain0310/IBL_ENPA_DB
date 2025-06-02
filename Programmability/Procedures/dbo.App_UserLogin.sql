SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[App_UserLogin]
@Userid	VARCHAR(100)= NULL,
@Password VARCHAR(400)=NULL
AS
BEGIN
	DECLARE @TimeKey  INTEGER
	SET  @TimeKey=(SELECT TimeKey From SysDayMatrix WHERE convert(varchar(10),Date,103)= convert(varchar(10),Getdate(),103))
	Declare @Tier int
	Select @Tier=Tier From SysReportformat WHERE Active='Y'
	Declare @ClientName as Varchar(50)
	select @ClientName=ParameterValue from syssolutionparameter where ParameterAlt_Key=101   
						BEGIN 
						SELECT 
						 DU.UserLoginID   As UserId
						,du.UserName    As UserName
						,D.UserRoleName AS  UserRole
						,du.userlocation as UserLevel
						,DU.UserLocationCode
						,NULL as UserLocationName
						,@ClientName AS ClientName
						,@Tier AS Tier
						,@TimeKey as TimeKey
						,'LoginDetails' As [TableName]
						FROM DimUserInfo DU   
					  LEFT JOIN DIMUSERROLE D ON D.EffectiveFromTimeKey<=@TimeKey And D.EffectiveToTimeKey>=@TimeKey 
								and D.UserRoleAlt_Key=DU.UserRoleAlt_Key
			
			WHERE DU.UserLoginID=@Userid
			AND DU.LoginPassword=@Password
			AND (DU.EffectiveFromTimeKey<=@TimeKey And DU.EffectiveToTimeKey>=@TimeKey)
			AND SuspendedUser='N'
			AND Activate='Y'
			END

	END

GO