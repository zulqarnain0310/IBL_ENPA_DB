CREATE TABLE [dbo].[HIST_STD_ASSET_CAT] (
  [Date_of_Change] [datetime] NOT NULL,
  [DateCreated] [smalldatetime] NULL,
  [NCIF_Id] [varchar](100) NULL,
  [CustomerId] [varchar](50) NULL,
  [CustomerACID] [varchar](50) NULL,
  [Balance] [decimal](16, 2) NULL,
  [PrevSTD_ASSET_CAT_Alt_key] [smallint] NULL,
  [CurSTD_ASSET_CAT_Alt_key] [smallint] NULL,
  [MOC_status] [varchar](5) NULL,
  [SOURCENAME] [varchar](100) NULL
)
ON [PRIMARY]
GO