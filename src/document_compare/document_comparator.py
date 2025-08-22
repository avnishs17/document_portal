import sys
from dotenv import load_dotenv
import pandas as pd
from langchain_core.output_parsers import JsonOutputParser
from langchain.output_parsers import OutputFixingParser
from utils.model_loader import ModelLoader
from logger import GLOBAL_LOGGER as log
from exception.custom_exception import DocumentPortalException
from prompt.prompt_library import PROMPT_REGISTRY
from model.models import SummaryResponse,PromptType

class DocumentComparatorLLM:
    def __init__(self):
        load_dotenv()
        self.loader = ModelLoader()
        self.llm = self.loader.load_llm()
        self.parser = JsonOutputParser(pydantic_object=SummaryResponse)
        self.fixing_parser = OutputFixingParser.from_llm(parser=self.parser, llm=self.llm)
        self.prompt = PROMPT_REGISTRY[PromptType.DOCUMENT_COMPARISON.value]
        self.chain = self.prompt | self.llm | self.parser
        log.info("DocumentComparatorLLM initialized", model=self.llm)

    def compare_documents(self, combined_docs: str) -> pd.DataFrame:
        try:
            inputs = {
                "combined_docs": combined_docs,
                "format_instruction": self.parser.get_format_instructions()
            }

            log.info("Invoking document comparison LLM chain")
            response = self.chain.invoke(inputs)
            log.info("Chain invoked successfully", response_preview=str(response)[:200])
            return self._format_response(response)
        except Exception as e:
            log.error("Error in compare_documents", error=str(e))
            # Try with the fixing parser as fallback
            try:
                log.info("Attempting to fix output with OutputFixingParser")
                raw_response = self.prompt.invoke(inputs)
                llm_response = self.llm.invoke(raw_response)
                fixed_response = self.fixing_parser.parse(llm_response.content)
                log.info("Output fixed successfully", response_preview=str(fixed_response)[:200])
                return self._format_response(fixed_response)
            except Exception as fallback_error:
                log.error("Fixing parser also failed", error=str(fallback_error))
                raise DocumentPortalException("Error comparing documents", sys)

    def _format_response(self, response_parsed: list[dict]) -> pd.DataFrame: #type: ignore
        try:
            df = pd.DataFrame(response_parsed)
            return df
        except Exception as e:
            log.error("Error formatting response into DataFrame", error=str(e))
            DocumentPortalException("Error formatting response", sys)