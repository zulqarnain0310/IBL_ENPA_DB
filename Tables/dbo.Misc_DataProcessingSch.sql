CREATE TABLE [dbo].[Misc_DataProcessingSch] (
  [ID] [int] IDENTITY,
  [Description] [varchar](250) NULL,
  [TimeTaken] [datetime] NULL,
  [NoofRowsAffected] [int] NULL,
  [TimeKey] [int] NULL,
  [SetID] [int] NULL,
  PRIMARY KEY CLUSTERED ([ID]) WITH (FILLFACTOR = 90)
)
ON [PRIMARY]
GO