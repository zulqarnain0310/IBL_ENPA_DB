SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO






Create PROCEDURE [dbo].[LastLoginBranchSelectUpdate] 
    @BranchCode		VARCHAR(20),
    @Type			VARCHAR(10),
	@userLoginId	VARCHAR(20)
AS
BEGIN
		DECLARE @Maxkey INT 
		IF	@Type = 'Login'
		BEGIN
			
			SELECT @Maxkey= MAX(EntityKey) FROM UserLoginHistory WHERE UserID =@userLoginId and BranchCode is not null

			SELECT BranchCode FROM UserLoginHistory WHERE EntityKey = @Maxkey

		END
		ELSE IF @Type = 'Logout'
		BEGIN
			
			SELECT @Maxkey= MAX(EntityKey) FROM UserLoginHistory WHERE UserID =@userLoginId
			
			UPDATE UserLoginHistory SET BranchCode = @BranchCode WHERE EntityKey = @Maxkey

			SELECT BranchCode FROM UserLoginHistory WHERE EntityKey = @Maxkey

			Declare @TimeKey INT
			SET @TimeKey = (SELECT  TimeKey  FROM    SysDataMatrix WHERE  CurrentStatus = 'C' )
			Update DimUserInfo Set UserLogged=0 where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
			AND UserLoginID=@userLoginId

		END
END


















GO