CREATE TABLE [dbo].[SPAuditCheck] (
  [Ext_Date] [date] NULL,
  [ID] [int] NULL,
  [SPName] [varchar](200) NULL,
  [StepName] [varchar](200) NULL,
  [StartTime] [datetime] NULL,
  [EndTime] [datetime] NULL,
  [ISsucess] [char](1) NULL
)
ON [PRIMARY]
GO