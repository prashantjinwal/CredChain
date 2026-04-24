from utils import file_to_images
from ocr import extract_text_from_images
from qr import extract_qr_hash
from parser import parse_certificate_text


file_path = "samples/sample_certificate.pdf"
# or:
# file_path = "samples/sample_certificate.png"
# file_path = "samples/sample_certificate.jpg"

images = file_to_images(file_path)

text = extract_text_from_images(images)

qr_hash = extract_qr_hash(images)

details = parse_certificate_text(text)

print("\n--- EXTRACTED DETAILS ---")
print(details)

print("\n--- QR HASH / QR DATA ---")
print(qr_hash)

print("\n--- RAW TEXT ---")
print(text)