SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE proc [dbo].[TDA_Account_Delete]
as
Begin
delete FROM Induslnd_Stg.dbo.Finacle_Stg where SCHEME_TYPE='TDA' AND cast(TOTAL_OUTSTANDING as decimal(20,2))<0
END
GO