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
	TimeCreated DATETIME,
	FOREIGN KEY (TrayNumber) REFERENCES Tray (TrayNumber)
)

-- create the Bin table
CREATE TABLE Bin (
	BinID INT IDENTITY PRIMARY KEY,
	StationID INT,
	PartTypeID INT,
	CurrentStock INT,
	MaxCapacity INT,
	LastRefilled TIMESTAMP,
	FOREIGN KEY (StationID) REFERENCES Station (StationID),
	FOREIGN KEY (PartTypeID) REFERENCES PartType (PartTypeID)
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
			('BezelCapacity', 75),
			('RunnerTime', 5)

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
		UPDATE Bin
		SET CurrentStock = (CurrentStock + MaxCapacity)
		FROM Bin
		INNER JOIN Station 
		ON Station.StationID = Bin.StationID
		WHERE CurrentStock <= 5 AND Active = 1



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


-- Name: NewStation 
-- Description: This creates a new station, along with the bins needed for it
-- Inputs: workerType: Int : the type of wroker that is running this station
-- Outputs: A table with the configuration settings and the ID of the workstation

DROP PROCEDURE IF EXISTS NewStation
GO

CREATE PROCEDURE NewStation
	@WorkerType INT
AS
BEGIN

	SET NOCOUNT ON;
    SET XACT_ABORT ON; 


	DECLARE @StationID INT
	DECLARE @FinalResult INT = 0
	DECLARE @TrayID INT = 0
	


	BEGIN TRY	
		BEGIN TRANSACTION

		-- attempt to insert the station into the database
		INSERT INTO Station(StartTime,StationWorkerType, Active)
		VALUES (GETDATE(), @WorkerType, 1)

		-- get the SationID 
		--SELECT @StationID = MAX(StationID) FROM Station
		SET @StationID = SCOPE_IDENTITY()

		-- now, we have to create the 6 bins for the station
		INSERT INTO Bin(StationID, PartTypeID, CurrentStock, MaxCapacity)
		VALUES (@StationID, 1, (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=2), (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=2)),
		(@StationID, 2, (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=3), (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=3)),
		(@StationID, 3, (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=4), (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=4)),
		(@StationID, 4, (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=5), (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=5)),
		(@StationID, 5, (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=6), (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=6)),
		(@StationID, 6, (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=7),  (SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationID=7))

		
		-- create a tray for that station
		INSERT INTO Tray (StationID)
		VALUES (@StationID)

		-- find the ID of the tray we just inserted
		SET @TrayID = SCOPE_IDENTITY()
		
		

		-- update that tray to have a unique trayID
		UPDATE Tray 
		SET TrayID = ('FL' + RIGHT('000000'+CAST(@TrayID AS VARCHAR(6)),6))
		WHERE TrayNumber = @TrayID


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- something went wrong, probably the user selected a setting that doesn't exist
		IF @@TRANCOUNT > 0 ROLLBACK 
		SET @FinalResult = 1

		SELECT ERROR_MESSAGE()
	END CATCH

	-- if everything went as planned, return the ID of the station

	SELECT @StationID
	
END 
GO

-- Name: PassCheck
-- Description: Randomizes the lamp pass/fail check, returns the output depending on the type of worker passed into it
-- Inputs: Worker Type, Int, an int corrosponding to the type of worker who created this lamp
-- Outputs: Bit, 1 if the lamp passed, 0 if it failed

DROP PROCEDURE IF EXISTS PassCheck
GO

CREATE PROCEDURE PassCheck 
	@WorkerType INT

AS
BEGIN
	-- declare a bit for final result
	DECLARE @Result BIT

	-- check what type of worker we have, and get the percentage for it
	DECLARE @Chance DECIMAL 
	DECLARE @RandomResult DECIMAL

	SELECT @Chance = ErrorChance FROM StationWorkerType 
	WHERE StationWorkerTypeID = @WorkerType

	-- check if the random number is below the error threshold

	IF (RAND() * 100)  < @Chance
		SET @Result = 0
	ELSE
		SET @Result = 1

	-- return the result
	RETURN @Result
END;

GO

-- Name: AddLamp
-- Description: This stored procedure allows a station to create a new lamp.
-- Inputs: Int, the ID of the workstation that created that lamp
-- outputs: Either a table of bin current capacaties, or the integer 1 if an error occured

DROP PROCEDURE IF EXISTS AddLamp
GO

CREATE PROCEDURE AddLamp
	@StationID INT
AS
BEGIN

	SET NOCOUNT ON;
    SET XACT_ABORT ON; 

	-- variable to hold the final result
	DECLARE @FinalResult INT = 0

	-- varaibles to help create the lamp ID
	DECLARE @TrayID VARCHAR(8)
	DECLARE @TrayNumber INT

	-- variable to keep track of how many lamps the tray currently holds
	DECLARE @LampNumber INT = 0

	BEGIN TRY	
		BEGIN TRANSACTION

		
		-- get the trayNumber from which we are passing the lamp into
		SELECT @TrayNumber = MAX(TrayNumber) from Tray
		WHERE StationID = @StationID


		-- Get the TrayID for later
		SELECT @TrayID = TrayID FROM Tray 
		WHERE TrayNumber =@TrayNumber

		

		-- get the number of Lamps held by this tray
		SELECT @LampNumber = COUNT(LampID) FROM Lamp WHERE TrayNumber = @TrayNumber
		SET @LampNumber = @LampNumber + 1

		-- get the percentage change that lamp failed

		DECLARE @Pass BIT
		DECLARE @WorkerType INT

		SELECT @WorkerType = StationWorkerType FROM Station 
		WHERE StationID = @StationID

		EXEC @Pass= PassCheck @WorkerType

		-- create a new lamp by inserting it into the lamp table

		INSERT INTO Lamp(LampID, TrayNumber, Passed, TimeCreated)
		VALUES(@TrayID + CAST(@LampNumber AS varchar(2)), @TrayNumber, @Pass,CURRENT_TIMESTAMP)
		
		-- if there are 60 or more lamps in the tray, we must insert a new one
		IF @LampNumber >= 60
			BEGIN
				INSERT INTO Tray(TrayID, StationID)
				VALUES (('FL' + RIGHT('000000'+CAST(@TrayID + 1 AS VARCHAR(6)),6)), @StationID)
			END	


		-- make sure to decriment all the bin values in the Station
		UPDATE BIN 
		SET CurrentStock = (CurrentStock - 1)
		WHERE StationID = @StationID

		-- return all the bin current volumes back to the station
		SELECT PartTypeID, CurrentStock 
		FROM Bin
		WHERE StationID = @StationID

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- something went wrong, probably the user selected a setting that doesn't exist
		IF @@TRANCOUNT > 0 ROLLBACK 
		SET @FinalResult = 1

		SELECT ERROR_MESSAGE()
	END CATCH


	
END 
GO


-- Name: ShutDownStations
-- Description: "Shuts Down" the simulation, setting all workstations to Inactive
-- Inputs: None
-- Outpuse: None
DROP PROCEDURE IF EXISTS ShutDownStations
GO

CREATE PROCEDURE ShutDownStations
	@StationID INT
AS
BEGIN

	SET NOCOUNT ON;
    SET XACT_ABORT ON; 

	-- variable to hold the final result
	DECLARE @FinalResult INT = 0


	BEGIN TRY	
		BEGIN TRANSACTION

		-- find all the stations that are running, and shut them off


		UPDATE Station
		SET Active = 0
		FROM Station
		WHERE Active = 1
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- something went wrong, probably the user selected a setting that doesn't exist
		IF @@TRANCOUNT > 0 ROLLBACK 
		SET @FinalResult = 1

		SELECT ERROR_MESSAGE()
	END CATCH

	-- if everything went as planned, return the Final Result

	SELECT @FinalResult
	
END 
GO





-- **************************************DATABASE SETUP*******************
-- call the stored procedure to set values to default values

EXEC SetDefaults
