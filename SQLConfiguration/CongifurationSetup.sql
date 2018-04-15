-- FILE: ConfigurationSetup.sql
-- Project: ASQL Project Milestone 1
-- Programmers: Manuel Poppe Richter and Humaira Siddiqa
-- Description: This script creates the Configuration Table in the Database, as well as create
-- their default values in the database using stored procedures which it also creates 

-- drop the database if it exists, then re-create it
DROP DATABASE IF EXISTS ASQLProject
CREATE DATABASE ASQLProject

-- using the ASQL Database
USE ASQLProject


-- dropping the tables one at a time, if they exist
DROP TABLE IF EXISTS Bin
DROP TABLE IF EXISTS Lamp

DROP TABLE IF EXISTS Tray
DROP TABLE IF EXISTS Station
DROP TABLE IF EXISTS SessionStatus
DROP TABLE IF EXISTS StationWorkerType
DROP TABLE IF EXISTS PartType

DROP TABLE IF EXISTS ConfigurationTable
DROP TABLE IF EXISTS Runner

-- *************************************** TABLE CREATION ***********************************************
-- *********************************************************************************************************


-- create the Configuration table.
-- this table will store all of the important configuration variables that
-- the C# simulators need to run


CREATE TABLE ConfigurationTable (
	ConfigurationID INT IDENTITY PRIMARY KEY, 
	ConfigurationSetting VARCHAR(20),
	ConfigurationValue INT,

)

-- create the StationWorkerTypeTable
CREATE TABLE StationWorkerType(
	StationWorkerTypeID INT IDENTITY PRIMARY KEY,
	WorkerDescription VARCHAR(30), 
	ErrorChance DECIMAL (5,4)
)

-- insert the standard workers into the table
INSERT INTO StationWorkerType(WorkerDescription, ErrorChance) 
VALUES ('Experienced', 0.15), ('New', 0.85), ('Normal', 0.5)




-- create the Station Table
CREATE TABLE Station (
	StationID INT IDENTITY PRIMARY KEY,
	StartTime DATETIME,
	ElapsedTime TIME,
	StationWorkerType INT,
	Active BIT,
	FOREIGN KEY (StationWorkerType) REFERENCES StationWorkerType (StationWorkerTypeID)
)

-- create the Tray table
CREATE TABLE Tray(
	TrayNumber INT IDENTITY PRIMARY KEY,
	TrayID VARCHAR(8), -- iN THE FORM FLxxxxxx  
	ID VARCHAR(10),
	CurrentLamps INT,
	StationID INT,
	FOREIGN KEY (StationID) REFERENCES Station(StationID)
)

-- create the part type table
CREATE TABLE PartType (
	PartTypeID INT IDENTITY PRIMARY KEY,
	PartDescription VARCHAR(20),
)


-- create the lamp table
CREATE TABLE Lamp (
	LampID VARCHAR(10) PRIMARY KEY,
	Passed BIT,
	TrayNumber INT,
	StationID INT,
	TimeCreated TIMESTAMP,
	FOREIGN KEY (TrayNumber) REFERENCES Tray (TrayNumber),
	FOREIGN KEY (StationID) REFERENCES Station (StationID)
)

-- create the Bin table
CREATE TABLE Bin (
	BinID INT IDENTITY PRIMARY KEY,
	StationID INT,
	PartTypeID INT,
	CurrentStock INT,
	CommonTray BIT,
	MaxCapacity INT,
	LastRefilled TIMESTAMP,
	FOREIGN KEY (StationID) REFERENCES Station (StationID),
	FOREIGN KEY (PartTypeID) REFERENCES PartTypes (PartTypeID)
)



-- *************************************** STORED PROCEDURES ***********************************************
-- *********************************************************************************************************



-- Name: SetDefaults
-- Description: This stored procedure sets the Configuration Table to have the default values
-- Inputs: None
-- Outputs: 0 if the configuration table was successfully obtained, 1 if an error occured

DROP PROCEDURE IF EXISTS SetDefaults
GO

CREATE PROCEDURE SetDefaults
	
