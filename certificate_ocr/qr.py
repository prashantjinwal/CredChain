import cv2
import numpy as np
from pyzbar.pyzbar import decode


def extract_qr_from_image(pil_image):
    image = np.array(pil_image)

    qr_codes = decode(image)

    if qr_codes:
        return qr_codes[0].data.decode("utf-8")

    return None


def extract_qr_from_images(images):
    for image in images:
        qr_data = extract_qr_from_image(image)

        if qr_data:
            return qr_data

    return None


def extract_qr_with_opencv(pil_image):
    """
    Backup QR extractor if pyzbar fails.
    """
    image = np.array(pil_image)
    image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

    detector = cv2.QRCodeDetector()
    data, points, _ = detector.detectAndDecode(image)

    if data:
        return data

    return None


def extract_qr_hash(images):
    for image in images:
        qr_data = extract_qr_from_image(image)

        if not qr_data:
            qr_data = extract_qr_with_opencv(image)

        if qr_data:
            return qr_data

    return None