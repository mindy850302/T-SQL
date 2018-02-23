--Lab_SQL_1 請列出每個銷售員每年訂單數量，並依員編及年度做排序。
SELECT HE.EmployeeID as [empid] , HE.FirstName as [firstname] , HE.LastName as [lastname] , YEAR(SO.OrderDate) as [orderyear] , COUNT(OrderID) as ordercnt
FROM Sales.Orders as SO  
		INNER JOIN HR.Employees as HE
		ON SO.EmployeeID = HE.EmployeeID
GROUP BY HE.EmployeeID, HE.FirstName,HE.LastName ,YEAR(SO.OrderDate)
ORDER BY empid , firstname , lastname , orderyear ; --依員編及年度排序

--Lab_SQL_2 列出最受歡迎產品前五名(銷售數量最多前五名)
SELECT TOP(5) PP.ProductID , PP.ProductName , SUM(SOD.Qty) as qty
FROM Sales.Orders as SO 
	INNER JOIN Sales.OrderDetails as SOD
	ON SO.OrderID = SOD.OrderID
	INNER JOIN Production.Products as PP
	ON SOD.ProductID = PP.ProductID
GROUP BY PP.ProductID , PP.ProductName 
ORDER BY SUM(SOD.Qty) DESC;

--Lab_SQL_3 以10歲為間隔列出每個年齡層員工人數
SELECT Level_Age,count(old) as 人數 
FROM(SELECT old, 
			CASE 
				WHEN old BETWEEN 30 AND 39 THEN '30-39' 
				WHEN old BETWEEN 40 AND 49 THEN '40-49' 
				WHEN old BETWEEN 50 AND 59 THEN '50-59' 
				WHEN old BETWEEN 60 AND 69 THEN '60-69' 
				WHEN old BETWEEN 70 AND 79 THEN '70-79' 
			END AS 'Level_Age' 
	FROM (select DATEDIFF ( Year , Birthdate , getdate()) as old from HR.Employees) as T1 
) as T2 group by Level_Age;

--Lab_SQL_4 撈出每個國家銷售數量前3名的員工及數量 Sales.Orders、HR.Employees
;WITH salesReport as(
	SELECT SO.ShipCountry,HE.EmployeeID,HE.FirstName,HE.LastName,COUNT(SO.OrderID) AS cnt ,ROW_NUMBER ( ) OVER(PARTITION BY SO.ShipCountry ORDER BY COUNT(SO.OrderID) DESC) as seq
	FROM Sales.Orders as SO
		INNER JOIN HR.Employees as HE
		ON SO.EmployeeID = HE.EmployeeID
	GROUP BY SO.ShipCountry,HE.EmployeeID,HE.FirstName,HE.LastName
)
SELECT seq ,ShipCountry,EmployeeID,FirstName,LastName,cnt
FROM salesReport
WHERE seq < 4
ORDER BY ShipCountry,cnt DESC,EmployeeID,FirstName,LastName;

--Lab_SQL_5 請列出2006,2007,2008 員工銷售數字比較 Sales.Orders、HR.Employees
;WITH salesReport1 as(
SELECT HE.EmployeeID,HE.FirstName,HE.LastName, YEAR(SO.OrderDate) as orderyear , COUNT(YEAR(SO.OrderDate)) as totalSales
FROM Sales.Orders as SO
		INNER JOIN HR.Employees as HE
		ON SO.EmployeeID = HE.EmployeeID
GROUP BY HE.EmployeeID,HE.FirstName,HE.LastName,YEAR(SO.OrderDate)
--ORDER BY HE.EmployeeID,HE.FirstName,HE.LastName,YEAR(SO.OrderDate)
)
SELECT DISTINCT EmployeeID,FirstName,LastName
, ISNULL((SELECT totalSales FROM salesReport1 WHERE a.EmployeeID = salesReport1.EmployeeID and orderyear = 2006),0) as [CNT2006] 
, ISNULL((SELECT totalSales FROM salesReport1 WHERE a.EmployeeID = salesReport1.EmployeeID and orderyear = 2007),0) as [CNT2007] 
, ISNULL((SELECT totalSales FROM salesReport1 WHERE a.EmployeeID = salesReport1.EmployeeID and orderyear = 2008),0) as [CNT2008] 
FROM salesReport1 as a
ORDER BY EmployeeID,FirstName,LastName;

--Lab_SQL_6 請列出2006,2007,2008 員工銷售數字比較 Sales.Orders、HR.Employees use pivot
SELECT EmployeeID,FirstName,LastName,[2006] as [CNT2006],[2007] as [CNT2007],[2008]as [CNT2008]
FROM 
	(SELECT HE.EmployeeID,HE.FirstName,HE.LastName, YEAR(SO.OrderDate) as orderyear , COUNT(YEAR(SO.OrderDate)) as totalSales
	FROM Sales.Orders as SO
			INNER JOIN HR.Employees as HE
			ON SO.EmployeeID = HE.EmployeeID
	GROUP BY HE.EmployeeID,HE.FirstName,HE.LastName,YEAR(SO.OrderDate) 
) as D
PIVOT(SUM(totalSales) FOR orderyear IN ([2006],[2007],[2008])) as pvt;

--Lab_SQL_7 請列出2006,2007,2008 員工銷售數字比較 Sales.Orders、HR.Employees use pivot and dynamic

