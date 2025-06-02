CREATE TABLE [dbo].[CheckSumData_RF_23102024] (
  [EntityID] [int] IDENTITY,
  [AS_ON_DATE] [date] NULL,
  [Timekey] [int] NULL,
  [SourceName] [nvarchar](50) NULL,
  [SourceAlt_Key] [int] NULL,
  [RecordCount] [int] NULL,
  [RF_Type] [varchar](10) NULL,
  [CRISMAC_CheckSum] [nvarchar](100) NULL,
  [Datecreated] [datetime] NULL
)
ON [PRIMARY]
GO