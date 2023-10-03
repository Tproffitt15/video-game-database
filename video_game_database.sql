USE master
GO
DROP DATABASE IF EXISTS DillonBrown_TroyProfitt
GO
CREATE DATABASE DillonBrown_TroyProfitt
GO
USE DillonBrown_TroyProfitt
GO
DROP TABLE IF EXISTS Admins, Owners, Console, Games
GO

-------------------------------------------------------------------------------------Tables
CREATE TABLE Admins (
	adminID			INT			NOT NULL	PRIMARY KEY		IDENTITY(1,1),
	token			INT			NOT NULL,
	username		VARCHAR(20)	NOT NULL,
	passwrd			VARCHAR(20)	NOT NULL
);
GO


CREATE TABLE Owners (
	ownerID			INT			NOT NULL	PRIMARY KEY		IDENTITY(1,1),
	firstName		VARCHAR(20)	NOT NULL,
	lastName		VARCHAR(20) NOT NULL,
	ownerAge		INT			NOT NULL
);
GO


CREATE TABLE Console (
	consoleID		INT			NOT NULL	PRIMARY KEY		IDENTITY(1,1),
	ownerID			INT			FOREIGN KEY REFERENCES		Owners(ownerID),
	consoleName		VARCHAR(20)	NOT NULL,
	hoursOnConsole	INT		NOT NULL
);
GO


CREATE TABLE Games (
	gameID			INT			NOT NULL	PRIMARY KEY		IDENTITY(1,1),
	consoleID		INT			FOREIGN KEY REFERENCES		Console(consoleID),
	ownerID			INT			FOREIGN KEY REFERENCES		Owners(ownerID),
	gameName		VARCHAR(50) NOT NULL,
	rating			VARCHAR(20)	NOT NULL,
	completed		BIT			NOT NULL	DEFAULT(0),
	totalHours		INT			NOT NULL	DEFAULT(0),
	publisher		VARCHAR(30) NOT NULL
);
GO
INSERT INTO Owners (firstName, lastName, ownerAge)
VALUES('Dillon', 'Brown', 21)

INSERT INTO Console (ownerID, consoleName, hoursOnConsole)
VALUES (1, 'Nintendo Switch', 2072) 


INSERT INTO Console (ownerID, consoleName, hoursOnConsole)
VALUES (1, 'PlayStation 4', 400) 

INSERT INTO Console (ownerID, consoleName, hoursOnConsole) 
VALUES (1, 'PC', 6000)

INSERT INTO Owners (firstName, lastName, ownerAge)
VALUES('Troy', 'Profitt', 20)

INSERT INTO Games(consoleID, ownerID, gameName, rating, completed, totalHours, publisher) 
VALUES(1,1,'Pokemon Mystery Dungeon Rescue Team DX', 'E', 1, 72, 'The Pokemon Company')

INSERT INTO Games(consoleID, ownerID, gameName, rating, completed, totalHours, publisher) 
VALUES(1,1,'Super Smash Brothers Ultimate', 'E10+', 0, 2000, 'Nintendo')

INSERT INTO Games(consoleID, ownerID, gameName, rating, completed, totalHours, publisher) 
VALUES(2,1,'Dark Souls III', 'M', 1, 400, 'BANDAI NAMCO Entertainment')


INSERT INTO Console (ownerID, consoleName, hoursOnConsole) 
VALUES (2, 'Playstation 4', 500)

INSERT INTO Console (ownerID, consoleName, hoursOnConsole) 
VALUES (2, 'Nintendo Switch', 250)

INSERT INTO Console (ownerID, consoleName, hoursOnConsole) 
VALUES (2, 'PC', 5000)

INSERT INTO Console (ownerID, consoleName, hoursOnConsole) 
VALUES (2, 'Xbox 360', 900)

INSERT INTO Games(consoleID, ownerID, gameName, rating, completed, totalHours, publisher) 
VALUES(3,2,'Final Fantasy 7 Remake', 'T', 1, 100, 'Square Enix')

