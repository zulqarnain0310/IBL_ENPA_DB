CREATE TABLE [dbo].[Reversefeed_check] (
  [Source_System] [varchar](50) NULL,
  [NCIF] [varchar](100) NULL,
  [CLient_ID] [varchar](20) NULL,
  [Account_Number] [varchar](20) NULL,
  [SourceAssetClass] [smallint] NULL,
  [SourceNPA_Date] [date] NULL,
  [SourceAsset_Class_Name] [varchar](20) NULL,
  [Reverse_NPA_Date_Final] [date] NULL,
  [Reverse_AssetClass] [smallint] NULL,
  [Reverse_Asset_Class_Name] [varchar](20) NULL
)
ON [PRIMARY]
GO