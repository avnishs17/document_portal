
import os
import sys
from dotenv import load_dotenv
from utils.config_loader import load_config
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_groq import ChatGroq
#from langchain_openai import ChatOpenAI
from logger import GLOBAL_LOGGER as log
from exception.custom_exception import DocumentPortalException

class ModelLoader:
    
    """
    A utility class to load embedding models and LLM models.
    """
    
    def __init__(self):
        
        load_dotenv()
        self.config=load_config()
        self._setup_langsmith_tracking()
        self._validate_env()
        log.info("Configuration loaded successfully", config_keys=list(self.config.keys()))
        
    def _setup_langsmith_tracking(self):
        """
        Setup LangSmith tracking based on config.yaml settings.
        Only enables if both config is enabled and LANGCHAIN_API_KEY is provided.
        """
        langsmith_config = self.config.get("langsmith", {})
        langsmith_enabled = langsmith_config.get("enabled", False)
        langchain_api_key = os.getenv("LANGCHAIN_API_KEY")
        
        if langsmith_enabled and langchain_api_key:
            # Get project name and environment from config
            project_name = langsmith_config.get("project_name", "DOCUMENT_PORTAL")
            environment = langsmith_config.get("environment", "production")
            
            # Enable LangSmith tracing
            os.environ["LANGCHAIN_TRACING_V2"] = "true"
            os.environ["LANGCHAIN_API_KEY"] = langchain_api_key
            os.environ["LANGCHAIN_PROJECT"] = project_name
            
            # Set environment tag if provided
            if environment:
                os.environ["LANGCHAIN_TAGS"] = environment
                
            log.info("LangSmith tracking enabled", 
                    project=project_name, 
                    environment=environment,
                    enabled=langsmith_enabled)
        else:
            reasons = []
            if not langsmith_enabled:
                reasons.append("disabled in config")
            if not langchain_api_key:
                reasons.append("no LANGCHAIN_API_KEY")
            
            log.info("LangSmith tracking disabled", reasons=reasons)
        
    def _validate_env(self):
        """
        Validate necessary environment variables.
        Ensure API keys exist.
        """
        required_vars=["GOOGLE_API_KEY","GROQ_API_KEY"]
        # LangChain API key is optional for tracking
        optional_vars=["LANGCHAIN_API_KEY"]
        
        self.api_keys={key:os.getenv(key) for key in required_vars + optional_vars}
        missing = [k for k in required_vars if not self.api_keys.get(k)]
        
        if missing:
            log.error("Missing environment variables", missing_vars=missing)
            raise DocumentPortalException("Missing environment variables", sys)
            
        available_keys = [k for k in self.api_keys if self.api_keys[k]]
        log.info("Environment variables validated", available_keys=available_keys)
        
    def load_embeddings(self):
        """
        Load and return the embedding model.
        """
        try:
            log.info("Loading embedding model...")
            model_name = self.config["embedding_model"]["model_name"]
            return GoogleGenerativeAIEmbeddings(model=model_name)
        except Exception as e:
            log.error("Error loading embedding model", error=str(e))
            raise DocumentPortalException("Failed to load embedding model", sys)
        
    def load_llm(self):
        """
        Load and return the LLM model.
        """
        """Load LLM dynamically based on provider in config."""
        
        llm_block = self.config["llm"]

        log.info("Loading LLM...")

        provider_key = os.getenv("LLM_PROVIDER", "google")  # Default google
        if provider_key not in llm_block:
            log.error("LLM provider not found in config", provider_key=provider_key)
            raise ValueError(f"Provider '{provider_key}' not found in config")

        llm_config = llm_block[provider_key]
        provider = llm_config.get("provider")
        model_name = llm_config.get("model_name")
        temperature = llm_config.get("temperature", 0.2)
        max_tokens = llm_config.get("max_output_tokens", 2048)
        
        log.info("Loading LLM", provider=provider, model=model_name, temperature=temperature, max_tokens=max_tokens)

        if provider == "google":
            llm=ChatGoogleGenerativeAI(
                model=model_name,
                api_key=self.api_keys["GOOGLE_API_KEY"],
                temperature=temperature,
                max_output_tokens=max_tokens
            )
            return llm

        elif provider == "groq":
            llm=ChatGroq(
                model=model_name,
                api_key=self.api_keys["GROQ_API_KEY"], #type: ignore
                temperature=temperature,
            )
            return llm
            
        # elif provider == "openai":
        #     return ChatOpenAI(
        #         model=model_name,
        #         api_key=self.api_keys["OPENAI_API_KEY"],
        #         temperature=temperature,
        #         max_tokens=max_tokens
        #     )
        else:
            log.error("Unsupported LLM provider", provider=provider)
            raise ValueError(f"Unsupported LLM provider: {provider}")
        
    
    
if __name__ == "__main__":
    loader = ModelLoader()
    
    # Test embedding model loading
    embeddings = loader.load_embeddings()
    print(f"Embedding Model Loaded: {embeddings}")
    
    # Test the ModelLoader
    result=embeddings.embed_query("Hello, how are you?")
    print(f"Embedding Result: {result}")
    
    # Test LLM loading based on YAML config
    llm = loader.load_llm()
    print(f"LLM Loaded: {llm}")
    
    # Test the ModelLoader
    result=llm.invoke("Hello, how are you?")
    print(f"LLM Result: {result.content}")