AS
BEGIN

	SET NOCOUNT ON;
    SET XACT_ABORT ON; 

    DECLARE @FinalResult INT = 0 -- Variable to keep track of whether any errors occurred. If  it ever gets set to 1, we must rollback

	BEGIN TRY
        BEGIN TRANSACTION
            -- First, delete all the contents from the table
			DELETE FROM ConfigurationTable 
			WHERE ConfigurationID > 0;

			-- now, add the default values of the scale and bin container capacities to the table

			INSERT INTO ConfigurationTable (ConfigurationSetting, ConfigurationValue) 
			VALUES ('TimeScale', 10),
			('HarnessCapacity', 55),
			('RefelectorCapacity', 35),
			('HousingCapacity', 24),
			('Lens', 40),
			('BulbCapacity', 60),
			('BezelCapacity', 75)

			-- we delete the part types table and set the default values 
			DELETE FROM PartType
			WHERE PartTypeID > 0;

			-- insert all the default values into PartTypes
			INSERT INTO PartType (PartDescription)
			VALUES ('Harness'),
			('Reflector'), 
			('Housing'), 
			('Lens'),
			('Bulb'),
			('Bezel')
        -- no errors, let us commit the transaction
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        -- An exception has occured
        SET @FinalResult = 1

        IF @@TRANCOUNT > 0 ROLLBACK 

    END CATCH

	-- output the final success/error message
    RETURN @FinalResult
END
GO

-- checks that the stored procedure was executed successfully. 
-- A 0 means all is well, a 1 means that the stored procedure encountered an error
DECLARE @Result INT
EXEC @Result = SetDefaults
SELECT @Result

-- Name: ChangeSetting 
-- Description: This will change the setting of the stored procedure that was specified
-- Inputs:
-- Name: Varchar(30): name of the stored configuration setting to change 
-- Value: Int: The new value of the stored configuration setting
-- Outputs:
-- Return Value: int, 0 if everything was set properly, 1 if something went wrong

DROP PROCEDURE IF EXISTS ChangeSetting
GO

CREATE PROCEDURE ChangeSetting
	@Name VARCHAR(20), -- the name of the setting we are trying to change 
	@Value INT -- The value we want to change the setting to
AS
BEGIN

	SET NOCOUNT ON;
    SET XACT_ABORT ON; 

    DECLARE @FinalResult INT = 0 -- Variable to keep track of whether any errors occurred. If  it ever gets set to 1, we must rollback
	

	-- make sure the user wants to set the value to something that is acceptable 

	IF NOT EXISTS (SELECT 1 FROM ConfigurationTable WHERE ConfigurationSetting=@Name)
		SET @FinalResult = 1
	ELSE
		BEGIN TRY	

			-- Now, check that the value the user chose is greater than 1
			IF (@Value > 0)
				BEGIN
				-- attempt to update the value that was specified
				UPDATE ConfigurationTable 
				SET ConfigurationValue=@Value
				WHERE ConfigurationSetting=@Name 			
				-- set the result to pass
				SET @FinalResult = 0
				END
			ELSE
				-- the user has picked a bad value
				SET @FinalResult = 1
		END TRY
		BEGIN CATCH
			-- something went wrong, probably the user selected a setting that doesn't exist
			SET @FinalResult = 1
		END CATCH
		

	-- output the final success/error message
    SELECT @FinalResult
END
GO

-- Name: RunerUpdate
-- Description: This stored proedure simulates the runner filling up every bin that needs filling
-- Inputs: None
-- Outputs: None

DROP PROCEDURE IF EXISTS RunnerUpdate
GO

CREATE PROCEDURE RunnerUpdate
	
AS
BEGIN

	SET NOCOUNT ON;
    SET XACT_ABORT ON; 

    DECLARE @FinalResult INT = 0 -- Variable to keep track of whether any errors occurred. If  it ever gets set to 1, we must rollback

	BEGIN TRY	

		-- Update all the Station Bins that have 5 or less parts
		UPDATE BIN 
		SET CurrentStock = (CurrentStock + MaxCapacity)
		WHERE
		CurrentStock <= 5

	END TRY
	BEGIN CATCH
		-- something went wrong
		IF @@TRANCOUNT > 0 ROLLBACK 
		SET @FinalResult = 1
	END CATCH
		

	-- output the final success/error message
    SELECT @FinalResult
END
GO


