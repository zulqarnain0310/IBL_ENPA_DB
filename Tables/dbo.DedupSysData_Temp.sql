CREATE TABLE [dbo].[DedupSysData_Temp] (
  [EntityKey] [int] IDENTITY,
  [NCIF] [int] NULL,
  [SrcAppAlt_Key] [smallint] NULL,
  [SrcAppCustomerID] [varchar](20) NULL,
  [PAN] [varchar](10) MASKED WITH (FUNCTION = 'default()') NULL
)
ON [PRIMARY]
GO