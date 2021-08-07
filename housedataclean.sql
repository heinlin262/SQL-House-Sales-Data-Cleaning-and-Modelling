
-- Cleaning Data in SQL Queries

--Check all the data types in the table

SELECT COLUMN_NAME,
       DATA_TYPE,
       IS_NULLABLE,
       CHARACTER_MAXIMUM_LENGTH,
       NUMERIC_PRECISION,
       NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='house';

SELECT * FROM house;

-- Standardize Date Format

ALTER TABLE house
ALTER COLUMN SaleDate DATE;

-- Populate Property Address Data
    
SELECT * 
FROM house
WHERE PropertyAddress IS NULL;

SELECT *
FROM house
ORDER BY ParcelID, PropertyAddress;

-- Check why they are null and what the null propertyaddress has in common

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM house AS a JOIN house AS b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

-- Replace those nulls in propertyaddress with the propertyaddress which has the same parcelID
-- Because they all have the same information except UniqueID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM house AS a JOIN house AS b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM house AS a JOIN house AS b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

--Splitting Addresses into Individual Columns (Address, City, State)

SELECT * FROM house;

SELECT PropertyAddress FROM house;

SElECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1) AS PropertySplitAddress,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) AS PropertySplitCity
FROM house;

ALTER TABLE house
ADD	PropertySplitAddress VARCHAR(250),
	PropertySplitCity VARCHAR(250);

UPDATE house
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress));

SELECT * FROM house;

SELECT OwnerAddress FROM house;

SELECT PARSENAME(REPLACE(OwnerAddress,',','.'),3) AS OwnerSplitAddress,
		PARSENAME(REPLACE(OwnerAddress,',','.'),2) AS OwnerSplitCity,
		PARSENAME(REPLACE(OwnerAddress,',','.'),1) AS OwnerSplitState
FROM house;

ALTER TABLE house
ADD OwnerSplitAddress VARCHAR(250),
    OwnerSplitCity VARCHAR(250),
    OwnerSplitState VARCHAR(250);

UPDATE house
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);

SELECT * FROM house;

ALTER TABLE house
DROP COLUMN OwnerSplitAddress, OwnerSplitCity, OwnerSplitState;

--Cleaning and Replacing only Yes and No in SoldAsVacant

SELECT DISTINCT(SoldAsVacant)
FROM house;

SELECT SoldAsVacant,
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
			 ElSE SoldAsVacant
		END
FROM house;

UPDATE house
SET SoldAsVacant =
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
			 ElSE SoldAsVacant
		END;

SELECT DISTINCT(SoldAsVacant)
FROM house;

--Removes Duplicates

SELECT *
FROM house;

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
			     PropertyAddress,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID
					) AS row_num
FROM house)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;


WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
			     PropertyAddress,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID
					) AS row_num
FROM house)
DELETE
FROM RowNumCTE
WHERE row_num > 1;

--Dividing the SaleDate into Year, Month and WeekDay

SELECT YEAR(SaleDate),  DATENAME(MM,SaleDate), DATENAME(WEEKDAY,SaleDate)
FROM house;

ALTER TABLE house
ADD SaleYear INT,
	SaleMonth VARCHAR(10),
	SaleWeekDay VARCHAR(10);

UPDATE house
SET SaleYear = YEAR(SaleDate),
	SaleMonth = DATENAME(MM,SaleDate),
	SaleWeekDay = DATENAME(WEEKDAY,SaleDate);

SELECT * FROM house;

--Creating Data Model

SELECT UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, LegalReference, SoldAsVacant, OwnerAddress, Acreage, 
		TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath
INTO Fact_House
FROM house;

SELECT * FROM Fact_House;

SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
INTO Dim_Property
FROM house;

SELECT * FROM Dim_Property;

SELECT OwnerAddress, OwnerName, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
INTO Dim_Owner
FROM house;

SELECT * FROM Dim_Owner;

SELECT SaleDate, SaleMonth, SaleWeekDay, SaleYear
INTO Dim_SaleDate
FROM house;

SELECT * FROM Dim_SaleDate;

--Removes Duplicates in Dimension Tables

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY PropertyAddress, PropertySplitAddress, PropertySplitCity
				 ORDER BY
					PropertyAddress
					) AS row_num
FROM Dim_Property)
DELETE
FROM RowNumCTE
WHERE row_num > 1;



WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY OwnerAddress, OwnerName, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
				 ORDER BY
					OwnerAddress
					) AS row_num
FROM Dim_Owner)
DELETE
FROM RowNumCTE
WHERE row_num > 1;


WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY SaleDate, SaleMonth, SaleWeekDay, SaleYear
				 ORDER BY
					SaleDate
					) AS row_num
FROM Dim_SaleDate)
DELETE
FROM RowNumCTE
WHERE row_num > 1;






