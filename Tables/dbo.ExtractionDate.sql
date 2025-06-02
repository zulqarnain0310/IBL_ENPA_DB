CREATE TABLE [dbo].[ExtractionDate] (
  [ID] [int] NULL,
  [STR_DATE] [date] NULL,
  [END_DATE] [date] NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [ExtractionType] [char](1) NULL
)
ON [PRIMARY]
GO