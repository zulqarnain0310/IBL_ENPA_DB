CREATE TABLE [dbo].[Upload_RestructureGapData] (
  [SlNo] [varchar](30) NULL,
  [NCIF_ID] [varchar](30) NULL,
  [2ndRestructuringDate] [varchar](10) NULL,
  [AggregateExposure] [varchar](100) NULL,
  [CreditRating1] [varchar](10) NULL,
  [CreditRating2] [varchar](10) NULL,
  [filname] [varchar](100) NULL,
  [ErrorMessage] [varchar](max) NULL,
  [ErrorinColumn] [varchar](max) NULL,
  [Srnooferroneousrows] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO