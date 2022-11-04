-- Active: 1666560447092@@poaudet.site@5432@pfa@public
CREATE PROCEDURE GetACP (dateDebut timestamp with time zone, dateFin timestamp with time zone, noDepot int = 0)
LANGUAGE plpgsql AS
$$
DECLARE 
        creancier VARCHAR(30);
		typeOps INT;
		noInst INT;
		noInstCT INT;
		noVerif INT;
		noCompte INT;
		noTransit INT;
		noEmetteur INT;

		-- Custom 
	
		noInstLot VARCHAR(5);
		creancierID VARCHAR(10);
		lineID VARCHAR(10);
		totalDepot INT;
		nbDepot INT;
		noDepotFS VARCHAR(4);

		-- StoreProc Static Parameters
BEGIN
	-- DB Data 

		

		-- Static Query

		SELECT	creancier = NomEmetteur,
				typeOps = TypeOp,
				noInst = NoInst,
				noInstCT = NoInstCT,
				noVerif = NoVerif,
				noCompte = NoCompte,
				noTransit = NoTransit,
				noEmetteur = NoEmetteur 
		FROM Informations
		WHERE ID = 1;

		lineID := CONCAT(noTransit, noEmetteur);
		noInstLot := CONCAT(noInst, noInstCT);


		IF noDepot = 0
        THEN
			noDepotFS := (SELECT FORMAT((MAX(NoDepot) + 1), '0000') FROM Transactions);
		ELSE
			noDepotFS := FORMAT(noDepot, '0000');
        END IF;
		nbDepot := ( SELECT COUNT(DateEffective)
						 FROM   listeDepot 
						 WHERE  DateEffective BETWEEN dateDebut AND dateFin 
					   );

		IF  nbDepot > 0 
        THEN
			-- Ligne A

			SELECT unaccent(CONCAT(
					'A', 
					FORMAT(1, '000000000'), 
					lineID,
					noDepotFS,					
					RIGHT(DATEPART(YEAR, GETDATE()), 3),
					FORMAT(DATEPART(DAYOFYEAR, GETDATE()), '000'),
					noInstLot)) AS Line
			FROM  Informations
			WHERE ID = creancierID 

			-- Ligne D

			UNION

			SELECT unaccent(CONCAT(
					'D', 
					FORMAT(ROW_NUMBER() OVER (ORDER BY DateEffective) + 1, '000000000'), 
					lineID,
					noDepotFS,
					typeOps,
					REPLACE(FORMAT((Depot + IIf(Frais IS NULL, 0, Frais)), '00000000.00'), '.', ''),
					RIGHT(DATEPART(YEAR, IIf(Transactions.DateEffective IS NULL, Transactions.Date, Transactions.DateEffective)), 3),
					FORMAT(DATEPART(DAYOFYEAR, IIf(Transactions.DateEffective IS NULL, Transactions.Date, Transactions.DateEffective)), '000'),			       
					CONCAT(FORMAT(NoInst, '0000'), FORMAT(NoTransit, '00000'), LEFT(CONCAT(FORMAT(NoCptTireur, IIF(NoInst in (1,4), '0000000', '00000000')), SPACE(12)), 12)),
					REPLICATE('0', 25),
					LEFT(CONCAT(creancier, SPACE(15)), 15),
					LEFT(CONCAT(Prenom, ' ', Nom, SPACE(30)), 30),
					LEFT(CONCAT(creancier, SPACE(30)), 30),
					lineID,
					SPACE(19),
					LEFT(CONCAT(FORMAT(noInst, '0000'), FORMAT(noTransit, '00000'), noCompte, noVerif, SPACE(21)), 21),
					LEFT(CONCAT(CONCAT('Prêt #', Transactions.NoPret), SPACE(15)), 15),
					SPACE(24),
					REPLICATE('0', 11))) AS Line
			FROM    Prets, Transactions, Clients 
			WHERE   Prets.NoPret = Transactions.NoPret AND
					--POA: le lien se fait plusieurs prêts pour un client. Le champ Clients.NoPret n'est plus mis à jour
					Prets.NoClient = Clients.NoClient AND
					Transactions.Etat IN (1, 2, 3, 4, 5) AND 
					Clients.Archive = 0 AND 
					Prets.Actif = 1 AND
					Transactions.DateEffective BETWEEN dateDebut AND dateFin

			-- Ligne Z

			UNION

			SELECT unaccent(CONCAT(
					'Z', 
					FORMAT(nbDepot + 2, '000000000'), 
					lineID,
					noDepotFS,
					REPLACE(FORMAT(SUM(Depot) + SUM(Frais), '000000000000.00'), '.', ''),
					FORMAT(COUNT(Depot), '00000000'),
					REPLICATE('0', 66))) AS Line
			FROM    Prets, Transactions, Clients 
			WHERE   Prets.NoPret = Transactions.NoPret AND
					--POA: le lien se fait plusieurs prêts pour un client. Le champ Clients.NoPret n'est plus mis à jour
					Prets.NoClient = Clients.NoClient AND
					Transactions.Etat IN (1, 2, 3, 4, 5) AND 
					Clients.Archive = 0 AND 
					Prets.Actif = 1 AND
					Transactions.DateEffective BETWEEN dateDebut AND dateFin;

			-- Update Transactions	
	   
			UPDATE  Transactions
			SET     Transactions.NoDepot = noDepot, 
				    Transactions.Etat = 8
			FROM    Prets, Transactions, Clients 
			WHERE   Prets.NoPret = Transactions.NoPret AND
					Prets.NoClient = Clients.NoClient AND
					Transactions.Etat IN (2, 3, 4, 5) AND 
					Clients.Archive = 0 AND 
					Prets.Actif = 1 AND
					Transactions.DateEffective BETWEEN dateDebut AND dateFin;

			UPDATE  Transactions
			SET     Transactions.NoDepot = noDepot, 
				    Transactions.Etat = 7
			FROM    Prets, Transactions, Clients 
			WHERE   Prets.NoPret = Transactions.NoPret AND
					Prets.NoClient = Clients.NoClient AND
					Transactions.Etat = 1 AND 
					Clients.Archive = 0 AND 
					Prets.Actif = 1 AND
					Transactions.DateEffective BETWEEN dateDebut AND dateFin;

			-- Update Logs
	
			INSERT INTO Logs (NoPret, NoDepot, Etat, Frais, DateEffective, NoTransaction)
			SELECT NoPret, NoDepot, Etat, Frais, DateEffective, NoTransaction
			FROM   Transactions
			WHERE  Transactions.NoDepot = noDepot;
        END IF;
END
$$