CREATE TABLE [dbo].[UserLoginHistory] (
  [EntityKey] [int] IDENTITY,
  [UserID] [varchar](20) NULL,
  [IP_Address] [varchar](50) NULL,
  [LoginTime] [datetime] NULL,
  [LogoutTime] [datetime] NULL,
  [DurationMin] [smallint] NULL,
  [LoginSucceeded] [char](1) NULL,
  [BranchCode] [varchar](10) NULL
)
ON [PRIMARY]
GO