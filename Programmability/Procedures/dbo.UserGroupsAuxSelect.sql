SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
--- exec [UserGroupsAuxSelect] 2922
CREATE PROCEDURE [dbo].[UserGroupsAuxSelect]
	@timekey INT
AS
BEGIN
	----SELECT EntityKey,DeptGroupId,REPLACE(DeptGroupCode,'#','') AS DeptGroupName,DeptGroupName AS DeptGroupDesc,Menus,DateCreated,EffectiveFromTimeKey,EffectiveToTimeKey 
	----FROM DimUserDeptGroup
	----WHERE EffectiveFromTimeKey <=3652 and EffectiveToTimeKey>=3652


	IF OBJECT_ID('Tempdb..#TmpGroupDtl') IS NOT NULL
		DROP TABLE #TmpGroupDtl

SELECT EntityKey,DeptGroupId,REPLACE(DeptGroupCode,'#','') AS DeptGroupName,DeptGroupName AS DeptGroupDesc,Menus,DateCreated,EffectiveFromTimeKey,EffectiveToTimeKey 
		INTO #TmpGroupDtl	
	FROM DimUserDeptGroup
	WHERE EffectiveFromTimeKey <=@timekey and EffectiveToTimeKey>=@timekey

	
	IF OBJECT_ID('Tempdb..#TmpGroupMenuParent') IS NOT NULL
			DROP TABLE #TmpGroupMenuParent


		SELECT DeptGroupId,	B.ParentId 
			INTO #TmpGroupMenuParent		
		FROM  (
					SELECT DeptGroupId,	DeptGroupName,	DeptGroupDesc, --,B.ParentId,
								Split.a.value('.', 'VARCHAR(100)') AS Menus  
				
					FROM  (SELECT DeptGroupId,	DeptGroupName,	DeptGroupDesc,
							CAST ('<M>' + REPLACE(Menus, ',', '</M><M>') + '</M>' AS XML) AS Menus  
							FROM  #TmpGroupDtl 
						) AS A CROSS APPLY Menus.nodes ('/M') AS Split(a) 
				) A
		INNER JOIN SysCRisMacMenu B
					ON CAST(A.Menus AS INT)=B.MenuId
		GROUP BY  DeptGroupId,	B.ParentId 

	--SELECT * FROM #TmpGroupMenuParent

	SELECT EntityKey ,T.DeptGroupId, DeptGroupName,DeptGroupDesc,Menus+'|'+ParentID As Menus , 'Y' IsMainTable
	,	DateCreated,EffectiveFromTimeKey, EffectiveToTimeKey--, ParentID
	FROM 
		#TmpGroupDtl T
	LEFT JOIN (
				select DeptGroupId,ParentID
					from(
							SELECT DeptGroupId,
										STUFF((SELECT ',' +CAST(ParentId AS VARCHAR(10)) 
									FROM #TmpGroupMenuParent M1
											WHERE M2.DeptGroupId = M1.DeptGroupId
									FOR XML PATH('')),1,1,'')  AS ParentID
									FROM #TmpGroupMenuParent M2
						) B
						group by DeptGroupId,ParentID
				)B
			ON T.DeptGroupId=B.DeptGroupId




END



GO