INSERT INTO Games(consoleID, ownerID, gameName, rating, completed, totalHours, publisher) 
VALUES(4,2,'The Legend of Zelda: Breath of the Wild', 'E10+', 0, 200, 'Nintendo')

INSERT INTO Games(consoleID, ownerID, gameName, rating, completed, totalHours, publisher) 
VALUES(5,2,'League of Legends', 'T', 0, 3000, 'Riot Games')

INSERT INTO Games(consoleID, ownerID, gameName, rating, completed, totalHours, publisher) 
VALUES(5,1,'League of Legends', 'T', 0, 3000, 'Riot Games')

INSERT INTO Games(consoleID, ownerID, gameName, rating, completed, totalHours, publisher) 
VALUES(6,2,'Halo 3', 'M', 1, 300, 'Bungie')

INSERT INTO Games(consoleID, ownerID, gameName, rating, completed, totalHours, publisher)
VALUES(6,2,'Call of Duty', 'M', 1, 500, 'Treyarch')

INSERT INTO Admins(token, username, passwrd) VALUES (0, 'Admin', 'pass')
GO

-------------------------------------------------------------------------------------Functions
CREATE FUNCTION sumHoursPlayed()
	RETURNS INT as
	BEGIN

	DECLARE @sumHours int;
		SELECT @sumHours = sum(totalHours) FROM Games
		RETURN @sumHours
	END
GO

-------------------------------------------------------------------------------------------VIEWS
DROP VIEW IF EXISTS gameHours, ownerAll, matureGames, mostPlayedGames
GO

CREATE VIEW gameHours AS
	SELECT g.gameName as [Game Name], c.consoleName as [Console Name], g.totalHours as [Total Hours By Owner]
	FROM Games g
		JOIN Console	c on c.consoleID = g.consoleID
	GROUP BY g.gameName, c.consoleName, g.totalHours
GO

CREATE VIEW ownerAll AS
	SELECT o.ownerID, o.firstName, o.lastName,  g.gameID, g.gameName, c.consoleID, c.consoleName
	FROM Owners o
		JOIN Console	c on c.ownerID = o.ownerID
		JOIN Games		g on g.ownerID = c.ownerID
	WHERE g.consoleID = c.consoleID
GO

CREATE VIEW matureGames AS
	SELECT g.gameID, g.gameName
	FROM Games g
	WHERE g.rating = 'T' OR g.rating = 'M' OR g.rating = 'Unrated'
GO

CREATE VIEW mostPlayedGames AS
	SELECT TOP(5) g.gameID, g.gameName, g.rating, g.publisher, sum(g.totalHours) as [Total Hours]
	FROM Games g
	GROUP BY g.gameID, g.totalHours, g.gameName, g.rating, g.publisher
	ORDER BY sum(g.totalHours) DESC
GO

-------------------------------------------------------------------------------------Procedures
DROP PROCEDURE IF EXISTS spAddUpdateDeleteConsole, spAddUpdateDeleteGames, spAddUpdateDeleteOwner, spEncrypting
GO

CREATE PROCEDURE spAddUpdateDeleteConsole
	@consoleID			INT, 
	@ownerID			INT,		
	@consoleName		VARCHAR(20),
	@hoursOnConsole		INT,
	@delete				bit,
	@token				int
	AS BEGIN
	IF @token = (SELECT token FROM Admins WHERE adminID=1)
	BEGIN
			IF @delete = 1 BEGIN																	-- DELETE
			BEGIN TRY
				DELETE FROM Console
				WHERE consoleID = @consoleID
			END TRY BEGIN CATCH
			END CATCH
		END 
		ELSE IF EXISTS (SELECT NULL FROM Console WHERE consoleID = @consoleID) BEGIN		-- UPDATE
				UPDATE Console
				SET ownerID = @ownerID, consoleName= @consoleName, hoursOnConsole = @hoursOnConsole
				WHERE consoleID = @consoleID
		END 
			ELSE BEGIN																			-- INSERT
				INSERT INTO Console (ownerID, consoleName, hoursOnConsole) VALUES (@ownerID, @consoleName, @hoursOnConsole)
			END
		END
	END
