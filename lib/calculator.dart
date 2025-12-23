class TaxCalculator {
  static const double pdfo = 0.18; // 18%
  static const double military = 0.05; // 5% (виправлено з 0.5 на 0.05)

  static Map<String, double> calculateUkraineTax(double grossIncome) {
    double pdfoAmount = grossIncome * pdfo;
    double militaryAmount = grossIncome * military;
    double totalTax = pdfoAmount + militaryAmount;
    double netIncome = grossIncome - totalTax;

    return {
      'pdfo': pdfoAmount,
      'military': militaryAmount,
      'totalTax': totalTax,
      'net': netIncome,
    };
  }

  static double calculateProgress(double currentBalance) {
    const double target = 1000000.0;
    return (currentBalance / target) * 100;
  }
}
