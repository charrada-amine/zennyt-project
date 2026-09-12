import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';

JobOffer _offer({
  double min = 30000,
  double max = 35000,
  String currency = 'EUR',
  SalaryPeriod period = SalaryPeriod.monthly,
}) =>
    JobOffer(
      id: 'j',
      recruiterId: 'r',
      title: 'UX/UI Designer',
      companyName: 'Google',
      city: 'Paris',
      country: 'France',
      remote: false,
      salaryMin: min,
      salaryMax: max,
      salaryCurrency: currency,
      salaryPeriod: period,
      currency: '',
      contractType: ContractType.fullTime,
      workplaceType: WorkplaceType.hybrid,
      experienceLevel: ExperienceLevel.senior,
      fieldOfWork: '',
      description: '',
      responsibilities: '',
      minimumQualifications: '',
      preferredQualifications: '',
      whatWeOffer: '',
      howToApply: '',
      companyInfo: '',
      openToInternational: false,
      status: JobStatus.active,
      postedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('JobOffer.salaryDisplay', () {
    test('uses the currency symbol and period suffix', () {
      expect(_offer().salaryDisplay, '€30K - €35K /Mo');
    });

    test('yearly USD collapses a single amount', () {
      expect(
        _offer(min: 15000, max: 15000, currency: 'USD', period: SalaryPeriod.yearly).salaryDisplay,
        '\$15K /Yr',
      );
    });

    test('unknown-prefix currencies keep their ISO code', () {
      expect(_offer(currency: 'MAD').salaryDisplay, 'MAD 30K - MAD 35K /Mo');
    });

    test('is empty when no salary is set', () {
      expect(_offer(min: 0, max: 0).salaryDisplay, '');
    });
  });
}
