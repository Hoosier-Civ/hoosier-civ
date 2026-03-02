import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';
import 'package:hoosierciv/data/models/official_response.dart';
import 'package:hoosierciv/features/onboarding/onboarding_cubit.dart';
import 'package:hoosierciv/features/onboarding/onboarding_state.dart';

class AddressVerificationScreen extends StatefulWidget {
  const AddressVerificationScreen({super.key});

  @override
  State<AddressVerificationScreen> createState() =>
      _AddressVerificationScreenState();
}

class _AddressVerificationScreenState extends State<AddressVerificationScreen> {
  final _addressController = TextEditingController();
  final _zipController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addressController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      final address = _addressController.text.trim();
      context.read<OnboardingCubit>().submitAddress(
        _zipController.text.trim(),
        address: address.isEmpty ? null : address,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: state is OnboardingZipVerified
                  ? _DistrictSummary(state: state)
                  : _AddressForm(
                      formKey: _formKey,
                      addressController: _addressController,
                      zipController: _zipController,
                      isLoading: state is OnboardingZipLoading,
                      errorMessage:
                          state is OnboardingError ? state.message : null,
                      onSubmit: () => _submit(context),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ── Address entry form ────────────────────────────────────────────────────────

class _AddressForm extends StatelessWidget {
  const _AddressForm({
    required this.formKey,
    required this.addressController,
    required this.zipController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;
  final TextEditingController zipController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Enter your Indiana ZIP code',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use this to find your elected officials.",
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: zipController,
            keyboardType: TextInputType.number,
            maxLength: 5,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'ZIP Code',
              hintText: 'e.g. 46074',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.length != 5) {
                return 'Please enter a 5-digit ZIP code.';
              }
              return null;
            },
            onFieldSubmitted: (_) => onSubmit(),
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: addressController,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Street Address (optional — improves accuracy)',
              hintText: 'e.g. 17941 Ambrosia Trail',
              border: OutlineInputBorder(),
            ),
            onFieldSubmitted: (_) => onSubmit(),
            enabled: !isLoading,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

// ── District summary ──────────────────────────────────────────────────────────

class _DistrictSummary extends StatelessWidget {
  const _DistrictSummary({required this.state});

  final OnboardingZipVerified state;

  static List<OfficialResponse> _filter(
    List<OfficialResponse> officials,
    List<String> chambers,
  ) =>
      officials.where((o) => chambers.contains(o.chamber)).toList();

  static String? _districtLabel(
    List<OfficialResponse> officials,
    String districtId,
  ) {
    for (final o in officials) {
      if (o.districtOcdId == districtId && o.districtLabel != null) {
        return o.districtLabel;
      }
    }
    for (final o in officials) {
      if ((o.chamber == 'house' || o.chamber == 'senate') &&
          o.districtLabel != null) {
        return o.districtLabel;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final officials = state.officials;
    final localOfficials = _filter(officials, ['local', 'local_exec']);
    final stateOfficials = _filter(officials, ['senate', 'house', 'state_exec']);
    final federalOfficials =
        _filter(officials, ['us_senate', 'us_house', 'national_exec']);

    final cityDisplay = state.city.isNotEmpty ? '${state.city}, IN' : 'Indiana';
    final districtLabel = _districtLabel(officials, state.districtId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        Text(
          cityDisplay,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (districtLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            districtLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${officials.length} officials found in public records',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                if (localOfficials.isNotEmpty)
                  _SummaryRow(
                    icon: Icons.home,
                    label: 'Local',
                    officials: localOfficials,
                  ),
                if (stateOfficials.isNotEmpty)
                  _SummaryRow(
                    icon: Icons.location_city,
                    label: 'State',
                    officials: stateOfficials,
                  ),
                if (federalOfficials.isNotEmpty)
                  _SummaryRow(
                    icon: Icons.account_balance,
                    label: 'Federal',
                    officials: federalOfficials,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Data sourced from Cicero. Some local offices may not be included.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black38,
              ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.go(AppConstants.routeHome),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Continue'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.read<OnboardingCubit>().reset(),
          child: const Text('Wrong address? Change it'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.officials,
  });

  final IconData icon;
  final String label;
  final List<OfficialResponse> officials;

  @override
  Widget build(BuildContext context) {
    final count = officials.length;
    return ExpansionTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(
        '$count official${count == 1 ? '' : 's'}',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.black54),
      ),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: officials.length,
            itemBuilder: (context, index) {
              final o = officials[index];
              final name = [o.firstName, o.lastName].join(' ');
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                title: Text(name),
                subtitle: o.officeTitle != null ? Text(o.officeTitle!) : null,
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }
}
