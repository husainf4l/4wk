import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClientFormFields extends StatelessWidget {
  final FocusNode nameFocus;
  final FocusNode phoneFocus;
  final FocusNode cityFocus;
  final FocusNode countryFocus;
  final TextEditingController phoneController;
  final FormFieldSetter<String> onSavedName;
  final FormFieldSetter<String> onSavedPhone;
  final FormFieldSetter<String?> onSavedCity;
  final FormFieldSetter<String?> onSavedCountry;
  final List<String> countryList;
  final String selectedCountry;
  final ValueChanged<String> onCountryChanged;
  final String countryCode;
  final String? initialCity;
  final List<String> cityList;
  final ValueChanged<String?> onCityChanged;

  const ClientFormFields({
    super.key,
    required this.nameFocus,
    required this.phoneFocus,
    required this.cityFocus,
    required this.countryFocus,
    required this.phoneController,
    required this.onSavedName,
    required this.onSavedPhone,
    required this.onSavedCity,
    required this.onSavedCountry,
    required this.countryList,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.countryCode,
    this.initialCity,
    required this.cityList,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade700,
      fontSize: 12,
      letterSpacing: 0.8,
    );

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFFE82127), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FULL NAME', style: labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          focusNode: nameFocus,
          decoration: inputDecoration.copyWith(hintText: 'Enter client name'),
          textInputAction: TextInputAction.next,
          onFieldSubmitted:
              (_) => FocusScope.of(context).requestFocus(phoneFocus),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
          onSaved: onSavedName,
        ),
        const SizedBox(height: 24),
        Text('PHONE NUMBER', style: labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: phoneController,
          focusNode: phoneFocus,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: inputDecoration.copyWith(
            hintText: 'Enter phone number',
            prefixIcon: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
              child: Text(
                countryCode,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          textInputAction: TextInputAction.next,
          onFieldSubmitted:
              (_) => FocusScope.of(context).requestFocus(countryFocus),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a phone number';
            }
            return null;
          },
          onSaved: onSavedPhone,
        ),
        const SizedBox(height: 24),
        Text('LOCATION', style: labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          focusNode: countryFocus,
          decoration: inputDecoration.copyWith(
            contentPadding: const EdgeInsets.only(left: 20, right: 12),
          ),
          value: selectedCountry,
          items:
              countryList
                  .map(
                    (country) =>
                        DropdownMenuItem(value: country, child: Text(country)),
                  )
                  .toList(),
          onChanged: (val) {
            if (val != null) {
              onCountryChanged(val);
              FocusScope.of(context).requestFocus(cityFocus);
            }
          },
          onSaved: onSavedCountry,
        ),
        const SizedBox(height: 16),
        if (cityList.isNotEmpty)
          DropdownButtonFormField<String>(
            key: ValueKey(initialCity),
            value: initialCity,
            focusNode: cityFocus,
            decoration: inputDecoration.copyWith(
              hintText: 'City',
              contentPadding: const EdgeInsets.only(left: 20, right: 12),
            ),
            items:
                cityList
                    .map(
                      (city) =>
                          DropdownMenuItem(value: city, child: Text(city)),
                    )
                    .toList(),
            onChanged: onCityChanged,
            onSaved: onSavedCity,
          )
        else
          TextFormField(
            key: ValueKey(initialCity),
            initialValue: initialCity,
            focusNode: cityFocus,
            decoration: inputDecoration.copyWith(hintText: 'City'),
            textInputAction: TextInputAction.done,
            onSaved: onSavedCity,
          ),
      ],
    );
  }
}
