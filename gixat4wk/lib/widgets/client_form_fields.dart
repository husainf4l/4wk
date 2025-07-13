import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/me_countries.dart';

class ClientFormFields extends StatelessWidget {
  final FocusNode nameFocus;
  final FocusNode phoneFocus;
  final FocusNode cityFocus;
  final FocusNode countryFocus;
  final TextEditingController phoneController;
  final bool isLoading;
  final FormFieldSetter<String> onSavedName;
  final FormFieldSetter<String> onSavedPhone;
  final FormFieldSetter<String?> onSavedCity;
  final FormFieldSetter<String?> onSavedCountry;
  final VoidCallback onSubmit;
  final List<String> countryList;
  final String selectedCountry;
  final ValueChanged<String> onCountryChanged;
  final String countryCode;
  final String? initialCity;

  const ClientFormFields({
    super.key,
    required this.nameFocus,
    required this.phoneFocus,
    required this.cityFocus,
    required this.countryFocus,
    required this.phoneController,
    required this.isLoading,
    required this.onSavedName,
    required this.onSavedPhone,
    required this.onSavedCity,
    required this.onSavedCountry,
    required this.onSubmit,
    required this.countryList,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.countryCode,
    this.initialCity,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = Colors.grey.shade100;
    final borderRadius = BorderRadius.circular(14);
    final focusedBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        width: 1.5,
      ),
    );
    final enabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    );
    final inputStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.grey.shade900,
    );

    return ListView(
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            prefixIcon: const Icon(Icons.person),
            filled: true,
            fillColor: fillColor,
            border: enabledBorder,
            enabledBorder: enabledBorder,
            focusedBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 14,
            ),
          ),
          style: inputStyle,
          focusNode: nameFocus,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(phoneFocus);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
          onSaved: onSavedName,
        ),
        const SizedBox(height: 16),
        // Modern connected phone field
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: borderRadius,
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              FocusScope.of(context).hasFocus
                  ? BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                  : const BoxShadow(color: Colors.transparent),
            ],
          ),
          child: Row(
            children: [
              if (countryCode.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    countryCode,
                    style: inputStyle.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              Expanded(
                child: TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                    border: InputBorder.none,
                    hintText: 'Enter phone number',
                    // Add left margin to hint/content
                    contentPadding: const EdgeInsets.only(
                      left: 10,
                      right: 0,
                      top: 18,
                      bottom: 18,
                    ),
                  ),
                  style: inputStyle,
                  focusNode: phoneFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    if (value.length < 6) {
                      return 'Phone number is too short';
                    }
                    return null;
                  },
                  onSaved: onSavedPhone,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // City dropdown mapped to selected country
        DropdownButtonFormField<String>(
          value:
              (meCountryCities[selectedCountry]?.contains(initialCity) ?? false)
                  ? initialCity
                  : null,
          items:
              (meCountryCities[selectedCountry] ?? [])
                  .map(
                    (city) => DropdownMenuItem<String>(
                      value: city,
                      child: Text(city, style: inputStyle),
                    ),
                  )
                  .toList(),
          onChanged: (val) {}, // No-op, only save on form submit
          decoration: InputDecoration(
            labelText: 'City',
            labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            prefixIcon: const Icon(Icons.location_city),
            filled: true,
            fillColor: fillColor,
            border: enabledBorder,
            enabledBorder: enabledBorder,
            focusedBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 14,
            ),
          ),
          focusNode: cityFocus,
          onSaved: onSavedCity,
          style: inputStyle,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedCountry,
          items:
              countryList
                  .map(
                    (country) => DropdownMenuItem<String>(
                      value: country,
                      child: Text(country, style: inputStyle),
                    ),
                  )
                  .toList(),
          onChanged: (val) {
            if (val != null) onCountryChanged(val);
          },
          decoration: InputDecoration(
            labelText: 'Country',
            labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            prefixIcon: const Icon(Icons.flag),
            filled: true,
            fillColor: fillColor,
            border: enabledBorder,
            enabledBorder: enabledBorder,
            focusedBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 14,
            ),
          ),
          focusNode: countryFocus,
          onSaved: onSavedCountry,
          style: inputStyle,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            elevation: 0,
          ),
          child:
              isLoading
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                  : const Text('SAVE CLIENT'),
        ),
      ],
    );
  }
}
