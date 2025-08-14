String? validateName(String? value) {
  if (value == null || value.isEmpty) {
    return "Empty value found";
  }
  if (value.length < 3) {
    return "Invalid length";
  }

  Pattern pattern = r'^[a-zA-Z ]*$';
  RegExp regExp = RegExp(pattern.toString());

  if (!regExp.hasMatch(value.toString())) {
    return "Name should contain only characters or spaces";
  }

  return null;
}



String? validateFullName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return "Name can't be empty";
  }

  if (value.length < 3) {
    return "Invalid length";
  }

  final pattern = r'^[A-Za-z]+ [A-Za-z]+$';
  final regExp = RegExp(pattern);

  if (!regExp.hasMatch(value.trim())) {
    return "Enter full name (first and last, only letters)";
  }

  return null;
}



String? validateEmail(String? value) {
  Pattern pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  RegExp regExp = RegExp(pattern.toString());

  if (!regExp.hasMatch(value.toString())) {
    return "Invalid Email";
  } else {
    return null;
  }
}



String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return "Password can't be empty";
  }

  if (value.length < 8) {
    return "Password must be at least 8 characters long";
  }

  final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
  final hasNumber = RegExp(r'\d').hasMatch(value);
  final hasSpecial = RegExp(r'[!@#\$&*~%^()_\-+=<>?/.,;:{}[\]\\|]').hasMatch(value);

  if (!hasLetter || !hasNumber) {
    return "Password must include a letter, number, and special character";
  }

  return null;
}


String? validatePreviousPassword(String? value, String actualPreviousPassword) {
  if (value == null || value.isEmpty) {
    return "Password can't be empty";
  }

  if (value != actualPreviousPassword) {
    return "Previous password is incorrect";
  }

  return null;
}



String? validateConfirmPassword(String? value, String newPassword) {
  if (value == null || value.isEmpty) {
    return "Password can't be empty";
  }

  if (value != newPassword) {
    return "Passwords do not match";
  }

  return null;
}




String? validateMessage(String? value) {
  if (value == null || value.isEmpty) {
    return 'Message can’t be empty';
  }
  return null;
}




String? validateAge(String? value,) {
  if (value!.isEmpty) {
    return "Age is required";
  }

  Pattern pattern = r'^[0-9]*$';
  RegExp regExp = RegExp(pattern.toString());

  if (!regExp.hasMatch(value.toString())) {
    return "Age should contain numbers";
  }

  return null;
}




String? validatePhoneNumber(String? value) {
  if (value!.isEmpty) {
    return "number is required";
  }

  Pattern pattern = r"^(?:\+92|0092|0)?3\d{2}[-\s]?\d{7}$";
  RegExp regExp = RegExp(pattern.toString());

  if (!regExp.hasMatch(value.toString())) {
    return "Only numbers are required in 03XXXXXXXXX";
  }
  return null;
}




String? validateAddress(String? value) {
  if (value == null || value.isEmpty) {
    return "Address is required";
  }

  Pattern pattern = r"^[a-zA-Z0-9\s,.-]{5,100}$";
  RegExp regExp = RegExp(pattern.toString());

  if (!regExp.hasMatch(value)) {
    return "Enter a valid address without special character";
  }

  return null;
}







