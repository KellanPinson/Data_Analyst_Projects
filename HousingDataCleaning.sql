

--View The Data
SELECT * FROM PortfolioProjects.dbo.NashvilleHousing


-- Standardize Date Format


Select SaleDate FROM PortfolioProjects.dbo.NashvilleHousing


ALTER TABLE PortfolioProjects.dbo.NashvilleHousing ALTER COLUMN SaleDate DATE


-- Return All Rows that have a Null Value to determine what to do about them
SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing
WHERE  [UniqueID] IS NULL
   OR [ParcelID] IS NULL
   OR [LandUse] IS NULL
   OR [PropertyAddress] IS NULL
   OR [SaleDate] IS NULL
   OR [SalePrice] IS NULL
   OR [LegalReference] IS NULL
   OR [SoldAsVacant] IS NULL
   OR [OwnerName] IS NULL
   OR [OwnerAddress] IS NULL
   OR [Acreage] IS NULL
   OR [TaxDistrict] IS NULL
   OR [LandValue] IS NULL
   OR [BuildingValue] IS NULL
   OR [TotalValue] IS NULL
   OR [YearBuilt] IS NULL
   OR [Bedrooms] IS NULL
   OR [FullBath] IS NULL
   OR [HalfBath] IS NULL;



  -- IF THEY HAVE SAME PARCEL ID, MOST LIKELY SAME OWNERNAME AND OWNERADDRESS
   SELECT ParcelID, PropertyAddress, OwnerName, OwnerAddress FROM PortfolioProjects.dbo.NashvilleHousing ORDER BY ParcelID


-- POPULATE PROPERTY ADDRESS DATA

SELECT original.ParcelID, original.PropertyAddress, new.ParcelID, new.PropertyAddress, ISNULL(original.PropertyAddress, new.PropertyAddress)
FROM PortfolioProjects.dbo.NashvilleHousing original
JOIN PortfolioProjects.dbo.NashvilleHousing new
ON original.ParcelID = new.ParcelID
AND original.[UniqueID ] <> new.[UniqueID ]
WHERE original.PropertyAddress IS NULL



UPDATE original
SET original.PropertyAddress = ISNULL(original.PropertyAddress, new.PropertyAddress)
FROM PortfolioProjects.dbo.NashvilleHousing original
JOIN PortfolioProjects.dbo.NashvilleHousing new
ON original.ParcelID = new.ParcelID
AND original.[UniqueID ] <> new.[UniqueID ]
WHERE original.PropertyAddress IS NULL



-- Seperate into Address, City, State, enables further analysis
-- NOTE that CHARINDEX(',', PropertyAddress) Simply returns a number, so you can change the position with -1
SELECT * FROM PortfolioProjects.dbo.NashvilleHousing


SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProjects.dbo.NashvilleHousing


-- ADD two new columns and populate them
ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
ADD SplitPropertyAddress NVARCHAR(255),
    SplitPropertyCity NVARCHAR(255);


UPDATE PortfolioProjects.dbo.NashvilleHousing
SET SplitPropertyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
	SplitPropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))



	-- Do the same thing for Owner Address Using Parsename

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',','.'),3) AS OwnerSplitAddress,
PARSENAME(REPLACE(OwnerAddress, ',','.'),2) AS OwnerSplitCity,
PARSENAME(REPLACE(OwnerAddress, ',','.'),1) AS OwnerSplitState
FROM PortfolioProjects.dbo.NashvilleHousing


ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255);


UPDATE PortfolioProjects.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)


-- Want to Have consistent columns, rename to "Yes" or "No"
SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProjects.dbo.NashvilleHousing
GROUP BY SoldAsVacant


SELECT SoldAsVacant, 
CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
	Else SoldAsVacant
	END 
	AS CorrectedVacant
FROM PortfolioProjects.dbo.NashvilleHousing


UPDATE PortfolioProjects.dbo.NashvilleHousing
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
	Else SoldAsVacant
	END 



	-- Check for duplicates
	-- Duplicates Found, Time To delete them
WITH NumberedRows AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY [ParcelID], [LandUse], [PropertyAddress], [SaleDate], [SalePrice], 
                                      [LegalReference], [SoldAsVacant], [OwnerName], [OwnerAddress], [Acreage], 
                                      [TaxDistrict], [LandValue], [BuildingValue], [TotalValue], [YearBuilt], 
                                      [Bedrooms], [FullBath], [HalfBath]
                             ORDER BY (SELECT NULL)) AS RowNum
    FROM PortfolioProjects.dbo.NashvilleHousing
)

DELETE
FROM NumberedRows
WHERE RowNum > 1


