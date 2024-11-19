import re

def validate_credit_card(card_number):
    # Check if the card starts with 4, 5, or 6
    if not re.match(r"^[456]", card_number):
        return "Invalid"

    # Check for correct formatting (digits only or groups of 4 separated by hyphens)
    if not re.match(r"^(\d{4}-\d{4}-\d{4}-\d{4}|\d{16})$", card_number):
        return "Invalid"

    # Remove hyphens for further checks
    card_number_cleaned = card_number.replace("-", "")

    # Check if it contains exactly 16 digits
    if len(card_number_cleaned) != 16:
        return "Invalid"

    # Check for 4 or more consecutive repeated digits
    if re.search(r"(.)\1{3,}", card_number_cleaned):
        return "Invalid"

    return "Valid"

def main():
    n = int(input("Enter the number of credit cards to validate: "))
    for _ in range(n):
        card_number = input("Enter credit card number: ").strip()
        print(validate_credit_card(card_number))

if __name__ == "__main__":
    main()