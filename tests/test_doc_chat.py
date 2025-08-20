import sys
from pathlib import Path
from langchain_community.vectorstores import FAISS
from archive.src.single_doc_chat.data_ingestion import SingleDocIngestor
from archive.src.single_doc_chat.retrieval import ConversationalRAG
from utils.model_loader import ModelLoader


# Testing code for document chat functionality


FAISS_INDEX_PATH = Path("faiss_index")

def test_conversational_rag_on_pdf(pdf_path:str, question:str):
    try:
        model_loader = ModelLoader()
        
        if FAISS_INDEX_PATH.exists():
            print("Loading existing FAISS index...")
            embeddings = model_loader.load_embeddings()
            vectorstore = FAISS.load_local(folder_path=str(FAISS_INDEX_PATH), embeddings=embeddings,allow_dangerous_deserialization=True)
            retriever = vectorstore.as_retriever(search_type="similarity", search_kwargs={"k": 5})
        else:
            # Step 2: Ingest document and create retriever
            print("FAISS index not found. Ingesting PDF and creating index...")
            with open(pdf_path, "rb") as f:
                uploaded_files = [f]
                ingestor = SingleDocIngestor()
                retriever = ingestor.ingest_files(uploaded_files)
                
        print("Running Conversational RAG...")
        session_id = "test_conversational_rag"
        rag = ConversationalRAG(retriever=retriever, session_id=session_id)
        response = rag.invoke(question)
        print(f"\nQuestion: {question}\nAnswer: {response}")
                    
    except Exception as e:
        print(f"Test failed: {str(e)}")
        sys.exit(1)
    
if __name__ == "__main__":
    # Example PDF path and question
    pdf_path = "B:\\LLOPS\\document_portal\\data\\sample.pdf"
    question = "What is the significance of the contrastive learning in graphs? can you explain it in simple terms?"

    if not Path(pdf_path).exists():
        print(f"PDF file does not exist at: {pdf_path}")
        sys.exit(1)
    
    # Run the test
    test_conversational_rag_on_pdf(pdf_path, question)