CREATE TABLE [dbo].[HeaderTable_06052023] (
  [EntityID] [int] IDENTITY,
  [Source] [varchar](50) NULL,
  [Table_Name] [varchar](50) NULL,
  [AS_ON_DATE] [date] NULL,
  [GENRN_TIME_STAMP] [datetime] NULL,
  [BATCH_ID] [varchar](50) NULL,
  [COUNT_REC] [int] NULL,
  [D2K_EXTRCTN_STATUS] [int] NULL,
  [D2K_EXTRCTN_START_TIME] [datetime] NULL,
  [D2K_EXTRCTN_END_TIME] [datetime] NULL
)
ON [PRIMARY]
GO