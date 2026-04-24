import os
import pytesseract
from dotenv import load_dotenv
from utils import preprocess_image


load_dotenv()

TESSERACT_CMD = os.getenv("TESSERACT_CMD")
TESSDATA_PREFIX = os.getenv("TESSDATA_PREFIX")

if TESSERACT_CMD:
    pytesseract.pytesseract.tesseract_cmd = TESSERACT_CMD

if TESSDATA_PREFIX:
    os.environ["TESSDATA_PREFIX"] = TESSDATA_PREFIX


def extract_text_from_image(pil_image) -> str:
    processed_image = preprocess_image(pil_image)

    text = pytesseract.image_to_string(
        processed_image,
        config="--psm 6",
        lang="eng"
    )

    return text.strip()


def extract_text_from_images(images) -> str:
    full_text = ""

    for image in images:
        page_text = extract_text_from_image(image)
        full_text += "\n" + page_text

    return full_text.strip()