enum PortfolioSource {
  ibkr('IBKR', 'Interactive Brokers'),
  univer('Univer', 'Univer Bank'),
  privatfond('Privatfond', 'Privatfond');

  const PortfolioSource(this.shortName, this.fullName);

  final String shortName;
  final String fullName;

  String get displayName => shortName;
  String get description => fullName;

  String get firestoreName {
    switch (this) {
      case PortfolioSource.ibkr:
        return 'ibkr';
      case PortfolioSource.univer:
        return 'univer';
      case PortfolioSource.privatfond:
        return 'privatfond';
    }
  }
}
