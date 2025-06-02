SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
 create Proc [dbo].[AadharData]  @Pan varchar(20)
 as
 select * from AADHAR_VOTER_NPADUPE_DAILY_DATA
 where PAN=@pan
GO