GO

CREATE PROCEDURE spAddUpdateDeleteGames
	@gameID			INT,			
	@consoleID		INT,			
	@ownerID		INT,			
	@gameName		VARCHAR(50), 
	@rating			VARCHAR(20),	
	@completed		BIT,		
	@totalHours		INT,			
	@publisher		VARCHAR(30) ,
	@delete			bit,
	@token			int
	AS BEGIN
	if @token = (SELECT token FROM Admins WHERE adminID = 1)
	BEGIN
		IF @delete = 1 BEGIN																	-- DELETE
			BEGIN TRY
				DELETE FROM Games
				WHERE gameID = @gameID
			END TRY BEGIN CATCH
			END CATCH
		END 
			ELSE IF EXISTS (SELECT NULL FROM Games WHERE gameID = @gameID) BEGIN		-- UPDATE
				UPDATE Games
				SET consoleID = @consoleID, ownerID = @ownerID, gameName = @gameName, rating = @rating, completed = @completed, totalHours = @totalHours, publisher = @publisher
				WHERE gameID = @gameID
		END 
			ELSE BEGIN																			-- INSERT
				INSERT INTO Games (consoleID, ownerID, gameName, rating, completed, totalHours, publisher) VALUES (@consoleID, @ownerID, @gameName, @rating, @completed, @totalHours, @publisher)
			END
		END
	END
GO
CREATE PROCEDURE spAddUpdateDeleteOwner
	@ownerID		INT,			
	@firstName		VARCHAR(20),	
	@lastName		VARCHAR(20),
	@ownerAge		INT,
	@delete			bit,
	@token			int
	AS BEGIN
	if @token = (SELECT token FROM Admins WHERE adminID = 1)
	Begin
		IF @delete = 1 BEGIN																	-- DELETE
			BEGIN TRY
				DELETE FROM Owners
				WHERE ownerID = @ownerID
			END TRY BEGIN CATCH
			END CATCH
		END 
			ELSE IF EXISTS (SELECT NULL FROM Owners WHERE ownerID = @ownerID) BEGIN		-- UPDATE
				UPDATE Owners
				SET  firstName = @firstName, lastName = @lastName, ownerAge = @ownerAge
				WHERE ownerID = @ownerID
		END 
			ELSE BEGIN																			-- INSERT
				INSERT INTO Owners (firstName, lastName, ownerAge) VALUES (@firstName, @lastName, @ownerAge)
			END
		END
	End
GO


CREATE INDEX idxGameName
ON Games (gameID, gameName);
GO
CREATE INDEX idxConsoleName
ON Console (consoleID, consoleName);
GO
CREATE INDEX idxOwnerName
ON Owners (ownerID, firstName, lastName);
GO


-------------------------------------------------------------------------------------Trigger
DROP TRIGGER IF EXISTS randomizeTokenConsole, randomizeTokenGames, randomizeTokenOwners, randomizeTokenAdmins;
GO

CREATE TRIGGER randomizeTokenGames ON Games
AFTER INSERT, UPDATE, DELETE
    AS BEGIN
        DECLARE @token INT = (SELECT FLOOR(RAND()*(10))+1);
		UPDATE Admins SET token = @token;
    END
    GO

CREATE TRIGGER randomizeTokenOwners ON Owners
AFTER INSERT, UPDATE, DELETE
    AS BEGIN
        DECLARE @token INT = (SELECT FLOOR(RAND()*(10)));
		UPDATE Admins SET token = @token;
    END
    GO

CREATE TRIGGER randomizeTokenConsole ON Console
AFTER INSERT, UPDATE, DELETE
    AS BEGIN
        DECLARE @token INT = (SELECT FLOOR(RAND()*(10)));
		UPDATE Admins SET token = @token;
    END
    GO

CREATE TRIGGER randomizeTokenAdmins ON Admins
AFTER INSERT, UPDATE, DELETE
    AS BEGIN
        DECLARE @token INT = (SELECT FLOOR(RAND()*(10)));
		UPDATE Admins SET token = @token;
    END
    GO