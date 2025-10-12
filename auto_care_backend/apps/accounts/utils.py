import secrets
import logging

logger = logging.getLogger(__name__)

def generate_otp():
    """Generate cryptographically secure 6-digit OTP"""
    return ''.join([str(secrets.randbelow(10)) for _ in range(6)])

def normalize_mobile_number(mobile_number):
    """
    Normalize mobile number by removing spaces, hyphens, and country codes
    Returns only 10-digit number
    """
    if not mobile_number:
        return ""
    
    # Remove spaces, hyphens, parentheses
    mobile = mobile_number.strip().replace(" ", "").replace("-", "").replace("(", "").replace(")", "")
    
    # Remove +91 prefix
    if mobile.startswith("+91"):
        mobile = mobile[3:]
    # Remove 91 prefix if total length is 12 (91 + 10 digits)
    elif mobile.startswith("91") and len(mobile) == 12:
        mobile = mobile[2:]
    # Remove 0 prefix if exists
    elif mobile.startswith("0"):
        mobile = mobile[1:]
    
    return mobile

def validate_mobile_number(mobile_number):
    """
    Validate mobile number format
    Returns (is_valid, error_message)
    """
    normalized = normalize_mobile_number(mobile_number)
    
    if not normalized:
        return False, "Mobile number is required."
    
    if not normalized.isdigit():
        return False, "Only numeric digits are allowed in mobile number."
    
    if len(normalized) < 10:
        return False, "Mobile number is too short. Must be exactly 10 digits."
    
    if len(normalized) > 10:
        return False, "Mobile number is too long. Must be exactly 10 digits."
    
    return True, None