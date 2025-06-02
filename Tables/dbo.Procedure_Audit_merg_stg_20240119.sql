CREATE TABLE [dbo].[Procedure_Audit_merg_stg_20240119] (
  [EXT_DATE] [date] NULL,
  [Timekey] [int] NULL,
  [SP_Name] [varchar](100) NULL,
  [Start_Date_Time] [datetime] NULL,
  [End_Date_Time] [datetime] NULL,
  [Audit_Flg] [smallint] NULL,
  [TimeDuration_Min] [int] NULL,
  [ERROR_MESSAGE] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO