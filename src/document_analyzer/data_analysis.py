import sys
import psutil
from utils.model_loader import ModelLoader
from logger import GLOBAL_LOGGER as log
from exception.custom_exception import DocumentPortalException
from model.models import *
from langchain_core.output_parsers import JsonOutputParser
from langchain.output_parsers import OutputFixingParser
from prompt.prompt_library import PROMPT_REGISTRY # type: ignore

class DocumentAnalyzer:
    """
    Analyzes documents using a pre-trained model.
    Automatically logs all actions and supports session-based organization.
    """
    def __init__(self):
        try:
            self.loader=ModelLoader()
            self.llm=self.loader.load_llm()
            
            # Prepare parsers
            self.parser = JsonOutputParser(pydantic_object=Metadata)
            self.fixing_parser = OutputFixingParser.from_llm(parser=self.parser, llm=self.llm)
            
            self.prompt = PROMPT_REGISTRY["document_analysis"]
            
            log.info("DocumentAnalyzer initialized successfully")
            
            
        except Exception as e:
            log.error(f"Error initializing DocumentAnalyzer: {e}")
            raise DocumentPortalException("Error in DocumentAnalyzer initialization", sys)
        
        
    
    def analyze_document(self, document_text:str)-> dict:
        """
        Analyze a document's text and extract structured metadata & summary.
        """
        try:
            log.info("Starting document analysis", text_length=len(document_text))
            
            chain = self.prompt | self.llm | self.parser
            
            log.info("Meta-data analysis chain initialized")

            log.info("Invoking LLM chain...")
            
            # Log memory usage before LLM call
            memory = psutil.virtual_memory()
            log.info("Memory usage before LLM call", 
                    available_mb=memory.available // (1024*1024),
                    used_mb=memory.used // (1024*1024),
                    percent=memory.percent)
            
            response = chain.invoke({
                "format_instructions": self.parser.get_format_instructions(),
                "document_text": document_text
            })

            log.info("Metadata extraction successful", keys=list(response.keys()))
            
            return response

        except Exception as e:
            log.error("Metadata analysis failed", error=str(e))
            # Try with the fixing parser as fallback
            try:
                log.info("Attempting to fix output with OutputFixingParser")
                raw_response = self.prompt.invoke({
                    "format_instructions": self.parser.get_format_instructions(),
                    "document_text": document_text
                })
                llm_response = self.llm.invoke(raw_response)
                fixed_response = self.fixing_parser.parse(llm_response.content)
                log.info("Output fixed successfully", keys=list(fixed_response.keys()))
                return fixed_response
            except Exception as fallback_error:
                log.error("Fixing parser also failed", error=str(fallback_error))
                raise DocumentPortalException("Metadata extraction failed",sys)
        
    