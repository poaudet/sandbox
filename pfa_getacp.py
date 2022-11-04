import datetime
import os
from unicodedata import decimal
from isodate import datetime_isoformat
import psycopg2
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient
import azure.functions

def main(req: azure.functions.HttpRequest) -> str:

# Creating Blob Storage connection
account_url = "https://audefinancement.blob.core.windows.net"
default_credential = DefaultAzureCredential()

# Create the BlobServiceClient object
blob_service_client = BlobServiceClient(account_url, credential=default_credential)

# Function to convert tuple in string
def convertTuple(tup):
    str = ''.join(tup)
    return str
# Functions to manage left/right/mid in string
def left(s, amount):
    return s[:amount]

def right(s, amount):
    return s[-amount:]

def mid(s, offset, amount):
    return s[offset:offset+amount]

# Define variables for lines
lineA = ''
lineD = ''
lineZ = ''

# Define variables to get from the HTTP Request
dateDebut = req.params.get('dateDebut')
dateFin = req.params.get('dateFin')
today = datetime.date.today()
doy=today.strftime('%j')
noEmetteur = 2003215299
typeOps=439
noDepot=int(req.params.get('noDepot'))
noInstLot='81510'
rowCount = 1
depotCount = 0
totalDepot = 0

# Connect to your postgres DB
conn = psycopg2.connect(database="pfa", user="pfa_admin", password="Les prêts auto.", host="poaudet.site", port="5432")

# Open a cursor to perform database operations
cur = conn.cursor()

# Create lineA
lineA = 'A'+str(rowCount).zfill(9)+str(noEmetteur)+str(noDepot).zfill(4)+right(str(today.year), 3)+str(doy).zfill(3)+noInstLot

# Excute a query to get number of depot and total amount
cur.execute("SELECT sum(cast(depot as decimal (10,2))),count(notransaction)\
            FROM prets, transactions, clients\
            WHERE prets.nopret = transactions.nopret AND\
                    prets.noclient = clients.noclient AND\
                    transactions.etat IN (1, 2, 3, 4, 5) AND\
                    transactions.dateeffective BETWEEN %s AND %s",(dateDebut,dateFin))

# Retrieve result and update variables
for row in cur:
    totalDepot = (str(row)).replace('(Decimal(','').replace('\')','').replace(' ','').replace('\'','').replace(')','').split(',')[0].replace('.','')
    depotCount = int((str(row)).replace('(Decimal(','').replace('\')','').replace(' ','').replace('\'','').replace(')','').split(',')[1])

# Execute a query for lineD
cur.execute("SELECT 'D'||to_char(ROW_NUMBER() OVER (ORDER BY dateeffective) + 1, 'FM000000000')||%s||%s||\
                    %s||\
                    REPLACE(to_char(Depot, 'FM00000000.00'), '.', '')||\
                    RIGHT(to_char(DATE_PART('YEAR', transactions.dateeffective),'FM0000'), 3)||\
                    to_char(DATE_PART('doy',transactions.dateeffective), 'FM000')||\
                    CONCAT(to_char(noinst, 'FM0000'), to_char(notransit, 'FM00000'), LEFT(rpad(to_char(nocpttireur,'FM00000000'),12,' '),12)||\
                    REPEAT('0', 25)||\
                    LEFT(CONCAT('Audet Financement inc.', REPEAT(' ',15)), 15)||\
                    LEFT(CONCAT(prenom, ' ', nom, REPEAT(' ',30)), 30)||\
                    LEFT(CONCAT('Audet Financement inc.', REPEAT(' ',30)), 30)||\
                    %s||\
                    REPEAT(' ',19)||\
                    LEFT(CONCAT(to_char(815, 'FM0000'), to_char(20032, 'FM00000'), 515299, 6, REPEAT(' ',21)), 21)||\
                    LEFT(CONCAT(CONCAT('Prêt #', transactions.nopret), REPEAT(' ',15)), 15)||\
                    REPEAT(' ',24)||\
                    REPEAT('0', 11)) AS Line\
            FROM    prets, transactions, clients \
            WHERE   prets.nopret = transactions.nopret AND\
                    prets.noclient = clients.noclient AND\
                    transactions.etat IN (1, 2, 3, 4, 5) AND \
                    transactions.dateeffective BETWEEN %s AND %s",(noEmetteur,str(noDepot).zfill(4),typeOps,noEmetteur,dateDebut,dateFin))

# Retrieve query results
for row in cur:
    rowCount = rowCount + 1
    row_string = convertTuple(row)
    if rowCount != depotCount+1:
        lineD = lineD + row_string + "\n"
    else:
        lineD = lineD + row_string

# Create lineZ
rowCount = rowCount +1
lineZ = 'Z'+str(rowCount).zfill(9)+str(noEmetteur)+str(noDepot).zfill(4)+(str(totalDepot).zfill(14))+str(depotCount).zfill(8)+'0'*66

# Upload to Blob Storage
# Create a local directory to hold blob data
local_path = "./data"
if not os.path.exists(local_path):
    os.mkdir(local_path)

# Create a file in the local data directory to upload and download
local_file_name = str(str(noDepot)+'_'+str(datetime.datetime.today())) + ".acp"
upload_file_path = os.path.join(local_path, local_file_name)

# Write text to the file
file = open(file=upload_file_path, mode='w')
file.write(lineA+'\n'+lineD+'\n'+lineZ)
file.close()

# Create a blob client using the local file name as the name for the blob
blob_client = blob_service_client.get_blob_client(container='acp', blob=local_file_name)

print("\nUploading to Azure Storage as blob:\n\t" + local_file_name)

# Upload the created file
with open(file=upload_file_path, mode="rb") as data:
    blob_client.upload_blob(data)