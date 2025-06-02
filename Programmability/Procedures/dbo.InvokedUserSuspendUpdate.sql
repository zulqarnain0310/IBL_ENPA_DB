SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Shivendra Singh>
-- ALTER date: <27/07/2010>
-- Description:	<In Dimuser info update flage for susped user,,>
-- =============================================
CREATE PROCEDURE [dbo].[InvokedUserSuspendUpdate]
	(
	 @UserLoginID varchar(20),
	 @LoginPassword varchar(50),
	 @TimeKey INT, -- NITIN : 21 DEC 2010
	 @ModifiedBy varchar(20)-- shailesh 11/06/2014
	 ,@Result INT=0 OUTPUT
	)
AS
  BEGIN
	--Declare @TimeKey INT -- NITIN : 21 DEC 2010
    --SET @TimeKey =(SELECT  MonthKey  FROM    DimMonthMatrix  WHERE  CurrentStatus = 'C')    -- NITIN : 21 DEC 2010
	SET @TimeKey=(SELECT TimeKey FROM SysDataMatrix WHERE CurrentStatus='C')
	Declare @CurrentLoginDate Date

		Select @CurrentLoginDate= CurrentLoginDate from DimUserInfo where (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey >=@TimeKey) AND UserLoginID=@ModifiedBy

		--IF DATEDIFF(DAY,@CurrentLoginDate,GetDate()) <> 0
		--BEGIN
		--	PRINT -12
		--	SET @Result = -12
		--   return -12 --- User Login Date is prior. Data will not be Saved. Please Close the Application.
		--END   

    IF NOT EXISTS(SELECT 1 from DimUserInfo where UserLoginID =  @UserLoginID  AND (DimUserInfo.EffectiveFromTimeKey    < = @TimeKey   
	                 AND DimUserInfo.EffectiveToTimeKey  > = @TimeKey) AND SuspendedUser='Y'  )
			BEGIN
			ROLLBACK TRANSACTION
			SET @Result = -1
			RETURN -1
	        END
      ELSE
		   BEGIN
		   
		   UPDATE UserLoginHistory SET 
				LoginSucceeded='Y'
		   WHERE  UserID=@UserLoginID
		   AND LoginSucceeded='W' AND EntityKey=(SELECT MAX(EntityKey) FROM UserLoginHistory WHERE UserID=@UserLoginID AND LoginSucceeded='W')

		   UPDATE  DimUserInfo         
						SET
      					SuspendedUser='N',LoginPassword=@LoginPassword,
      					Activate='Y',--addded by Vivek
						CurrentLoginDate = GETDATE(),	-- Added By SATWAJI 04/02/2022 date changes
      					DateModified=GETDATE() ,
						PasswordChanged='Y',
						PasswordChangeDate=GETDATE()
						-- Added By Badri 28/08/2012 date changes
	 					WHERE UserLoginID=@UserLoginID AND
	 					(EffectiveFromTimeKey < = @TimeKey AND EffectiveToTimeKey  > = @TimeKey)
						SET @Result = 1
						RETURN 1
			END
    END



GO