--Lab_SQL_8 請查詢出訂單編號為11070的明細資料，其中包含訂單代號、訂購日期(yyyy/mm/dd)、需要日期(yyyy/mm/dd)、公司名稱(id-name)、管理員(名 姓)、商品(id-name)、原價、數量、小計 Sales.Orders、Sales.OrderDetails、Sales.Customers、Production.Products
DECLARE @OrderID INT = 11070;
--DECLARE @Company NVARCHAR(200);
--SELECT @Company = COALESCE( @Company+'-'+ CompanyName,CustomerID)
--FROM Sales.Customers as SC;
--INNER JOIN Sales.Orders as SO
--ON SO.CustomerID = SC.CustomerID;

SELECT SO.OrderID as '訂單代號',convert(varchar, SO.OrderDate, 111) as '訂購日期',convert(varchar, SO.RequiredDate, 111) as '需要日期',CONCAT(SC.CustomerID,'-',SC.CompanyName) as '公司名稱',CONCAT(HE.FirstName,' ',HE.LastName) as '管理員',CONCAT(PP.ProductID,'-',PP.ProductName) '商品',PP.UnitPrice as '原價',SOD.Qty as '數量', PP.UnitPrice*SOD.Qty as '小計'
FROM Sales.Orders as SO
INNER JOIN  Sales.OrderDetails as SOD
ON SO.OrderID = SOD.OrderID
INNER JOIN  Sales.Customers as SC
ON SO.CustomerID = SC.CustomerID
INNER JOIN  Production.Products as PP
ON SOD.ProductID = PP.ProductID
INNER JOIN  Production.Suppliers as PS
ON PP.SupplierID = PS.SupplierID
INNER JOIN  HR.Employees as HE
ON SO.EmployeeID = HE.EmployeeID
WHERE SO.OrderID=@OrderID;

--Lab_SQL_9 於11070訂單新增產品代號為38的商品,數量2個,沒有折扣,並修改需要日期為2008/10/10

USE [TSQL2012];
GO

DECLARE @OrderID INT = 11070;
DECLARE @ProductID INT = 38;
DECLARE @Price INT;
DECLARE @Qty INT = 2;
DECLARE @Discount NUMERIC = 0;

SELECT @Price=PP.UnitPrice
FROM Production.Products as PP
WHERE PP.ProductID = @ProductID;

BEGIN TRY
	INSERT INTO [Sales].[OrderDetails]([OrderID],[ProductID],[UnitPrice],[Qty],[Discount])
		 VALUES (@OrderID,@ProductID,@Price,@Qty,@Discount)
END TRY
BEGIN CATCH 
	SELECT ERROR_NUMBER()
END CATCH;

SELECT SO.OrderID as '訂單代號',convert(varchar, SO.OrderDate, 111) as '訂購日期',convert(varchar, SO.RequiredDate, 111) as '需要日期',CONCAT(SC.CustomerID,'-',SC.CompanyName) as '公司名稱',CONCAT(HE.FirstName,' ',HE.LastName) as '管理員',CONCAT(PP.ProductID,'-',PP.ProductName) '商品',PP.UnitPrice as '原價',SOD.Qty as '數量', PP.UnitPrice*SOD.Qty as '小計'
FROM Sales.Orders as SO
INNER JOIN  Sales.OrderDetails as SOD
ON SO.OrderID = SOD.OrderID
INNER JOIN  Sales.Customers as SC
ON SO.CustomerID = SC.CustomerID
INNER JOIN  Production.Products as PP
ON SOD.ProductID = PP.ProductID
INNER JOIN  Production.Suppliers as PS
ON PP.SupplierID = PS.SupplierID
INNER JOIN  HR.Employees as HE
ON SO.EmployeeID = HE.EmployeeID
WHERE SO.OrderID=@OrderID;

GO

--Lab_SQL_10 請將題9新增的商品(商品代號=38)刪除
USE [TSQL2012]
GO
DECLARE @OrderID INT = 11070;
DECLARE @ProductID INT = 38;
DELETE FROM Sales.OrderDetails 
      WHERE Sales.OrderDetails.OrderID = @OrderID 
	  AND Sales.OrderDetails.ProductID = @ProductID;

--印出資料表
SELECT SO.OrderID as '訂單代號',convert(varchar, SO.OrderDate, 111) as '訂購日期',convert(varchar, SO.RequiredDate, 111) as '需要日期',CONCAT(SC.CustomerID,'-',SC.CompanyName) as '公司名稱',CONCAT(HE.FirstName,' ',HE.LastName) as '管理員',CONCAT(PP.ProductID,'-',PP.ProductName) '商品',PP.UnitPrice as '原價',SOD.Qty as '數量', PP.UnitPrice*SOD.Qty as '小計'
FROM Sales.Orders as SO
INNER JOIN  Sales.OrderDetails as SOD
ON SO.OrderID = SOD.OrderID
INNER JOIN  Sales.Customers as SC
ON SO.CustomerID = SC.CustomerID
INNER JOIN  Production.Products as PP
ON SOD.ProductID = PP.ProductID
INNER JOIN  Production.Suppliers as PS
ON PP.SupplierID = PS.SupplierID
INNER JOIN  HR.Employees as HE
ON SO.EmployeeID = HE.EmployeeID
WHERE SO.OrderID=@OrderID;
GO



