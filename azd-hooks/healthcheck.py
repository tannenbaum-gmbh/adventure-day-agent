import os
import requests
from dotenv import load_dotenv
from openai import AzureOpenAI

load_dotenv()

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def error_report(message):
    print("["+bcolors.FAIL + "ERROR"+bcolors.ENDC+"] "+message)
    print(error_message)
    exit(1)

def success_report(message):
    print("["+bcolors.OKGREEN + "SUCCESS"+bcolors.ENDC+"] "+message)

print("Running healthcheck of deployed resources...")

error_message="The validation has encountered an error. Please check the output above for more details. \n If you want to rerun the check execute \"python azd-hooks/healthcheck.py\""

# Check if the OpenAI API is reachable
print("Checking if OpenAI API is reachable...")
try:
    requests.get(os.getenv("AZURE_OPENAI_ENDPOINT") + "/status-0123456789abcdef")
except Exception as e:
    error_report("OpenAI API cannot be reached or is inoperational. Details: " + str(e))

success_report("OpenAI API is reachable.")


# Check completion model operability
print("Checking if OpenAI completion model is operational...")
client = AzureOpenAI(
        api_key = os.getenv("AZURE_OPENAI_API_KEY"),  
        api_version = os.getenv("AZURE_OPENAI_VERSION"),
        azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    )
deployment_name = os.getenv("AZURE_OPENAI_COMPLETION_DEPLOYMENT_NAME")

try:
    response = client.chat.completions.create(
        model=deployment_name,
        messages=[
            {"role" : "assistant", "content" : "The one thing I love more than anything else is "}
        ],
    )
except Exception as e:
    error_report("Error while trying to connect to completion model ("+ deployment_name +"). Details: " +str(e))
success_report("Completion model is operational.")

# Check embedding model operability
embedding_model = os.environ["AZURE_OPENAI_EMBEDDING_MODEL"]

print("Checking if OpenAI embedding model is operational...")
try:
    embedding = client.embeddings.create(
        input = "This is an example text that i want to turn into embedding.",
        model=embedding_model,
    )
except Exception as e:
    error_report("Error while trying to connect to embedding model ("+ embedding_model +"). Details: " +str(e))
success_report("Embedding model is operational.")

# Check AiSearch service operability
print("Checking if AzureAI Search API is accessable...")
aisearch_endpoint = os.environ["AZURE_AI_SEARCH_ENDPOINT"]
try:
    requests.get(url=aisearch_endpoint+"?api-version=2024-07-01", headers={"api-key": os.getenv("AZURE_AI_SEARCH_KEY")})
except Exception as e:
    error_report("AzureAI Search API cannot be accessed. Check endpoint ("+aisearch_endpoint+"), credentials and/or network connection. Details: " + str(e))
success_report("AzureAI Search API is accessable.")

print("All resources are operational. The deployment is ready for use.")
exit(0)