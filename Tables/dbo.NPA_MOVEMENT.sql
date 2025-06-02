CREATE TABLE [dbo].[NPA_MOVEMENT] (
  [SR_NO] [varchar](5) NULL,
  [PARTICULARS] [varchar](200) NULL,
  [STANDARD] [decimal](36, 4) NULL,
  [SUB_STANDARD] [decimal](36, 4) NULL,
  [DOUBTFUL1] [decimal](36, 4) NULL,
  [DOUBTFUL2] [decimal](36, 4) NULL,
  [DOUBTFUL3] [decimal](36, 4) NULL,
  [LOSS] [decimal](36, 4) NULL,
  [TOTAL_NON_PERFORMING] [decimal](36, 4) NULL,
  [TOTAL] [varchar](200) NULL
)
ON [PRIMARY]
GO