CREATE TABLE [dbo].[DimAlertMessage] (
  [EntityKey] [int] IDENTITY,
  [AlertMessageAlt_key] [int] NOT NULL,
  [MessageFor] [varchar](50) NULL,
  [Location] [varchar](50) NULL,
  [FromDate] [date] NULL,
  [ToDate] [date] NULL,
  [Active] [char](1) NULL,
  [MessageDesc] [nvarchar](500) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifyBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp],
  [LocationListAlt_key] [varchar](200) NULL,
  [UserLocationAlt_Key] [int] NULL
)
ON [PRIMARY]
GO