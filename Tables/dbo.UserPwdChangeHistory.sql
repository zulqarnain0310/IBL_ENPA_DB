CREATE TABLE [dbo].[UserPwdChangeHistory] (
  [EntityKey] [smallint] IDENTITY,
  [SeqNo] [smallint] NULL,
  [UserLoginID] [varchar](50) NULL,
  [LoginPassword] [varchar](max) NULL,
  [PwdChangeTime] [date] NULL,
  [DateCreated] [smalldatetime] NULL,
  [CreatedBy] [varchar](20) NULL,
  [Status] [bit] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO