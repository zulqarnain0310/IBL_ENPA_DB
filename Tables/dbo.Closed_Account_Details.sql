CREATE TABLE [dbo].[Closed_Account_Details] (
  [ASONDATE] [date] NULL,
  [SrcSysAlt_Key] [smallint] NULL,
  [NCIF_ID] [varchar](100) NULL,
  [CustomerId] [varchar](20) NULL,
  [CustomerACID] [varchar](20) MASKED WITH (FUNCTION = 'default()') NULL,
  [CustomerName] [varchar](500) NULL,
  [AC_Closed_Date] [date] NULL
)
ON [PRIMARY]
GO